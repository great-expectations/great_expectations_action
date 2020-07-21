FROM sctay/great_expectations_proof_of_concept

RUN pip install pyyaml
RUN apt-get install curl -y
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - 
RUN apt-get install -y nodejs
RUN npm install netlify-cli -g
RUN npm install @octokit/rest

COPY run_checkpoints.sh /run_checkpoints.sh
COPY build_gh_action_site.py /build_gh_action_site.py
COPY find_doc_location.py /find_doc_location.py
RUN chmod u+x /run_checkpoints.sh

ENTRYPOINT ["/bin/bash", "/run_checkpoints.sh"]
