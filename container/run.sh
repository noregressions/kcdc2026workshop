#!/usr/bin/env bash
# Run the workshop container.
#
#   - mounts the host Docker socket: docker/scout/syft-on-images inside the
#     container operate on YOUR daemon (this is required for S01/S02 and
#     T02-T04)
#   - passes SNYK_TOKEN and NVD_API_KEY through when set locally
set -euo pipefail

exec docker run --rm -it \
  --name shipping-workshop \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ${SNYK_TOKEN:+-e SNYK_TOKEN} \
  ${NVD_API_KEY:+-e NVD_API_KEY} \
  shipping-workshop:latest
