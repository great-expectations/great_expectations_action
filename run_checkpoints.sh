#!/bin/bash

set -e

# Validate That Required Inputs Were Supplied
function check_env() {
    if [ -z $(eval echo "\$$1") ]; then
        echo "Variable $1 not found.  Exiting..."
        exit 1
    fi
}

check_env "INPUT_CHECKPOINTS"

# Emit docs locations to stdout
python /find_doc_location.py

# Loop through checkpoints
STATUS=0
IFS=','
FAILING_CHECKPOINTS=""
PASSING_CHECKPOINTS=""
for c in $INPUT_CHECKPOINTS;do
    echo ""
    echo "Validating Checkpoint: ${c}"
    if ! great_expectations checkpoint run $c; 
        then
            STATUS=1
            if [[ -z "$FAILING_CHECKPOINTS" ]];
                then
                    export FAILING_CHECKPOINTS="${c}"
                else
                    export FAILING_CHECKPOINTS="${FAILING_CHECKPOINTS},${c}"
            fi
        else
            if [[ -z "$PASSING_CHECKPOINTS" ]];
                then
                    export PASSING_CHECKPOINTS="${c}"
                else
                    export PASSING_CHECKPOINTS="${PASSING_CHECKPOINTS},${c}"
            fi
    fi
done

# Build the ephemeral docs site and read location of site into DOCS_LOC
python /build_gh_action_site.py
DOCS_LOC=`cat _temp_greatexpectations_action_docs_location_dir.txt`

# Emit Failing and Passing Checkpoints as output variables
export FAILING_CHECKPOINTS="${FAILING_CHECKPOINTS}"
echo "::set-output name=FAILING_CHECKPOINTS::${FAILING_CHECKPOINTS}"
echo "::set-output name=PASSING_CHECKPOINTS::${PASSING_CHECKPOINTS}"

# Optionally launch docs on Netlify
if [[ ! -z "$INPUT_NETLIFY_AUTH_TOKEN" ]] && [[ ! -z "$INPUT_NETLIFY_SITE_ID" ]]; 
    then
        # Set Inputs to proper environment variable names for Netlify CLI
        export NETLIFY_AUTH_TOKEN=$INPUT_NETLIFY_AUTH_TOKEN
        export NETLIFY_SITE_ID=$INPUT_NETLIFY_SITE_ID

        # Verify Docs Directory
        [[  -z "$DOCS_LOC" ]] && { echo "Variable DOCS_LOC is empty" ; exit 1; }
        [[ ! -d "$DOCS_LOC" ]] && { echo "Directory specified in variable DOCS_LOC: ${DOCS_LOC} does not exist."; exit 1; }

        # Deploy docs site to Netlify, and write out to logs
        netlify deploy --dir $DOCS_LOC | tee _netlify_logs.txt

        # Parse URL from logs and send to next step
        export DOCS_URL=`cat _netlify_logs.txt | awk '/Draft URL: /{print $4}'`

        ## Verify URL exists and emit it as an output variable
        [[  -z "$DOCS_URL" ]] && { echo "Variable DOCS_URL is empty" ; exit 1; }
        echo "::set-output name=NETLIFY_DOCS_URL::${DOCS_URL}"
    else
        echo "Netlify Deploy Skipped."
fi

if [[ ! -z "$INPUT_AUTO_NETLIFY_DOCS" ]] || [[ ! -z "$INPUT_MANUAL_NETLIFY_DOCS_TRIGGER_PHRASE" ]]; then
    # Throw an error if user specifies the AUTO_NETLIFY_DOCS flag, but doesnt supply a GITHUB_TOKEN, NETLIFY_AUTH_TOKEN, or NETLIFY_SITE_ID
    elif [[ -z "$INPUT_GITHUB_TOKEN" ]]; then
        echo "::error::You must supply the input GITHUB_TOKEN to trigger a pull request comment."
        exit 1;

    elif [[ -z "$INPUT_NETLIFY_AUTH_TOKEN" ]]; then
        echo "::error::You must supply the input INPUT_NETLIFY_AUTH_TOKEN to trigger a pull request comment with a Data Docs preview on Netlify."
        exit 1;

    elif [[ -z "$INPUT_NETLIFY_SITE_ID" ]]; then
        echo "::error::You must supply the input INPUT_NETLIFY_SITE_ID to trigger a pull request comment with a Data Docs preview on Netlify."
        exit 1;
fi


if [[ ! -z "$INPUT_AUTO_NETLIFY_DOCS" ]] && [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
    # GITHUB_HEAD_REF is only set by Actions when a pull_request event is created from a fork. 
    # Emit a warning to the logs that no comment can be made in this situation, but do not fail the checkrun.
    # TODO: handle upcoming pull_request_target event once it is realeased on 7/31
    if [[ ! -z "$GITHUB_HEAD_REF" ]]; then
            echo "::warning::pull request comments are not supported on a push made from a forked repository for security reasons."

        # Comment on PR if any checkpoint fails    
        elif [[ $STATUS == 1 ]]; then
            node comment_on_pr.js
    fi

elif [[ ! -z "$INPUT_MANUAL_NETLIFY_DOCS_TRIGGER_PHRASE" ]] && [[ "$GITHUB_EVENT_NAME" == "issue_comment" ]]; then
    node comment_on_pr.js
fi

echo "::set-output name=CHECKPOINT_FAILURE_FLAG::${STATUS}"

# exit with appropriate status
if [[ ! -z "$INPUT_DEBUG" ]]; then
    exit $STATUS
fi
