# variables:
#   DEBFULLNAME: "Garden Linux builder"
#   DEBEMAIL: "contact@gardenlinux.io"
#   SOURCE_NAME: $CI_PROJECT_NAME
#   SOURCE_DIST: bookworm
#   SOURCES_LIST: |
#     deb http://deb.debian.org/debian bookworm main
#     deb http://deb.debian.org/debian-security bookworm-security main
#     deb-src http://deb.debian.org/debian bullseye main
#     deb-src http://deb.debian.org/debian-security bullseye-security main
#     deb-src http://deb.debian.org/debian bookworm main
#     deb-src http://deb.debian.org/debian-security bookworm-security main
#     deb-src http://deb.debian.org/debian sid main
#     deb-src http://deb.debian.org/debian experimental main

# before_script:
function do_before_script(){
  if [[ $CI_DISPOSABLE_ENVIRONMENT ]]; then
    echo -n "$SOURCES_LIST" > /etc/apt/sources.list
    apt-get update -qy
    apt-get install -qy --no-install-recommends devscripts pristine-lfs rsync
  fi
}


# script:
function do_script() {
  if [[ ${CI_COMMIT_TAG:-} ]]; then
    TAG_VERSION=${CI_COMMIT_TAG#*/}
    TAG_VERSION=${TAG_VERSION/\%/:}
    TAG_VERSION=${TAG_VERSION/\_/\~}
    echo "Target Version: $TAG_VERSION"
    APT_NAME=${SOURCE_NAME}=${TAG_VERSION%garden*}
  else
    APT_NAME=${SOURCE_NAME}/${SOURCE_DIST}
  fi
  ROOT=$(pwd)
  mkdir _output
  if [[ ${ORIG_TAR:-} ]]; then
    echo '### pulling existing orig via pristine-lfs'
    git fetch --quiet --depth 1 origin pristine-lfs
    echo "### Get latest Upstream Version in pristine-lfs"
    LATEST_TARBALL="$(pristine-lfs list | grep 'orig.tar.' | sort -r -V | head -n1)"
    SOURCE_NAME=${LATEST_TARBALL%_*}
    UPSTREAM_VERSION="${LATEST_TARBALL%.orig*}"
    UPSTREAM_VERSION="${UPSTREAM_VERSION#*_}"
    if [[ ${CI_COMMIT_TAG:-} ]]; then
      if [[ "${UPSTREAM_VERSION}" != "${TAG_VERSION%-*}" ]]; then
        echo "ERROR: sources for version ${TAG_VERSION%-*} not found in pristine-lfs."
        exit 1
      fi
    fi
    pristine-lfs checkout "_output/${LATEST_TARBALL}" || true
    if [[ -e "_output/${LATEST_TARBALL}" ]]; then
      cd _output
      echo "### unpack source"
      tar -xf "${LATEST_TARBALL}"
    else
      echo "### Specified ORIG_TAR='${ORIG_TAR}' was not found in pristine-lfs branch"
      exit 1
    fi
  else 
    apt source --only-source -d $APT_NAME
    cd _output
    dpkg-source -x ../$SOURCE_NAME_*.dsc
  fi
  echo "### Get path to source folder"
  SOURCE_DIR_UNPACKED=$(find "$ROOT/_output" -maxdepth 1 -type d -name "$SOURCE_NAME-*")
  SOURCE_DIR_UNPACKED=$(readlink -e "$SOURCE_DIR_UNPACKED")
  if [[ ${ORIG_TAR:-} ]]; then
    if [[ -d "$ROOT/debian" ]]; then
      echo "### Replace debian folder with own content"
      rsync -a "$ROOT/debian" "${SOURCE_DIR_UNPACKED}"
    fi
  fi
  cd "$SOURCE_DIR_UNPACKED"
  if [[ ${CI_COMMIT_TAG:-} ]]; then
    dch --newversion $TAG_VERSION --distribution gardenlinux --force-distribution -- \
      'Rebuild for Garden Linux.'
  elif [[ ${CI_MERGE_REQUEST_IID:-} ]]; then
    VERSION="$(dpkg-parsechangelog -SVersion)gardenlinux~${CI_MERGE_REQUEST_IID}.${CI_PIPELINE_ID}.${CI_COMMIT_SHORT_SHA}"
    dch --newversion $VERSION --distribution UNRELEASED --force-distribution -- \
      'Rebuild for Garden Linux.' \
      "Snapshot from merge request ${CI_MERGE_REQUEST_IID}."
  else
    VERSION="$(dpkg-parsechangelog -SVersion)gardenlinux~0.${CI_PIPELINE_ID}.${CI_COMMIT_SHORT_SHA}"
    dch --newversion $VERSION --distribution UNRELEASED --force-distribution -- \
      'Rebuild for Garden Linux.' \
      "Snapshot from branch ${CI_COMMIT_REF_NAME}."
  fi
  if [ -e $ROOT/patches/series ]; then
    for patch in $(grep -vE '^( |#)' $ROOT/patches/series); do
      desc=$(sed -nEe 's/^(Description|Subject): +(.*)$/\2/p' $ROOT/patches/$patch)
      dch --append "$desc."
      patch -p1 < $ROOT/patches/$patch
    done
  fi
  EDITOR=true dpkg-source --commit . gardenlinux-changes
  dpkg-buildpackage -us -uc -S -nc -d

}

# artifacts:
#   paths:
#   - _output/*.changes
#   - _output/*.dsc
#   - _output/*.tar.*
#   expire_in: 2 days
