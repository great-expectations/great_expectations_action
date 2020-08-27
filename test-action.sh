#!/bin/bash
# This script helps to test the Action locally

docker build -t test-ge-action .

INPUT_CHECKPOINTS="npi.pass,npi.fail"

docker run -e INPUT_CHECKPOINTS=$INPUT_CHECKPOINTS \
-e INPUT_NETLIFY_AUTH_TOKEN=$NETLIFY_AUTH_TOKEN \
-e INPUT_NETLIFY_SITE_ID=$NETLIFY_SITE_ID \
-e GITHUB_REPOSITORY="$GITHUB_REPOSITORY" \
-v $PWD/test:/app test-ge-action

# cleanup
rm -rf great_expectations/gh_action_site_*
rm -rf great_expectations/uncommitted/
