
GARDENLINUX_BUILD_CRE ?= "sudo podman"
GARDENLINUX_VERSION ?= $(shell bin/garden-version)


# TODO: Rename to gardenlinux organization package name 
GARDENLINUX_PKG_BUILD_IMAGE_NAME ?= "package-build"

pkg-build-container:
	GARDENLINUX_PKG_BUILD_IMAGE_NAME="$(GARDENLINUX_PKG_BUILD_IMAGE_NAME)" VERSION=$(GARDENLINUX_VERSION) ./container/package-build/mk-container.sh

test-source-stage-git:
	SOURCE_TAG_PREFIX=frr- ORIGINAL_SOURCE_VIA=git SOURCE_REPO=https://github.com/FRRouting/frr SOURCE_REPO_TAG=frr-8.5 SOURCE_NAME=frr ./source.sh
test-source-stage-debian:
	SOURCE_NAME=dash ./source.sh
