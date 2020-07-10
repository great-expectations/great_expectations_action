FROM sctay/great_expectations_proof_of_concept

COPY run_checkpoints.sh /run_checkpoints.sh
RUN chmod u+x /run_checkpoints.sh

ENTRYPOINT ["/bin/bash", "/run_checkpoints.sh"]
