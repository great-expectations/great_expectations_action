import logging
import sys
import requests
import json
import ipdb

from great_expectations.validation_operators.actions import ValidationAction


class GHIssue(ValidationAction):
    def __init__(
        self, data_context, issue_title, token, repo_owner, repo_name):
        super().__init__(data_context)
        self.data_context = data_context
        self.issue_title = issue_title
        self.token = token
        self.repo_owner = repo_owner
        self.repo_name = repo_name
  
    def _run(self,
             validation_result_suite,
             validation_result_suite_identifier,
             data_asset=None):
        # ipdb.set_trace()
        results = self.data_context.validations_store.get(validation_result_suite_identifier)
        msg = self.parse_results(results)
        self.create_github_issue(issue_body=msg)

    def create_github_issue(self, issue_body):
        """
        Create an Issue on github.com using via the REST API.
        """
        url = f'https://api.github.com/repos/{self.repo_owner}/{self.repo_name}/import/issues'
        
        # Headers
        headers = {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.golden-comet-preview+json"
        }
        
        # Create issue
        data = {'issue': {'title': self.issue_title,
                        'body': issue_body,
                        }}

        # Add the issue to the repository
        response = requests.request("POST", url, data=json.dumps(data), headers=headers)
        if response.status_code == 202:
            logging.debug(f'Successfully created Issue "{self.issue_title}"')
        else:
            err_msg = f'Could not create Issue "{self.issue_title}"'
            logging.error(err_msg)
            logging.error(f"Response: {response.content}")
            raise Exception(err_msg)

    def parse_results(self, results):
        """
        Transform metadata into markdown formatted text that can be rendered on a GitHub Issue.
        """
        s = results.statistics
        meta = results.meta
        msg_heading = f"# Expecation Suite `{meta['expectation_suite_name']}` Failed\n"
        msg_fail = f"{s['unsuccessful_expectations']:,} of {s['evaluated_expectations']:,} ({100-s['success_percent']:3.1f}%) Expectations Failed"
        
        msg_batch_kwargs = '## Metadata\n'
        msg_batch_kwargs += '\n'.join([f" - {k}: {meta['batch_kwargs'][k]}" for k in meta['batch_kwargs']])
        
        msg_time = '## Runtime\n'
        msg_time += '\n'.join([f" - {k}: {meta['run_id'][k]}" for k in meta['run_id']])
        msg_time += f"\n - validation_time: {meta['validation_time']}"
        
        return '\n'.join([msg_heading, msg_fail, msg_batch_kwargs, msg_time])