#!/bin/bash

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
                    FAILING_CHECKPOINTS="${c}"
                else
                    FAILING_CHECKPOINTS="${FAILING_CHECKPOINTS},${c}"
            fi
        else
            if [[ -z "$PASSING_CHECKPOINTS" ]];
                then
                    PASSING_CHECKPOINTS="${c}"
                else
                    PASSING_CHECKPOINTS="${PASSING_CHECKPOINTS},${c}"
            fi
    fi
done

# Build the ephemeral docs site and read location of site into DOCS_LOC
python /build_gh_action_site.py
DOCS_LOC=`cat _temp_greatexpectations_action_docs_location_dir.txt`

# Emit Failing and Passing Checkpoints as output variables
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
        DOCS_URL=`cat _netlify_logs.txt | awk '/Draft URL: /{print $4}'`

        ## Verify URL exists and emit it as an output variable
        [[  -z "$DOCS_URL" ]] && { echo "Variable DOCS_URL is empty" ; exit 1; }
        echo "::set-output name=NETLIFY_DOCS_URL::${DOCS_URL}"
    else
        echo "Netlify Deploy Skipped."
fi

if [[ ! -z "$INPUT_PR_COMMENT_ON_ERROR" ]] && [[ "$GITHUB_EVENT_NAME" == "push" ]]; then
    if [[ ! -z "$GITHUB_HEAD_REF" ]]; then
            echo "::warning::pull request comments are not supported on a push made from a forked repository for security reasons."
        elif [[ -z "$INPUT_GITHUB_TOKEN" ]]; then
            echo "::warning::You must supply the input GITHUB_TOKEN to trigger a pull request comment."
        else
            echo "TODO: comment on the issue!"
    fi
fi

# exit with appropriate status
exit $STATUS
