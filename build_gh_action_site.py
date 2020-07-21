#!/usr/bin/env python
"""
Create a new ephemeral site store and build docs for it.

Usage: `./build_gh_action_site.py`

When DataContext.build_data_docs() is called, there are side effects that may
include external cloud storage. Here we are running in a GitHub Action, so we
create a temporary site store for use only within this action. When docs are
built we only build this temporary site.
"""
# TODO it is not yet clear if this will surprise users. If users want their
# TODO  cloud sites updated we could parameterize this behavior in the future.


import os
import uuid

import great_expectations as ge
from great_expectations.data_context.store import TupleFilesystemStoreBackend


def build_site_name() -> str:
    short_guid = str(uuid.uuid4())[0:7]
    return f"gh_action_site_{short_guid}"


def build_site_config(site_name) -> dict:
    return {
        "class_name": "SiteBuilder",
        "store_backend": {
            "class_name": "TupleFilesystemStoreBackend",
            "base_directory": f"{site_name}/",
        },
        "site_index_builder": {"class_name": "DefaultSiteIndexBuilder"},
    }


def main():
    print("Loading project")
    context = ge.DataContext("great_expectations")
    action_site_name = build_site_name()
    context_config = context.get_config()
    context_config["data_docs_sites"][action_site_name] = build_site_config(
        action_site_name
    )
    # Note we mangle the in memory DataContext and do not persist this config
    context._project_config = context_config

    print(f"Building docs for site: {action_site_name}")

    validation_store = context.stores["validations_store"]
    if not isinstance(validation_store.store_backend, TupleFilesystemStoreBackend):
        # TODO the action will likely need to run entirely in python so an ephemeral
        #  validation store can be used if desired.
        print("WARNING an external validation store exists and was likely polluted.")

    # Build only the GitHub Actions temporary site
    context.build_data_docs(site_names=[action_site_name])
    gh_site_dir = f"{context.root_directory}/{action_site_name}"
    print(f"Site built in directory: {gh_site_dir}")
    print(f'::set-output name=ACTION_DOCS_LOCATION::{gh_site_dir}')
    with open('_temp_greatexpectations_action_docs_location_dir.txt', 'w') as f:
        f.write(f"{gh_site_dir}")
    # For local debugging, this is handy to verify docs built
    if os.getenv('DEBUG_OPEN_DOCS'):
        context.open_data_docs(site_name=action_site_name)

if __name__ == "__main__":
    main()
