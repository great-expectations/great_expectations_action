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
FAILED_CHECKPOINTS=""
PASSING_CHECKPOINTS=""
for c in $INPUT_CHECKPOINTS;do
    echo ""
    echo "Validating Checkpoint: ${c}"
    if ! great_expectations checkpoint run $c; 
        then
            STATUS=1
            if [[ -z "$FAILED_CHECKPOINTS" ]];
                then
                    FAILED_CHECKPOINTS="${c}"
                else
                    FAILED_CHECKPOINTS="${FAILED_CHECKPOINTS},${c}"
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
echo "::set-output name=FAILED_CHECKPOINTS::${FAILED_CHECKPOINTS}"
echo "::set-output name=PASSING_CHECKPOINTS::${PASSING_CHECKPOINTS}"

# exit with appropriate status
exit $STATUS
