#!/bin/bash


WORKSPACE=$(pwd)
#thisDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
CONTAINER_IMAGE=${CONTAINER_IMAGE:-"gardenlinux/package-build:today"}

[ ! -d "$WORKSPACE" ] && echo "$WORKSPACE does not exist." && exit 1

docker run \
    -ti \
    --device /dev/fuse \
    --privileged \
    -v "${WORKSPACE}":/workspace \
    --rm \
    -w /workspace \
    "${CONTAINER_IMAGE}" \
    '/bin/bash -c "$1"'
