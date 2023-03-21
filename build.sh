# variables:
#   EXCLUDE_ARTIFACT: ignore
#   BUILD_DIST: bookworm
#   BUILD_DIST_GARDENLINUX: today
#   BUILD_IMAGE: debian:${BUILD_DIST}-slim
#   BUILD_SOURCES_LIST: |
#     deb http://deb.debian.org/debian ${BUILD_DIST} main
#     deb http://deb.debian.org/debian-security ${BUILD_DIST}-security main
#   BUILD_SOURCES_LIST_GARDENLINUX: |
#     deb http://repo.gardenlinux.io/gardenlinux ${BUILD_DIST_GARDENLINUX} main
#   BUILD_KEY_GARDENLINUX: |
#     -----BEGIN PGP PUBLIC KEY BLOCK-----

#     mQINBGN3UG4BEACUPRC/gZekjtoaszk7+TdJUi4E6U9asuUu2p9TvXpItQHcjBc4
#     XZhKvrtJotft/KJQf7/hkS587QfaRzMqzIJe7WC3ttm/SWNQee9VDUOzNCBaIPrq
#     9iv0wZn+UtfbnKqUj8oknuo4BIKBdMJML4WiAsueP2wIrl0K37axoXfBFRXXmIhd
#     48xZKGw3MeoZKhv5buATwv7tnJAlWXmSAn1lJolVhcdsl6npN1RPWAUPbhUoeaYQ
#     zA2crak8PSe9B2foCoJ/7a4wtN4f9aI2+XYbMa97/9UzbcH8c1Cx4hSQpc7p0Csf
#     5Ig0h/dLAFQ11xPbCgchh6EqZY46327H5vEXxhNVOAoQqIp+MEW12Gok6fDJX4Ts
#     zA8k4X8w5SEdhCKd4sUBYU8CzlejXqykHRkqlYi/kR4qAUsbaNy3naIqGb+hdeSs
#     1Ch7X5sXArK1ua6a2xTlzpV7UesQddR31XBxg1y8zuqkD4YhxbcLx9i27kC9pyYm
#     5aCE215k9NXnmeBI80VsEWbfxRomwIZ4XK0QiVqOS8f/yQtU2dZbAOEEb5hPhLvK
#     fhfFwBuLCuu4BQLBJCYX4tEvwtecXG31/3w+EbEBoFZ9HKRxIQgNM8u5pS4uKk9S
#     fBJRbliCtyynOkTRRBy8nUgoPhHAIruBfVo5CiRF8j/NRnCjp5glPNTuoQARAQAB
#     tEJHYXJkZW4gTGludXggQXV0b21hdGljIFNpZ25pbmcgS2V5ICgyMDIyKSA8Y29u
#     dGFjdEBnYXJkZW5saW51eC5pbz6JAlQEEwEKAD4WIQTwpt05wx1W5TUPBqaLrXaj
#     keK7UQUCY3dQbgIbLwUJBaOagAULCQgHAgYVCgkICwIEFgIDAQIeAQIXgAAKCRCL
#     rXajkeK7UTcQD/9/Jxg34xhrzUpOStFtxo9JrsAUc38rAUEbFL30LSX9DG5fCHff
#     6MCOGSI9zenc95O3hXOFb9mlQJrEFc7oYlqePbxqXCstOvyavKw53KddEKrpp+zZ
#     EIfbcXIsMh6c3G0fxPaAlFnjXprEzEDtPMfr3aa7fLZJENQbpOzyt//8AtFwYv2u
#     3sEgYwPo07PQf60g7pIfkC6rkg3RexwMkhquh2gdBQo1I/jloWLsDhn+Hi+/zsbs
#     ny/IC8YZl3iMu+5pY5eRL+Uu3lslA8IB6Pjp1x2kBIP6PeVANAg/5vXqq1qn8aoG
#     z6+8JcIMDUETlnx19b6SqZd1shFlxlodU8qUtoAisk+WRoHCetkFSPvLr4EVloTb
#     SUB7gHPBWqjrCP39lYPsN52fgBiG2Nko+bnU9BSPt5VIvYQfvX3gx0FXQbW1zeZ6
#     gq4w3lWajqilmS5F8x2pBJAFdLZw7f5t4w0NoGA2edJEc51+JW0/BgKmImQOjiOg
#     dD34FwP49P6orG14l/q3meKfJB0O660N09+liEHLo9zJtOUp8v+EwAjB81/LRLpV
#     HNRHTVOxDJRDDC2wjbhN38BtfjnLKFz2S/hZNIDeqz53fSgpGftdiBNhLS8wI2E1
#     ciUIHaRWRlvgpEo1KsHk3Knn+t+f+5Fxyi9Yj9QMU5Hi7zKex9hBDReBrA==
#     =93j9
#     -----END PGP PUBLIC KEY BLOCK-----

