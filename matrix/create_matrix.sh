#!/bin/bash
#set -x
# Set the image driver name and the registry
driver_name="nvidia"
registry="quay.io/ebelarte"

# Read the original JSON with type LTS or Production 
releases_json_lts=$(cat releases.json | jq -r '.[] | select(.type == "lts branch")')
releases_json_prod=$(cat releases.json | jq -r '.[] | select(.type == "production branch")')

# Read the JSON with available kernel_versions
kernel_versions_json=$(cat kernel_versions.json)
kernel_versions=$(echo "$kernel_versions_json" | jq -r '.Tags[] | select(startswith("5"))')

# Function to check if image exists
check_image_exists() {
    local image_url=$1
    if skopeo inspect docker://"$image_url" &> /dev/null; then
        echo "y"
    else
        echo "n"
    fi
}

# Array to store all releases
release_versions=()

# Loop over data and create JSON matrix
while IFS= read -r kernel_version; do
# Extract LTS releases <3 years
release_versions_lts=$(echo "$releases_json_lts" | jq -r --arg kernel_version "$kernel_version" --arg registry "$registry" --arg driver_name "$driver_name" '.driver_info[] | select((.release_date | strptime("%Y-%m-%d") | mktime) > (now - (3 * 365 * 24 * 60 * 60))) | {release_version: .release_version, release_date: .release_date, kernel_version: $kernel_version, image: "\($registry)/\($driver_name)-\(.release_version):\($kernel_version)"}')

# Extract production releases < 1 year
release_versions_prod=$(echo "$releases_json_prod" | jq -r --arg kernel_version "$kernel_version" --arg registry "$registry" --arg driver_name "$driver_name" '.driver_info[] | select((.release_date | strptime("%Y-%m-%d") | mktime) > (now - (1 * 365 * 24 * 60 * 60))) | {release_version: .release_version, release_date: .release_date, kernel_version: $kernel_version, image: "\($registry)/\($driver_name)-\(.release_version):\($kernel_version)"}')

# Add versions to array
release_versions+=("$release_versions_lts")
release_versions+=("$release_versions_prod")

done <<< "$kernel_versions"

# Delete previous matrix if exists before creating the new one
rm -f drivers_matrix.json

# Iterate over modified release versions and add "published" field
for release_info in "${release_versions[@]}"; do
    image_url=$(echo "$release_info" | jq -r '.image')
    published=$(check_image_exists "$image_url")
    modified_release_info=$(echo "$release_info" | jq --arg published "$published" '. + {published: $published}')
    # Delete previous matrix if exists before creating the new one
    echo "$modified_release_info" >> drivers_matrix.json
    md5sum drivers_matrix.json > drivers_matrix.MD5SUM 
done
