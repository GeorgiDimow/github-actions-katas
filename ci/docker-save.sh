#!/bin/bash
set -euo pipefail
# Ensure github_username is provided
if [[ -z "${github_username:-}" ]]; then
	echo "ERROR: github_username must be set in the environment"
	exit 1
fi
# Strip any trailing slashes from the username to avoid ghcr.io// when empty or misformatted
USER="${github_username%/}"
if [[ -z "${USER}" ]]; then
	echo "ERROR: github_username is empty after trimming; please set a valid username (lowercase)"
	exit 1
fi
[[ -z "${GIT_COMMIT:-}" ]] && Tag='local' || Tag="${GIT_COMMIT::8}"
REPO="ghcr.io/${USER}/"
IMAGE="${REPO}micronaut-app"
# Output file can be overridden with the first argument (default: image.tar)
OUTPUT="${1:-image.tar}"

# Make sure the image was built before saving
if ! docker image inspect "${IMAGE}:1.0-$Tag" > /dev/null 2>&1; then
	echo "ERROR: image ${IMAGE}:1.0-$Tag not found; run ci/build-docker.sh first"
	exit 1
fi

echo "Saving ${IMAGE}:latest and ${IMAGE}:1.0-$Tag to ${OUTPUT}"
# Save both tags into one tar, so docker load restores both
docker save -o "${OUTPUT}" "${IMAGE}:latest" "${IMAGE}:1.0-$Tag"
echo "Saved $(du -h "${OUTPUT}" | cut -f1) to ${OUTPUT}"
