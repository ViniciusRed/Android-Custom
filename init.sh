#!/bin/bash

export my_dir=$(pwd)
export PATH="$(pwd)/bin:${PATH}"

echo "Loading configuration..."
source "${my_dir}"/config.sh

if [ -z "${GITHUB_USER}" ] || [ -z "${GITHUB_EMAIL}" ]; then
    echo "GitHub user or email not set. Please enter the following information:"
    [ -z "${GITHUB_USER}" ] && read -p "GitHub Username: " GITHUB_USER
    [ -z "${GITHUB_EMAIL}" ] && read -p "GitHub Email: " GITHUB_EMAIL
    
    # Update config.sh with the new values
    sed -i "s/export GITHUB_USER=.*/export GITHUB_USER=\"${GITHUB_USER}\"/" "${my_dir}"/config.sh
    sed -i "s/export GITHUB_EMAIL=.*/export GITHUB_EMAIL=\"${GITHUB_EMAIL}\"/" "${my_dir}"/config.sh
fi

if [ -z "${GITHUB_TOKEN}" ]; then
    echo "Please set GITHUB_TOKEN before continuing."
    exit 1
fi

git config --global user.email "${GITHUB_EMAIL}"
git config --global user.name "${GITHUB_USER}"

mkdir -p "${ROM_DIR}"
cd "${ROM_DIR}"

source "${my_dir}"/sync.sh
