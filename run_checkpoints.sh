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
python find_doc_location.py

# Loop through checkpoints
IFS=','
for c in $INPUT_CHECKPOINTS;do
    great_expectations checkpoint run $c
done

# Build the ephemeral docs site
build_gh_action_site.py

# TODO put the built site somewhere interesting
