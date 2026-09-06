#!/usr/bin/env bash
# Tag the locally built workshop image and push it to Docker Hub.
#
#   ./container/publish.sh 0.0.1          tag + push shipping-workshop:latest
#                                         as noregressions/ydnwys-workshop:0.0.1
#                                         (and :latest)
#   ./container/publish.sh 0.0.1 --base   also push the tools/base image as
#                                         noregressions/ydnwys-workshop-base:0.0.1
#
# Log in as the account that owns the noregressions namespace first:
#   docker login -u <username>
#
# NOTE: this pushes whatever platform the local image was built for (on an
# Apple silicon Mac that is linux/arm64 only). A multi-arch image needs a
# buildx build with --platform linux/amd64,linux/arm64 --push instead.
set -euo pipefail

REPO=noregressions/ydnwys-workshop
VERSION="${1:?usage: $0 <version> [--base]}"

push() {
  local src=$1 dst=$2
  echo "== $src -> $dst:$VERSION =="
  docker tag "$src" "$dst:$VERSION"
  docker tag "$src" "$dst:latest"
  docker push "$dst:$VERSION"
  docker push "$dst:latest"
}

if [[ "${2:-}" == "--base" ]]; then
  push shipping-workshop-base:latest "$REPO-base"
fi
push shipping-workshop:latest "$REPO"
