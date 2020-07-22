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

echo "::set-output name=CHECKPOINT_FAILURE_FLAG::${STATUS}"

# # exit with appropriate status if DEBUG flag is not set.
if [[ -z "$INPUT_DEBUG" ]]; then
    exit $STATUS;
fi
