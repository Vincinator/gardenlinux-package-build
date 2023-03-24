
GARDENLINUX_BUILD_CRE ?= "sudo podman"
IMAGE_NAME ?= "gardenlinux/package-build:today"


pkg-build-container:
	./container/package-build/mk-container.sh



test-source-stage-git:
	SOURCE_TAG_PREFIX=frr- ORIGINAL_SOURCE_VIA=git SOURCE_REPO=https://github.com/FRRouting/frr SOURCE_REPO_TAG=frr-8.5 SOURCE_NAME=frr ./source.sh
test-source-stage-debian:
	SOURCE_NAME=dash ./source.sh
