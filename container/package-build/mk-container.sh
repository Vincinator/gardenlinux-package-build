#!/bin/bash
set -x 
GARDENLINUX_BUILD_CRE=${GARDENLINUX_BUILD_CRE:-docker}

thisDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

#VERSION=$("${thisDir}/../../bin/garden-version")


IMAGE_NAME=${IMAGE_NAME:-vincinator/package-build}


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
  -t "$IMAGE_NAME":today \
   "$thisDir"
