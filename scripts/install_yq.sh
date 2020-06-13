#!/bin/bash
set -euo pipefail

DOWNLOAD_FOLDER=${CACHE_DIR}/Downloads
mkdir -p ${DOWNLOAD_FOLDER}
DOWNLOAD_FILE=${DOWNLOAD_FOLDER}/yq_linux_amd64

export YQInstallDir="${DEPS_DIR}/${INDEX}/yq"
mkdir -p $YQInstallDir

CACHED_DOWNLOAD_FILE=$BUILDPACK_DIR/dependencies/*/yq_linux_amd64
if [ -f $CACHED_DOWNLOAD_FILE ]; then
  echo "-----> yq install package included in offline buildpack"
  DOWNLOAD_FILE=$CACHED_DOWNLOAD_FILE
else
  # Download the archive if we do not have it cached
  if [ ! -f ${DOWNLOAD_FILE} ]; then
    # Delete any cached yq downloads, since those are now out of date
    rm -rf ${DOWNLOAD_FOLDER}/yq*

    YQ_SHA="9a2914efa6a0de753e7361485378366b3893d7494b69beab31b3bd39e797fa2c"
    URL=https://github.com/mikefarah/yq/releases/download/3.3.1/yq_linux_amd64
    echo "-----> Download yq"
    curl -s -L --retry 15 --retry-delay 2 $URL -o ${DOWNLOAD_FILE}

    DOWNLOAD_SHA=$(sha256sum ${DOWNLOAD_FILE} | cut -d ' ' -f 1)
    if [[ $DOWNLOAD_SHA != $YQ_SHA ]]; then
      echo "       **ERROR** SHA mismatch: got $DOWNLOAD_SHA expected $YQ_SHA"
      exit 1
    fi
  else
    echo "-----> yq install package available in cache"
  fi
fi

if [ ! -f $YQInstallDir/yq ]; then
  cp ${DOWNLOAD_FILE} $YQInstallDir/yq
  chmod +x $YQInstallDir/yq
fi

if [ ! -f $YQInstallDir/yq ]; then
  echo "       **ERROR** Could not download yq"
  exit 1
fi
