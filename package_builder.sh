#!/bin/bash

container_run_opts=(
	--security-opt seccomp=unconfined
	--security-opt apparmor=unconfined
	--security-opt label=disable
)

container_mount_opts=(
	-v "$PWD/package:/package"
)


IMAGE_NAME="package-builder"
podman run "${container_run_opts[@]}" "${container_mount_opts[@]}" ${IMAGE_NAME} "$@"
