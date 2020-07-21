#!/bin/bash
# This script helps to test the Action locally

docker build -t test-ge-action .

INPUT_CHECKPOINTS="passing_checkpoint,failing_checkpoint,passing_checkpoint"

docker run -e INPUT_CHECKPOINTS=$INPUT_CHECKPOINTS \
-e INPUT_NETLIFY_AUTH_TOKEN=$NETLIFY_AUTH_TOKEN \
-e INPUT_NETLIFY_SITE_ID=$NETLIFY_SITE_ID \
-e INPUT_PR_COMMENT_ON_ERROR="true" \
-e GITHUB_EVENT_NAME="push" \
-e INPUT_GITHUB_TOKEN="foo" \
-v $PWD:/app test-ge-action
