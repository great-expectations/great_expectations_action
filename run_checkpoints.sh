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

# Build the ephemeral docs site
python /build_gh_action_site.py
DOCS_LOC=`cat _temp_greatexpectations_action_docs_location_dir.txt`
echo "::set-output name=FAILING_CHECKPOINTS::${FAILING_CHECKPOINTS}"
echo "::set-output name=PASSING_CHECKPOINTS::${PASSING_CHECKPOINTS}"

# Optionally launch docs on Netlify
if [[ ! -z "$NETLIFY_AUTH_TOKEN" ]] && [[ ! -z "$NETLIFY_SITE_ID" ]]; 
then
    [[  -z "$DOCS_LOC" ]] && { echo "Variable DOCS_LOC is empty" ; exit 1; }
    [[  -d "$DOCS_LOC" ]] && { echo "Directory specified in variable DOCS_LOC: ${DOCS_LOC} does not exist" ; exit 1; }
    netlify deploy --dir $DOCS_LOC | tee _netlify_logs.txt
    # Parse URL from logs and send to next step
    DOCS_URL=`cat _netlify_logs.txt | awk '/Draft URL: /{print $4}'`
    ## find out if it is empty or not
    [[  -z "$DOCS_URL" ]] && { echo "Variable DOCS_URL is empty" ; exit 1; }
    echo "::set-output name=NETLIFY_DOCS_URL::${DOCS_URL}"
else
    echo "Netlify Deploy Skipped."
fi

# exit with appropriate status
exit $STATUS
