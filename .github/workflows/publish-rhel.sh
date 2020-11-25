#!/bin/bash

get_containers()
{
    PROJECT_ID=$1
    VERSION=$2
    API_KEY=$3

    RESPONSE=$( \
        curl --silent \
             --request POST \
             --header "Content-Type: application/json" \
             --header "Authorization: Bearer ${API_KEY}" \
             --data {} \
             "https://connect.redhat.com/api/v2/projects/${PROJECT_ID}/tags?tags=${VERSION}")

    echo "${RESPONSE}"
}

get_container_build()
{
    PROJECT_ID=$1
    VERSION=$2
    API_KEY=$3

    BUILD=$(get_containers "${PROJECT_ID}" "${VERSION}" "${API_KEY}" | jq -r '.tags[0]')
    if [ "${BUILD}" == "null" ]; then
        # TAG can be also stored as "${VERSION}, latest"
        BUILD=$(get_containers "${PROJECT_ID}" "${VERSION}%2C%20latest" "${API_KEY}" | jq -r '.tags[0]')
    fi
    echo "${BUILD}"
}

is_build_valid()
{
    BUILD=$1

    echo "${BUILD}" | jq -r '.digest' > /dev/null
    return $?
}

# Check parameters
if [ "$#" -ne 3 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Assign API Key and Project ID
API_KEY=$1
PROJECT_ID=$2
VERSION=$3

# Wait until the image is built and scanned
for i in `seq 1 10`; do
    BUILD=$(get_container_build "${PROJECT_ID}" "${VERSION}" ${API_KEY})
    SCAN_STATUS=$(echo "${BUILD}" | jq -r '.scan_status')
    DIGEST=$(echo "${BUILD}" | jq -r '.digest')
    if [ "${SCAN_STATUS}" == "passed" ]; then
        break
    fi
    echo "Building or scanning in progress, waiting..."
    sleep 120
    if [ "$i" = "10" ]; then

    fi
done

# Publish the image
echo "Publishing the image..."
RESPONSE=$( \
    curl --silent \
         --request POST \
         --header "Authorization: Bearer ${API_KEY}" \
         --header 'Cache-Control: no-cache' \
         --header 'Content-Type: application/json' \
         --data {} \
         "https://connect.redhat.com/api/v2/projects/${PROJECT_ID}/containers/${DIGEST}/tags/${VERSION}/publish")
STATUS=$(echo "${RESPONSE}" | jq -r '.status')

# Result message
if [ "${STATUS}" == "OK" ]; then
    echo "Done."
    exit 0
else
    ERROR=$(echo "${RESPONSE}" | jq -r '.data.errors[0]')
    if [[ "${ERROR}" == 'Container image is already published'* ]]; then
        echo "Image is already published. Skipped."
        exit 0
    else
        echo "Error, result message: ${RESPONSE}"
        exit 42
    fi
fi