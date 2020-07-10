 ![](https://github.com/superconductive/great_expectations_action/workflows/GE-Action-Build/badge.svg)
 
 <h1><img src="https://github.com/superconductive/great_expectations_action/blob/master/ge-logo.png" width="100" height="100">Great Expectations GitHub Action</h1>

# Background

This Action allows you to validate your data with [Great Expectations](https://greatexpectations.io/).  From [the docs](https://docs.greatexpectations.io/en/latest/):

> Great Expectations is a leading tool for validating, documenting, and profiling your data to maintain quality and improve communication between teams.

TODO - Features

# Usage

## Example

```yaml
TODO
```
## Inputs

- `CHECKPOINTS`:
    A comma separated list of checkpoint names to execute.  Example -  "checkpoint1,checkpoint2"


# Development

## Installation

1. `pip install -r requriements.txt`
2. run `great_expectations init` to set up missing directories

## Use

Run these commands from the repo root.

To see a checkpoint pass run `great_expectations checkpoint run passing_checkpoint`
To see a checkpoint fail run `great_expectations checkpoint run failing_checkpoint`
