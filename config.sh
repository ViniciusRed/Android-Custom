#!/bin/bash

export GITHUB_USER=${GITHUB_USER:-$(git config --get user.name)}
export GITHUB_EMAIL=${GITHUB_EMAIL:-$(git config --get user.email)}

export device=""

export ROM=""
export ROM_DIR=""
export ROM_VERSION=""
export local_manifest_url=""
export manifest_url=""
export rom_vendor_name=""
export branch=""
export bacon="bacon"
export buildtype=""
export clean=""
export generate_incremental=""
export upload_recovery=""

export ccache=""
export ccache_size=""

export jenkins="false"

export release_repo=""

export timezone="UTC"
