const { Octokit } = require("@octokit/rest");
const fs = require('fs');

// Read Event Payload
path = process.env.GITHUB_EVENT_PATH
let rawdata = fs.readFileSync(path)
let payload = JSON.parse(rawdata)

const octokit = new Octokit({
    auth: process.env.INPUT_GITHUB_TOKEN,
});

if (process.env.GITHUB_EVENT_NAME == 'pull_request'){
    let pr_number = payload.pull_request.number;
    if ( pr_number == null ){
        console.log('Not able to retrieve pull request number from payload.')
        process.exit(1);
    }

    octokit.issues.createComment({
        issue_number: pr_number,
        owner: process.env.GITHUB_REPOSITORY.split("/")[0],
        repo: process.env.GITHUB_REPOSITORY.split("/")[1],
        body: `The following Great Expectations checkpoint(s) failed: \`${process.env.FAILING_CHECKPOINTS}\`. Corresponding Data Docs have been generated for SHA: ${process.env.GITHUB_SHA} and can be viewed [here](${process.env.DOCS_URL}).`
      }); 
} else if (process.env.GITHUB_EVENT_NAME == 'issue_comment' && payload.issue.pull_request != null){

    octokit.pulls.get({
        owner: context.repo.owner,
        repo: context.repo.repo,
        pull_number: payload.issue.number
      }).then( (pr) => {

    octokit.issues.createComment({
        issue_number: payload.issue.number,
        owner: process.env.GITHUB_REPOSITORY.split("/")[0],
        repo: process.env.GITHUB_REPOSITORY.split("/")[1],
        body: `Great Expectations Data Docs have been generated for SHA: ${process.env.GITHUB_SHA} and can be viewed [here](${process.env.DOCS_URL}).`,
      });
}

