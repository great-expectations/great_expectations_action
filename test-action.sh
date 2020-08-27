#!/bin/bash
# This script helps to test the Action locally

docker build -t test-ge-action .

docker run -e INPUT_CHECKPOINTS="npi.pass,npi.fail" \
-e INPUT_NETLIFY_AUTH_TOKEN=$NETLIFY_AUTH_TOKEN \
-e INPUT_NETLIFY_SITE_ID=$NETLIFY_SITE_ID \
-e INPUT_GE_HOME="test" \
-e GITHUB_REPOSITORY="$GITHUB_REPOSITORY" \
-v $PWD:/usr/app/great_expectations test-ge-action

# cleanupls
rm -rf great_expectations/gh_action_site_*
rm -rf great_expectations/uncommitted/


# docker run -e INPUT_CHECKPOINTS="npi.pass,npi.fail" \
# -e INPUT_NETLIFY_AUTH_TOKEN=$NETLIFY_AUTH_TOKEN \
# -e INPUT_NETLIFY_SITE_ID=$NETLIFY_SITE_ID \
# -e INPUT_GE_HOME="test" \
# -e GITHUB_REPOSITORY="$GITHUB_REPOSITORY" \
# -v $PWD:/usr/app/great_expectations \
# -it --entrypoint /bin/bash test-ge-action