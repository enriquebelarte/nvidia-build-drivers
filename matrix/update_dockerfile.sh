#!/bin/bash
set -x
# Function to update Dockerfile with version number
update_dockerfile() {
    json_file=$1
    dockerfile=$2

    result=$(cat "$json_file" | jq -r '.[] | select(.published == "n") | {release_version, kernel_version}')
    # Extract 'release_version' and 'kernel_version' from the result (first match)
    release_version=$(echo "$result" | jq -r '.release_version'| head -n1)
    kernel_version=$(echo "$result" | jq -r '.kernel_version' | head -n1 )
    sed -i "s|ARG KERNEL_VERSION='[^']*'|ARG KERNEL_VERSION='${kernel_version}'|g" "$dockerfile"
    sed -i "s|.*FROM registry\.distributed-ci\.io/dtk/driver-toolkit.*|FROM registry.distributed-ci.io/dtk/driver-toolkit:${kernel_version} as builder|g" "$dockerfile"
    sed -i "s|ARG DRIVER_VERSION='[^']*'|ARG DRIVER_VERSION='${release_version}'|g" "$dockerfile"
}

# Run the function
update_dockerfile "drivers_matrix.json" "../Dockerfile"
