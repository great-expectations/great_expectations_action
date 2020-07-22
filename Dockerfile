FROM sctay/great_expectations_proof_of_concept

RUN pip install pyyaml
RUN apt-get install curl -y
RUN apt-get install -y nodejs
RUN curl -L https://npmjs.org/install.sh | bash
RUN npm install -g netlify-cli 
RUN npm install -g @octokit/rest
ENV NODE_PATH="/usr/lib/node_modules"

COPY run_checkpoints.sh /run_checkpoints.sh
COPY comment_on_pr.js /comment_on_pr.js
COPY build_gh_action_site.py /build_gh_action_site.py
COPY find_doc_location.py /find_doc_location.py
RUN chmod u+x /run_checkpoints.sh

ENTRYPOINT ["/bin/bash", "/run_checkpoints.sh"]
