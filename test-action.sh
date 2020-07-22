#!/bin/bash
# This script helps to test the Action locally

docker build -t test-ge-action .

INPUT_CHECKPOINTS="passing_checkpoint,failing_checkpoint,passing_checkpoint"

docker run -e INPUT_CHECKPOINTS=$INPUT_CHECKPOINTS \
-e INPUT_NETLIFY_AUTH_TOKEN=$NETLIFY_AUTH_TOKEN \
-e INPUT_NETLIFY_SITE_ID=$NETLIFY_SITE_ID \
-e GITHUB_REPOSITORY="$GITHUB_REPOSITORY" \
-e INPUT_GITHUB_TOKEN="$GITHUB_TOKEN" \
-e INPUT_AUTO_NETLIFY_DOCS="true" \
-e GITHUB_EVENT_NAME="pull_request" \
-e GITHUB_EVENT_PATH="/app/test-event.json" \
-e GITHUB_SHA="ffac537e6cbbf934b08745a378932722df287a53" \
-v $PWD:/app test-ge-action

# cleanup
rm -rf great_expectations/gh_action_site_*
rm -rf great_expectations/uncommitted/
