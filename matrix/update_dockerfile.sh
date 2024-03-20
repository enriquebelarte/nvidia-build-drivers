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

update_pipelinerun(){
pr_file="../.tekton/nvidia-build-drivers-push.yaml"
output_container="nvidia-build-drivers"
existing_version=$(grep -A1 "name: output-image" "$pr_file" | awk -v output_container="$output_container" -F: 'NR==2 && $0 ~ $output_container {print $3}')
new_version="$release_version-$kernel_version"
sed -i "s/$existing_version/$new_version/g" $pr_file
}

# Run the function
update_dockerfile "drivers_matrix.json" "../Dockerfile"
update_pipelinerun
