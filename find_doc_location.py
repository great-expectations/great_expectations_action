"""
Find local site location and emit that as a variable for Actions on stdout
"""
import yaml

# Read YAML file
with open("great_expectations/great_expectations.yml", 'r') as stream:
    config = yaml.safe_load(stream)
    try:
        location = f"great_expectations/{config['data_docs_sites']['local_site']['store_backend']['base_directory']}"
    except:
        location = "great_expectations/uncommitted/data_docs/local_site/"

print(f'::set-output name=local_docs_location::{location}')
