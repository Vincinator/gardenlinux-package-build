#!/bin/bash

set -Euxo pipefail

trap 'rm -rf _output && exit' ERR

SOURCE_DIST=${SOURCE_DIST:-gardenlinux/package-build:today}
DEBFULLNAME=${DEBFULLNAME:-"Garden Linux builder"}
DEBEMAIL=${DEBEMAIL:-"contact@gardenlinux.io"}

export DEBFULLNAME
export DEBEMAIL

SOURCES_LIST=$(cat <<'EOF'
deb http://deb.debian.org/debian bookworm main
deb http://deb.debian.org/debian-security bookworm-security main
deb-src http://deb.debian.org/debian bullseye main
deb-src http://deb.debian.org/debian-security bullseye-security main
deb-src http://deb.debian.org/debian bookworm main
deb-src http://deb.debian.org/debian-security bookworm-security main
deb-src http://deb.debian.org/debian sid main
deb-src http://deb.debian.org/debian experimental main
EOF
)
source ./common.sh

function check_variable(){
  if  [ -z "${!1}" ]; then
    error "$1 not specified. Refusing to continue"
    exit 1
  fi
}
export -f check_variable



check_variable SOURCE_NAME


function get_source_git() {
  check_variable SOURCE_REPO
  check_variable SOURCE_REPO_TAG
  git -c advice.detachedHead=false clone --branch "$SOURCE_REPO_TAG" --jobs $(nproc) --depth 1 --shallow-submodules --recurse-submodules "$SOURCE_REPO" _output/src

  # Replace with own debian folder if it is present
  if [ -d "debian" ]; then
    rm -rf _output/src/debian
    cp -a debian _output/src/debian
  else 
    if [ ! -d "_output/src/debian" ]; then
      error "No Debian folder in upstream sources found."
    else 
      # Create own changelog later.
      rm -rf _output/src/debian/changelog
    fi
  fi
}

function get_source() {
  case "$1" in
    git)
      echo "Get Source from git repository"
      get_source_git
      ;;
    lfs)
      echo "Get Source from git-lfs"
      ;;
    debian)
      echo "Get Source from debian apt src repo"
      ;;
    *)
      echo "'$PACKAGE_SOURCE_OGIGIN' is unknown"
      ;;
  esac
}


function generate_automated_changelog() {
  check_variable SOURCE_REPO
  check_variable UPSTREAM_VERSION

  pushd _output/src
  case "$1" in
    local)
      notice "Create local version (changelog)"
      version=${UPSTREAM_VERSION}-0gardenlinux~0.local
      dch --create --package $SOURCE_NAME --newversion "$version" --distribution UNRELEASED --force-distribution -- \
        'Rebuild for Garden Linux.' \
        "Local build."
      ;;
    release)
      notice "Create release version (changelog)"
      dch --create --package $SOURCE_NAME --newversion "$version" --distribution gardenlinux --force-distribution -- \
        'Rebuild for Garden Linux.'
      ;;
    pr)
      notice "Create pr version (changelog)"
      version=${UPSTREAM_VERSION}-0gardenlinux~${GITHUB_REF_NAME}.${GITHUB_JOB}.${GITHUB_SHA}
      dch --create --package $SOURCE_NAME --newversion "$version" --distribution UNRELEASED --force-distribution -- \
        'Rebuild for Garden Linux.' \
        "Snapshot from pull request ${GITHUB_REF_NAME}."
      ;;
  esac
  popd
}

function apply_build_env_patches(){

  gardenlinux_package_root=$1

  if [ -e $gardenlinux_package_root/patches/series ]; then
    for patch in $(grep -vE '^( |#)' $gardenlinux_package_root/patches/series); do
      echo "Applying $patch"
      desc=$(sed -nEe 's/^(Description|Subject): +(.*)$/\2/p' $gardenlinux_package_root/patches/$patch)
      dch --append "$desc."
      patch -p1 < $gardenlinux_package_root/patches/$patch
    done
  fi
  
}

function build_source(){

  pushd _output/src
  make -f ./debian/rules source

  EDITOR=true dpkg-source --commit . gardenlinux-changes
  dpkg-buildpackage -us -uc -S -nc -d
  popd
}

export DEB_BUILD_OPTIONS="nodoc terse"
export DEB_BUILD_PROFILES="nodoc noudeb"
get_source git

generate_automated_changelog local
apply_build_env_patches $(pwd)
build_source


