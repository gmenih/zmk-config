#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="zmk-builder"

# Rebuild image if Dockerfile or entrypoint changed
NEEDS_BUILD=false
if ! docker image inspect "${IMAGE_NAME}" &>/dev/null; then
  NEEDS_BUILD=true
else
  IMAGE_DATE=$(docker inspect -f '{{.Created}}' "${IMAGE_NAME}")
  for f in Dockerfile docker-entrypoint.sh; do
    if [ "${SCRIPT_DIR}/${f}" -nt <(echo "${IMAGE_DATE}") ]; then
      NEEDS_BUILD=true
      break
    fi
  done
fi

if [ "${NEEDS_BUILD}" = true ]; then
  echo "Building Docker image..."
  docker build -t "${IMAGE_NAME}" "${SCRIPT_DIR}"
fi

# Run the build (mount repo directly at /workspace)
docker run --rm \
  -v "${SCRIPT_DIR}:/workspace" \
  "${IMAGE_NAME}" \
  docker-entrypoint.sh "$@"
