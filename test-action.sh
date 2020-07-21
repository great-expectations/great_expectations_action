#!/bin/bash
# This script helps to test the Action locally

docker build -t test-ge-action .

INPUT_CHECKPOINTS="passing_checkpoint,failing_checkpoint,passing_checkpoint"

docker run -e INPUT_CHECKPOINTS=$INPUT_CHECKPOINTS \
-e NETLIFY_AUTH_TOKEN=$NETLIFY_AUTH_TOKEN \
-e NETLIFY_SITE_ID=$NETLIFY_SITE_ID \
-v $PWD:/app test-ge-action
