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
for c in $INPUT_CHECKPOINTS;do
    echo ""
    echo "Validating Checkpoint: ${c}"
    if ! great_expectations checkpoint run $c; then
        STATUS=1
    fi
done

# Build the ephemeral docs site
python /build_gh_action_site.py

# TODO put the built site somewhere interesting

# exit with appropriate status
exit $STATUS
