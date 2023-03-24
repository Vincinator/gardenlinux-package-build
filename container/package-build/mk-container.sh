#!/bin/bash
set -x 
GARDENLINUX_BUILD_CRE=${GARDENLINUX_BUILD_CRE:-docker}

thisDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

#VERSION=$("${thisDir}/../../bin/garden-version")

if  [ -z "${GARDENLINUX_PKG_BUILD_IMAGE_NAME}" ]; then
    echo " not specified. Refusing to continue"
    exit 1
fi

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

${GARDENLINUX_BUILD_CRE} build \
  --build-arg SOURCES_LIST="$SOURCES_LIST" \
  -t "$GARDENLINUX_PKG_BUILD_IMAGE_NAME":today \
   "$thisDir"
