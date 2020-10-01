![](https://github.com/great-expectations/great_expectations_action/workflows/Action%20Build/badge.svg) [![MLOps](https://img.shields.io/badge/MLOps-black.svg?logo=github&?logoColor=blue)](https://mlops-github.com)

 <h1><img src="https://github.com/great-expectations/great_expectations_action/blob/main/ge-logo.png" width="100" height="100">Great Expectations GitHub Action</h1>

This Action allows you to validate and profile your data with [Great Expectations](https://greatexpectations.io/).  From [the Great Expectations docs](https://docs.greatexpectations.io/en/latest/):

> Great Expectations is a leading tool for validating, documenting, and profiling your data to maintain quality and improve communication between teams.

This Action provides the following features:

- Run [Expectation Suites](https://docs.greatexpectations.io/en/latest/reference/core_concepts.html#expectations) to validate your data pipeline code as part of your continuous integration workflow.
- Generate [Data Docs](https://docs.greatexpectations.io/en/latest/reference/core_concepts/data_docs.html#data-docs) and serve them on a static site generator or platform like [Netlify](https://www.netlify.com/).
- More information on how you can use this action can be found in the [Use cases](#use-cases).

# Table of contents

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Demo](#demo)
- [Use cases](#use-cases)
- [Usage](#usage)
	- [Example 1 (Simple): Run Great Expectations in a PR and provide links to Data Docs](#example-1-simple-run-great-expectations-and-provide-links-to-docs)
	- [Example 2 (Advanced): Trigger Data Docs generation with a PR comment](#example-2-advanced-trigger-data-docs-generation-with-a-pr-comment)
- [API reference](#api-reference)
	- [Inputs](#inputs)
		- [Mandatory inputs](#mandatory-inputs)
		- [Optional inputs](#optional-inputs)
	- [Outputs](#outputs)
- [Development](#development)
	- [Installation](#installation)
	- [Usage](#usage)
	- [Current limitations](#current-limitations)

<!-- /TOC -->

# Use cases

1. **Integration testing of your data pipelines as part of your CI workflows**
    - This Action allows you to trigger a Great Expectation *Checkpoint*, which runs a suite of data tests against your data in GitHub and links directly to the validation report (Data Docs).
    - This means you can test whether any changes to your data pipelines had unintended consequences.
    - The Great Expectations Action does **not** run your data pipelines. This will need to be configured as a separate GitHub workflow.
    - While you can run any data pipeline in any environment to be tested, we strongly recommend using static **input data fixtures** in a test environment to ensure that you can cleanly separate testing *code changes* from *data changes*.
    - One advantage of using only fixed input data and Expectations instead of fixed output data is that you can apply the same tests to your production data!
2. **Monitoring data drift**
    - You can also configure this Action to run peridocially to test your *data* rather than the data pipeline *code*.
    - This Action is *not limited* to running in response to code change or other activity on GitHub. You can also run this Action [manually](https://github.blog/changelog/2020-07-06-github-actions-manual-triggers-with-workflow_dispatch/) or [on a schedule](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#onschedule). As long as your data sources are configured and accessible, you can get the benefits of data quality testing without integrating Great Expectations directly into your pipelines.
    - As an example, in an ML Ops context, Great Expectations can be used to detect when your live prediction data has drifted from your training data. Not only does this protect you from misbehaving models, it also can be used to determine when models need to be retrained.
    - In addition to checking model input, Great Expectations can be used to check model output.

# Demo

![Demo](ge-demo.gif)

# Usage

## Pre-requisites

1. You have an existing setup of Great Expectations in the repo (i.e. a `great_expectations/` subdirectory), with which you have created at least one Expectation Suite and Checkpoint for the data you want to secure. See the Great Expectations [Getting started tutorial](https://docs.greatexpectations.io/en/latest/guides/tutorials/getting_started.html) for instructions on the setup.
2. You have configured GitHub secrets for the relevant environment variables needed in the example below, e.g. Datasource credentials. The environment variables need to match those used in your Great Expectations setup, e.g. if your `great_expectations.yml` references an environment variable `DB_HOST`, this is what you need to configure in GitHub secrets.

## Example 1 (Simple): Run Great Expectations in a PR and provide links to Data Docs

In order to configure the GitHub action for your repository, add the following code snippet to your GitHub workflows file. The file should be located under `my_repo_name/.github/my_workflow.yml`.

This example triggers Great Expectations to run every time a GitHub pull request is opened, reopened, or a push is made to a pull request.  Furthermore, if a Checkpoint fails, a comment with a link to the Data Docs hosted on Netlify is provided.

> Note: This example will not work on pull requests from forks. This is to protect repositories from malicious actors. To trigger a GitHub Action with sufficient permissions to comment on a pull request from a fork, you must trigger the Action via another event, such as a comment or a label. This is demonstrated in Example 2 below.


```yaml
# Automatically Runs Great Expectation Checkpoints on every push to a PR, and provides links to hosted Data Docs if there an error.
name: PR Push
on: pull_request
env: # Credentials to your development database (this is illustrative, can be another data source)
  DB_HOST: ${{ secrets.DB_HOST }}
  DB_PASS: ${{ secrets.DB_PASS }}
  DB_USER: ${{ secrets.DB_USER }} 

jobs:
  great_expectations_validation:
    runs-on: ubuntu-latest
    steps:

      # Clone the contents of the repository
    - name: Copy Repository contents
      uses: actions/checkout@main
    
    # Execute your data pipeline on development infrastructure.  This is a simplified example where
    #   we run a local SQL file against a remote Postgres development database as the "pipeline". We 
    #   then test the materialized data from the pipeline with this Action. 
    #   It is up to you to configure how you kick off your pipeline in a workflow!
    - name: Run SQL "pipeline"
      run: |
        PGPASSWORD=${DB_PASS} psql -h $DB_HOST -d demo -U $DB_USER -f location_frequency.sql

      # Run Great Expectations and deploy Data Docs to Netlify
      # In this example, we have configured a Checkpoint called "locations.rds.chk".
    - name: Run Great Expectation Checkpoints
      id: ge
      # Use @v0.x instead of @main to pin to a specific version, e.g. @v0.2
      uses: great-expectations/great_expectations_action@main
      with:
        CHECKPOINTS: "locations.rds.chk" # This can be a comma-separated list of Checkpoints
        NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
        NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}

      # Comment on PR with link to deployed Data Docs if there is a failed Checkpoint, otherwise don't comment.
    - name: Comment on PR 
      if: ${{ always() }}
      uses: actions/github-script@v2
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        script: |
            if (process.env.FAILURE_FLAG == 1 ) {
              msg = `Failed Great Expectations Checkpoint(s) \`${process.env.FAILED_CHECKPOINTS}\` detected for: ${process.env.SHA}.  Corresponding Data Docs have been generated and can be viewed [here](${process.env.URL}).`;
              console.log(`Message to be emitted: ${msg}`);
              github.issues.createComment({
                 issue_number: context.issue.number,
                 owner: context.repo.owner,
                 repo: context.repo.repo,
                 body: msg 
               });
            }
      env:
        URL: "${{ steps.ge.outputs.netlify_docs_url }}"
        FAILED_CHECKPOINTS: ${{ steps.ge.outputs.failing_checkpoints }}
        SHA: ${{ github.sha }}
        FAILURE_FLAG: ${{ steps.ge.outputs.checkpoint_failure_flag }}
```

## Example 2 (Advanced): Trigger Data Docs Generation With A PR Comment

In order to configure the GitHub action for your repository, add the following code snippet to your GitHub workflows file. The file should be located under `my_repo_name/.github/my_workflow.yml`.

The below example checks pull request comments for the presence of a special command: `/data-docs`.  If this command is present, the following steps occur:

1. The HEAD SHA for the pull request commented on is retrieved.
2. The contents for the repository are fetched at the HEAD SHA of the branch of the pull request.
3. Great Expectations checkpoints are run, and Data Docs are deployed to Netlify.
4. The Netlify URL is provided as a comment on the pull request.

```yaml
# Allows repo owners to view Data Docs hosted on Netlify for a PR with the command "/data-docs" as a comment in a PR.
name: PR Comment
on: [issue_comment]

jobs:
  demo-pr:
    # Check whether a comment with the command '/data-docs' is made on a pull request (not an issue).
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
        github-token: ${{ secrets.GITHUB_TOKEN }}
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
    - name: Copy the PR's branch repository contents
      uses: actions/checkout@main
      with:
        ref: ${{ steps.chatops.outputs.SHA }}

    - name: Run data pipeline on dev server
      run: # <Put your code here> run your data pipeline in development so you can test the results with Great Expectations

    # Run Great Expectation Checkpoints and deploy Data Docs to Netlify
    - name: Run Great Expectation Checkpoints
      id: ge
      # Use @v0.x instead of @main to pin to a specific version, e.g. @v0.2
      uses: great-expectations/great_expectations_action@main 
      with:
        CHECKPOINTS: ${{ matrix.checkpoints }}
        NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
        NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}

    # Comment on PR with link to deployed Data Docs on Netlify. In this example, we comment
    #  on the PR with a message for both failed and successful checks.
    - name: Comment on PR
      if: ${{ always() }}
      uses: actions/github-script@v2
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        script: |
            if (process.env.FAILURE_FLAG == 1 ) {
              msg = `Failed Great Expectations Checkpoint(s) \`${process.env.FAILED_CHECKPOINTS}\` detected for: ${process.env.SHA}.  Corresponding Data Docs have been generated and can be viewed [here](${process.env.URL}).`;
            } else {
              msg = `All Checkpoints for: ${process.env.SHA} have passed.  Corresponding Data Docs have been generated and can be viewed [here](${process.env.URL}).`;
            }
            console.log(`Message to be emitted: ${msg}`);
            github.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: msg
            })
      env:
        URL: "${{ steps.ge.outputs.netlify_docs_url }}"
        FAILED_CHECKPOINTS: ${{ steps.ge.outputs.failing_checkpoints }}
        SHA: ${{ steps.chatops.outputs.SHA }}
        FAILURE_FLAG: ${{ steps.ge.outputs.checkpoint_failure_flag }}
```


# API Reference

## Inputs

### Mandatory inputs

- **`CHECKPOINTS`**:
    A comma separated list of checkpoint names to execute.  Example: "checkpoint1,checkpoint2"

### Optional Inputs

- **`NETLIFY_AUTH_TOKEN`**:
    A personal access token for [Netlify](https://www.netlify.com/).

- **`NETLIFY_SITE_ID`**:
    A [Netlify](https://www.netlify.com/) site id.

- **`DEBUG`**
    Setting this input to any value will allow the Action to exit with a status code of 0 even if a Checkpoint fails.  This is used by maintainers of this Action for testing and debugging.

## Outputs

- **`ACTION_DOCS_LOCATION`**:
    The absolute path where generated data docs generated by the Action run are located.  This is useful if you want to deploy the data docs to an external service.

- **`FAILING_CHECKPOINTS`**:
    A comma delimited list of failed checkpoints.

- **`PASSING_CHECKPOINTS`**:
    A comma delimited list of passing checkpoints.

- **`NETLIFY_DOCS_URL`**:
    The URL to the generated data docs on Netlify.  This output is only emitted only if the input parameters `NETLIFY_AUTH_TOKEN` and `NETLIFY_SITE_ID` are provided.

- **`CHECKPOINT_FAILURE_FLAG`**:
    This will return 0 if there are no Checkpoint failures and 1 if there are one or more Checkpoint failures.

# Development

This section is for those who wish to develop this GitHub Action.  Users of this Action can ignore this section.

## Installation

1. `pip install -r requirements.txt`
2. run `great_expectations init` to set up missing directories

## Usage

Run these commands from the repo root.

To see a Checkpoint pass, run `great_expectations checkpoint run passing_checkpoint`
To see a Checkpoint fail, run `great_expectations checkpoint run failing_checkpoint`

## Current limitations

- As mentioned above, this Action does not trigger your data pipeline to run, it only validates the data you point it at. You will need to configure the data pipeline run separately in your workflow, if desired.
- If a **cloud-based** `ValidationStore` is in use we may need to disable it so that the built Data Docs focus only on what is being validated in the Action without other side effects.


Please feel free to jump into the Great Expectations Slack to ask us questions about the GitHub Action [http://greatexpectations.io/slack](http://greatexpectations.io/slack)