# before_script:
function do_before_script() {
  if [[ $CI_DISPOSABLE_ENVIRONMENT ]]; then
    echo -n "$BUILD_SOURCES_LIST" > /etc/apt/sources.list
    if [[ ${BUILD_USE_GARDENLINUX:-} ]]; then
      echo -n "$BUILD_SOURCES_LIST_GARDENLINUX" >> /etc/apt/sources.list
      echo "$BUILD_KEY_GARDENLINUX" >> /etc/apt/trusted.gpg.d/gardenlinux.asc
    fi
    if [[ $JOB_HOST_ARCH != all ]]; then
      dpkg --add-architecture $JOB_HOST_ARCH
    fi
    apt-get update -qy
    apt-get upgrade -qy -o DPkg::Options::=--force-unsafe-io fakeroot
    if [[ ${BUILD_REQUIRES_GO:-} ]]; then
      apt-get install -qy --no-install-recommends golang
    fi
    apt-get install -qy --no-install-recommends ca-certificates
    if [[ $JOB_HOST_ARCH = all ]]; then
      apt-get build-dep -qy --indep-only -o DPkg::Options::=--force-unsafe-io ./_output/*.dsc
    else
      if [[ $JOB_HOST_ARCH != $(dpkg --print-architecture) ]]; then
        export DEB_BUILD_PROFILES="${DEB_BUILD_PROFILES:-} cross"
      fi
      apt-get build-dep -qy -a $JOB_HOST_ARCH --arch-only -o DPkg::Options::=--force-unsafe-io ./_output/*.dsc
      # Workaround for non-multiarch build-essential, see https://bugs.debian.org/666743
      apt-get install -qy --no-install-recommends binutils-$JOB_HOST_GNU_TYPE_PACKAGE gcc-$JOB_HOST_GNU_TYPE_PACKAGE g++-$JOB_HOST_GNU_TYPE_PACKAGE libc6-dev:$JOB_HOST_ARCH
    fi
  fi
  if [[ ${UPLOAD_OUTPUT_TO_S3:-} && ${CI_COMMIT_REF_PROTECTED:-} ]]; then
    apt-get update -qy
    apt-get install -qy --no-install-recommends python3 python3-pip python3-venv
    export VIRTUAL_ENV=/opt/venv
    python3 -m venv $VIRTUAL_ENV;
    PATH="$VIRTUAL_ENV/bin:$PATH" pip install awscli
  fi
  cd _output
  dpkg-source -x *.dsc src
  chown nobody -R .
  cd src
}

#  script:
function do_script() {

  if [[ $JOB_HOST_ARCH == 'all' ]]; then
    su -s /bin/sh -c "set -euE; dpkg-buildpackage -A" nobody
    return
  else
    if [[ $JOB_HOST_ARCH != $(dpkg --print-architecture) ]]; then
      export DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS:-} nocheck"
      export DEB_BUILD_PROFILES="${DEB_BUILD_PROFILES:-} cross"
    fi
    su -s /bin/sh -c "set -euE; dpkg-buildpackage -B -a $JOB_HOST_ARCH" nobody
  fi
}


function do_after_script() {
  export VIRTUAL_ENV=/opt/venv
  export PACKAGE_VERSION=$(cat _output/*.dsc | grep "^Version:" | cut -d' ' -f2)
  export PATH="$VIRTUAL_ENV/bin:$PATH"
  export OUTPUT_TAR_NAME="${CI_JOB_NAME//build/}-artifacts.tar"
  export OUTPUT_TAR_NAME="${OUTPUT_TAR_NAME// /}"
  if [[ ${UPLOAD_OUTPUT_TO_S3:-} && ${CI_COMMIT_REF_PROTECTED:-} ]]; then
    if [[ ${ROLE_ARN:-} && ${GITLAB_CACHES_BUCKET:-} ]]; then
      echo "Uploading artifacts to S3 Bucket..."
      set +x
      export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
        $(aws sts assume-role-with-web-identity \
        --role-arn ${ROLE_ARN} \
        --role-session-name "GitLabRunner-${CI_PROJECT_ID}-${CI_PIPELINE_ID}" \
        --web-identity-token $CI_JOB_JWT_V2 \
        --duration-seconds 3600 \
        --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
        --output text))
      aws sts get-caller-identity
      tar cf ${OUTPUT_TAR_NAME} _output/linux-image-*-dbg*.deb || echo "failed to compress output artifacts.."
      aws s3 cp ${OUTPUT_TAR_NAME} ${GITLAB_CACHES_BUCKET}/${CI_PROJECT_NAME}/${PACKAGE_VERSION// /_}/ || echo "failed to upload.."
      echo "done uploading.."
     else
      echo "Please set ROLE_ARN and GITLAB_CACHES_BUCKET variables in gitlab project"
    fi
  else
    echo "Not uploading artifacts to S3 (default)."
  fi
}


#   dependencies:
#   - source
#   artifacts:
#     paths:
#     - _output/*_${JOB_HOST_ARCH}.*
#     exclude:
#     - ${EXCLUDE_ARTIFACT}
#     expire_in: 2 days

# build all:
#   extends: .build
#   script:
#   variables:
#     JOB_HOST_ARCH: all
#   rules:
#   - if: '$BUILD_ARCH_ALL != ""'

# build amd64:
#   extends: .build
#   variables:
#     JOB_HOST_ARCH: amd64
#     JOB_HOST_GNU_TYPE_PACKAGE: x86-64-linux-gnu
#   tags:
#   - gardenlinux-build-amd64
#   rules:
#   - if: '$BUILD_ARCH_AMD64 != ""'

# build arm64:
#   extends: .build
#   variables:
#     JOB_HOST_ARCH: arm64
#     JOB_HOST_GNU_TYPE_PACKAGE: aarch64-linux-gnu
#   tags:
#   - gardenlinux-build-arm64
#   rules:
#   - if: '$BUILD_ARCH_ARM64 != ""'
