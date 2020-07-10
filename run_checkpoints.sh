#!/bin/bash

IFS=','
checkpoints='passing_checkpoint,failing_checkpoint'

for c in $checkpoints;do
    great_expectations checkpoint run $c
done
