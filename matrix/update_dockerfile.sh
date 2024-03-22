#!/usr/bin/env bash
#set -x
# Function to update Dockerfile with version number
update_dockerfile(){
    json_file=$1
    dockerfile=$2
    
    result=$(cat "$json_file" | jq -r '.[] | select(.published == "n") | {release_version, kernel_version}')
    # Extract 'release_version' and 'kernel_version' from the result (first match)
    release_version=$(echo "$result" | jq -r '.release_version' | head -n1 )
    kernel_version=$(echo "$result" | jq -r '.kernel_version' | head -n1 )
    
    sed -i "s|ARG KERNEL_VERSION='[^']*'|ARG KERNEL_VERSION='${kernel_version}'|g" "$dockerfile"
    sed -i "s|.*FROM registry\.distributed-ci\.io/dtk/driver-toolkit.*|FROM registry.distributed-ci.io/dtk/driver-toolkit:${kernel_version} as builder|g" "$dockerfile"
    sed -i "s|ARG DRIVER_VERSION='[^']*'|ARG DRIVER_VERSION='${release_version}'|g" "$dockerfile"
}

# Function to update pipelineRun with image matching above results
# Will change the value after the first match for output-image
pipelinerun_file="../.tekton/nvidia-build-drivers-push.yaml"
registry_repo="quay.io/ebelarte/nvidia-build-drivers"

update_pipelinerun(){
	new_image="$registry_repo:$release_version-$kernel_version"
        output_image_line=$(grep -m1 -n "output-image" "$pipelinerun_file" | cut -d: -f1)
        value_line_number=$((output_image_line + 1))
        sed -i "${value_line_number}s|value:.*|value: $new_image|" "$pipelinerun_file"
}

# Run the functions
update_dockerfile "drivers_matrix.json" "../Dockerfile"
update_pipelinerun
