![](https://github.com/superconductive/great_expectations_action/workflows/Action%20Build/badge.svg) ![](https://github.com/superconductive/great_expectations_action/workflows/PR%20Comment/badge.svg) ![](https://github.com/superconductive/great_expectations_action/workflows/PR%20Push/badge.svg) [![MLOps](https://img.shields.io/badge/MLOps-black.svg?logo=github&?logoColor=blue)](https://mlops-github.com)

 <h1><img src="https://github.com/superconductive/great_expectations_action/blob/main/ge-logo.png" width="100" height="100">Great Expectations GitHub Action</h1>

This Action allows you to validate and profile your data with [Great Expectations](https://greatexpectations.io/).  From [the docs](https://docs.greatexpectations.io/en/latest/):


> Great Expectations is a leading tool for validating, documenting, and profiling your data to maintain quality and improve communication between teams.

This Action provides the following features:

- Run [ Expectations Suites](https://docs.greatexpectations.io/en/latest/reference/core_concepts.html#expectations), to validate your data as part of your continuous integration workflow.
- Generate [Data Docs](https://docs.greatexpectations.io/en/latest/reference/core_concepts/data_docs.html#data-docs) and [Profiling](https://docs.greatexpectations.io/en/latest/reference/core_concepts/profiling.html) and serve them on a static site generator like GitHub Pages or platform like [Netlify](https://www.netlify.com/).
- More information on how you can use this action can be found in the [Use Cases](#use-cases).

# Table of Contents

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Demo](#demo)
- [Use Cases](#use-cases)
- [Usage](#usage)
	- [Example 1 (Simple): Run Great Expectations And Provide Links To Docs](#example-1-simple-run-great-expectations-and-provide-links-to-docs)
	- [Example 2 (Advanced): Trigger Data Docs Generation With A PR Comment](#example-2-advanced-trigger-data-docs-generation-with-a-pr-comment)
- [API Reference](#api-reference)
	- [Inputs](#inputs)
		- [Mandatory Inputs](#mandatory-inputs)
		- [Optional Inputs](#optional-inputs)
	- [Outputs](#outputs)
- [Development](#development)
	- [Installation](#installation)
	- [Usage](#usage)
	- [Current Limitations](#current-limitations)

<!-- /TOC -->

# Use Cases

1. **CI for your data.**
    - GitHub is a natural platform to discuss fixes as issues arise. This action can speed up conversations by presenting data docs reports that make it easy to see how your data has changed.
2. **MLOps - Retraining ML models.**
    - Great Expectations can be used to detect when your live prediction data has drifted from your training data. Not only does this protect you from misbehaving models, it also can be used to determine when models need to be retrained.
    - In addition to checking model input, Great Expectations can be used to check model output.
3. **Integration testing with static data fixtures.**
    - Many data pipeline and ML projects use static data fixtures for unit or integration tests. These test suites can be expressed as Great Expectations suites. Then each time you submit a PR not only will you receive a pass/fail CI check you'll receive a visual data report on how your tests performed.
4. **Run on code change.**
    - Use this action as CI/CD for data and ML pipelines that runs when PRs are submitted.
5. **A lightweight DAG runner**
    - This action is not limited to running in response to code change or other activity on GitHub. You can also run this action [manually](https://github.blog/changelog/2020-07-06-github-actions-manual-triggers-with-workflow_dispatch/) or [on a schedule](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#onschedule). As long as your data sources are configured and accessible, you can get the benefits of data quality testing without integrating Great Expectations directly into your pipelines.

# Demo

TODO: insert GIF here

# Usage

## Example 1 (Simple): Run Great Expectations And Provide Links To Docs

This example triggers Great Expectations to run everytime a pull request is opened, reopened, or a push is made to a pull request.  Furthermore, if a checkpoint fails a comment with a link to the Data Docs hosted on Netlify is provided.

> Note: This example will not work on pull requests from forks. This is to protect repositories from malicious actors. To trigger a GitHub Action with sufficient permissions to comment on a pull request from a fork, you must trigger the action via another event, such as a comment or a label. This is demonstrated in Example 2 below.

```yaml
#Automatically Runs Great Expectation Checkpoints on every push to a PR, and provides links to hosted Data Docs if there an error.
name: PR Push
on: pull_request

jobs:
  test-hosted-action:
    runs-on: ubuntu-latest
    steps:

      # Clone the contents of the repository
    - name: Copy Repository Contents
      uses: actions/checkout@main

      # Run Great Expectations and deploy Data Docs to Netlify
    - name: Run Great Expectation Checkpoints
      uses: superconductive/great_expectations_action@main
      continue-on-error: true
      with:
        CHECKPOINTS: "passing_checkpoint,failing_checkpoint"
        NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
        NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
    
    # If a checkpoint failed, comment on the PR with a link to the Data Docs hosted on Netlify.
    - name: Comment on PR Upon Checkpoint Failure
      if: steps.ge.outputs.checkpoint_failure_flag == '1'
      uses: actions/github-script@v2
      with:
        github-token: ${{secrets.GITHUB_TOKEN}}
        script: |
            github.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `Failed Great Expectations checkpoint(s) \`${FAILED_CHECKPOIINTS}\` detected for: ${process.env.GITHUB_SHA}.  Corresponding Data Docs have been generated and can be viewed [here](${process.env.URL}).`
            })
      env:
        URL: ${{ steps.ge.outputs.docs_url }}
        FAILED_CHECKPOIINTS: ${{ steps.ge.outputs.failing_checkpoints }}
```

## Example 2 (Advanced): Trigger Data Docs Generation With A PR Comment

The below example checks pull request comments for the presence of a special command: `/data-docs`.  If this command is present, the following steps occur:

1. The HEAD SHA for the pull request commented on is retrieved.
2. The contents for the repository are fetched at the HEAD SHA of the branch of the pull request.
3. Great Expectations checkpoints are run, and Data Docs are deployed to Netlify.
4. The Netlify URL is provided as a comment on the pull request.

```yaml
#Allows repo owners to view data docs hosted on Netlify for a PR with the command "/data-docs" as a comment in a PR.
name: PR Comment
on: [issue_comment]

jobs:
  demo-pr:
    # Check that a comment with word '/data-docs' is made on pull request (not an issue).
    if: | 
      (github.event.issue.pull_request != null) &&
      contains(github.event.comment.body, '/data-docs')
    runs-on: ubuntu-latest
    steps:

      # Get the HEAD SHA of the pull request that has been commented on.
    - name: Fetch context about the PR that has been commented on
      id: chatops
      uses: actions/github-script@v1
      with:
        github-token: ${{secrets.GITHUB_TOKEN}}
        script: |
          // Get the branch name
          github.pulls.get({
            owner: context.repo.owner,
            repo: context.repo.repo,
            pull_number: context.payload.issue.number
          }).then( (pr) => {
            // Get latest SHA of current branch
            var SHA = pr.data.head.sha
            console.log(`::set-output name=SHA::${SHA}`)
          })

      # Clone the contents of the repository at the SHA fetched in the previous step
    - name: Copy The PR's Branch Repository Contents
      uses: actions/checkout@main
      with:
        ref: ${{ steps.chatops.outputs.SHA }}

      # Run Great Expectation checkpoints and deploy Data Docs to Netlify
    - name: run great expectation checkpoints
      id: ge
      continue-on-error: true
      uses: superconductive/great_expectations_action@main
      with:
        CHECKPOINTS: "passing_checkpoint,failing_checkpoint"
        NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
        NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}

      # Comment on PR with link to deployed Data Docs on Netlify
    - name: Comment on PR
      uses: actions/github-script@v2
      with:
        github-token: ${{secrets.GITHUB_TOKEN}}
        script: |
            github.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `Great Expectations Data Docs have been generated for SHA: ${process.env.SHA} and can be viewed [here](${process.env.URL}).`
            })
      env:
        URL: ${{ steps.ge.outputs.docs_url }}
        SHA: ${{ steps.chatops.outputs.SHA }}  
```


# API Reference

## Inputs

### Mandatory Inputs

- **`CHECKPOINTS`**:
    A comma separated list of checkpoint names to execute.  Example -  "checkpoint1,checkpoint2"

### Optional Inputs

- **`NETLIFY_AUTH_TOKEN`**:
    A personal access token for [Netlify](https://www.netlify.com/).

- **`NETLIFY_SITE_ID`**:
    A [Netlify](https://www.netlify.com/) site id.

- `DEBUG`
    Setting this input to any value will allow the Action to exit with a status code of 0 even if a checkpoint fails.  This is used by maintainers of this Action for testing and debugging.

## Outputs

- **`ACTION_DOCS_LOCATION`**:
    The absolute path where generated data docs generated by the Action run are located.  This is useful if you want to deploy the data docs to an external service.

- **`FAILING_CHECKPOINTS`**:
    A comma delimited list of failed checkpoints.

- **`PASSING_CHECKPOINTS`**:
    A comma delimited list of passing checkpoints.

- **`NETLIFY_DOCS_URL`**:
    The url to the generated data docs on Netlify.  This output is only emitted only if the input parameters `NETLIFY_AUTH_TOKEN` and `NETLIFY_SITE_ID` are provided.

- **`CHECKPOINT_FAILURE_FLAG`**:
    This will return 0 if there are no checkpoint failures and 1 if there are one or more checkpoint failures.

# Development

This section is for those who wish to develop this GitHub Action.  Users of this Action can ignore this section.

## Installation

1. `pip install -r requriements.txt`
2. run `great_expectations init` to set up missing directories

## Usage

Run these commands from the repo root.

To see a checkpoint pass run `great_expectations checkpoint run passing_checkpoint`
To see a checkpoint fail run `great_expectations checkpoint run failing_checkpoint`

## Current Limitations

- If a **cloud-based** `ValidationStore` is in use we may need to disable it so that the built docs focus only on what is being validated in the Action without other side effects.
