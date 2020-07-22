FROM sctay/great_expectations_proof_of_concept

RUN apt-get install curl nodejs -y
RUN curl -L https://npmjs.org/install.sh | bash
RUN npm install -g netlify-cli
ENV NODE_PATH="/usr/lib/node_modules"

COPY run_checkpoints.sh /run_checkpoints.sh
COPY build_gh_action_site.py /build_gh_action_site.py
RUN chmod u+x /run_checkpoints.sh

ENTRYPOINT ["/bin/bash", "/run_checkpoints.sh"]
