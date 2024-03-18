#!/bin/bash

# Function to update Dockerfile with version number
update_dockerfile() {
    json_file=$1
    dockerfile=$2

    while IFS= read -r line; do
        release_version=$(jq -r '.release_version' <<< "$line")
        published=$(jq -r '.published' <<< "$line")
        kernel_version=$(jq -r '.kernel_version' <<< "$line")
        
        if [ "$published" = "n" ]; then
            sed -i "s|ARG KERNEL_VERSION='[^']*'|ARG KERNEL_VERSION='${kernel_version}'|g; s|registry\.distributed-ci\.io/dtk/driver-toolkit|FROM registry.distributed-ci.io/dtk/driver-toolkit:\${kernel_version} as builder|g" "$dockerfile"

            sed -i "s|ARG DRIVER_VERSION='[^']*'|ARG DRIVER_VERSION='${release_version}'|g" "$dockerfile"
        fi
    done < "$json_file"
}

# Run the function
update_dockerfile "drivers_matrix.json" "../Dockerfile"
