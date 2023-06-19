#!/bin/bash

container_run_opts=(
	--security-opt seccomp=unconfined
	--security-opt apparmor=unconfined
	--security-opt label=disable
)

container_mount_opts=(
	-v "$PWD/output:/output"
)


IMAGE_NAME="package-builder"
mkdir -p output
podman run "${container_run_opts[@]}" "${container_mount_opts[@]}" ${IMAGE_NAME} "$@"
