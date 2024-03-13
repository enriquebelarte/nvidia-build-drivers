#!/bin/bash
set -x
# Read the original JSON with release_versions
releases_json=$(cat releases.json)

# Read the JSON with kernel_versions
kernel_versions_json=$(cat kernel_versions.json)

# Extract release_versions
release_versions=$(echo  "$releases_json" | jq -r '.[] | select(.type == "lts branch" or .type == "production branch") | .driver_info[].release_version') 
# Extract kernel_versions
kernel_versions=$(echo "$kernel_versions_json" | jq -r '.Tags[] | select(startswith("5"))')

# Create an array to store the combinations
drivers_matrix=()

# Iterate through all combinations and check if the image exists
for release_version in $release_versions; do
    for kernel_version in $kernel_versions; do
        image_name="quay.io/myrepo/driver-$release_version:$kernel_version"
	image_published="n"
        #if docker inspect "$image_name" &> /dev/null; then
        #    image_published="y"
        #else
        #    image_published="n"
        #fi

        # Add the combination to the array
        drivers_matrix+=("{\"release_version\": \"$release_version\", \"kernel_version\": \"$kernel_version\", \"image_published\": \"$image_published\"}")
    done
done

# Convert the array to JSON format
json_result="{\"drivers_matrix\": [$(IFS=,; echo "${drivers_matrix[*]}")]}"

# Print the final JSON
echo "$json_result" | jq . > drivers_matrix.json

