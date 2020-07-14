#!/bin/bash
# This script helps to test the Action locally

docker build -t test-ge-action .

INPUT_CHECKPOINTS="passing_checkpoint,failing_checkpoint"

docker run -e INPUT_CHECKPOINTS=$INPUT_CHECKPOINTS \
-v $PWD:/app test-ge-action


