#!/bin/bash
# Add a logfile for debugging
#exec 19>logfile
#BASH_XTRACEFD=19
#set -x

# Set the image driver name and the registry
driver_name="nvidia-build-drivers"
registry="quay.io/ebelarte"
matrix_dir="/matrix/"
# Read the original JSON with type LTS or Production 
releases_json_lts=$(cat "$matrix_dir"releases.json | jq -r '.[] | select(.type == "lts branch")')
releases_json_prod=$(cat "$matrix_dir"releases.json | jq -r '.[] | select(.type == "production branch")')

# Read the JSON with available kernel_versions
kernel_versions_json=$(cat "$matrix_dir"kernel_versions.json)
kernel_versions=$(echo "$kernel_versions_json" | jq -r '.Tags[] | select(startswith("5"))')

# Array to store all releases
release_versions=()

# Loop over data and create JSON matrix
while IFS= read -r kernel_version; do
# Extract LTS releases <3 years
release_versions_lts=$(echo "$releases_json_lts" | jq -r --arg kernel_version "$kernel_version" --arg registry "$registry" --arg driver_name "$driver_name" '.driver_info[] | select((.release_date | strptime("%Y-%m-%d") | mktime) > (now - (3 * 365 * 24 * 60 * 60))) | {release_version: .release_version, release_date: .release_date, kernel_version: $kernel_version, image: "\($registry)/\($driver_name):\(.release_version)-\($kernel_version)"}')

# Extract production releases < 1 year
release_versions_prod=$(echo "$releases_json_prod" | jq -r --arg kernel_version "$kernel_version" --arg registry "$registry" --arg driver_name "$driver_name" '.driver_info[] | select((.release_date | strptime("%Y-%m-%d") | mktime) > (now - (1 * 365 * 24 * 60 * 60))) | {release_version: .release_version, release_date: .release_date, kernel_version: $kernel_version, image: "\($registry)/\($driver_name):\(.release_version)-\($kernel_version)"}')

# Add versions to array
release_versions+=("$release_versions_lts")
release_versions+=("$release_versions_prod")

done <<< "$kernel_versions"

# Function to check if image exists
check_image_exists() {
    local image_url=$1
    if skopeo inspect docker://"$image_url" &> /dev/null; then
        echo "y" 
    else
        echo "n"
    fi
}
release_matrix=$(echo "${release_versions[@]}" | jq -sc '.')
# Iterate over modified release versions and add "published" field if needed
for release in $(echo "${release_matrix}" | jq -c '.[]'); do
    #echo "$release" | jq -r 'to_entries | .[] | "\(.key): \(.value)"'
    image_url=$(echo "$release" | jq -r '.image')
    published=$(check_image_exists "$image_url")
    modified_release_info=$(echo "$release" | jq --arg published "$published" '. + {published: $published}')    
    echo "$modified_release_info" >> tmp_matrix
done

# Format a whole JSON for later process 
cat tmp_matrix | jq -sc '.' > "$matrix_dir"drivers_matrix.json
md5sum drivers_matrix.json > "$matrix_dir"drivers_matrix.MD5SUM
rm tmp_matrix

