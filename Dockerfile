FROM sctay/great_expectations_proof_of_concept

RUN pip install pyyaml

COPY run_checkpoints.sh /run_checkpoints.sh
COPY find_doc_location.py /find_doc_location.py
RUN chmod u+x /run_checkpoints.sh

ENTRYPOINT ["/bin/bash", "/run_checkpoints.sh"]
