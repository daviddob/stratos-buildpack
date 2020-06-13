#!/bin/bash
set -euo pipefail

GO_VERSION=$(yq r $BUILDPACK_DIR/manifest.yml 'dependencies.(name==go)'.version)
GO_SHA=$(yq r $BUILDPACK_DIR/manifest.yml 'dependencies.(name==go)'.sha256)
GO_URL=$(yq r $BUILDPACK_DIR/manifest.yml 'dependencies.(name==go)'.uri)

DOWNLOAD_FOLDER=${CACHE_DIR}/Downloads
mkdir -p ${DOWNLOAD_FOLDER}
DOWNLOAD_FILE=${DOWNLOAD_FOLDER}/go${GO_VERSION}.tar.gz

export GoInstallDir="${DEPS_DIR}/${INDEX}/go"
mkdir -p $GoInstallDir

CACHED_DOWNLOAD_FILE=${BUILDPACK_DIR}/$(yq r $BUILDPACK_DIR/manifest.yml 'dependencies.(name==go)'.file)
if [ -f $CACHED_DOWNLOAD_FILE ]; then
  echo "-----> go install package included in offline buildpack"
  DOWNLOAD_FILE=$CACHED_DOWNLOAD_FILE
else
  # Download the archive if we do not have it cached
  if [ ! -f ${DOWNLOAD_FILE} ]; then
    # Delete any cached go downloads, since those are now out of date
    rm -rf ${DOWNLOAD_FOLDER}/go*.tar.gz

    echo "-----> Download go ${GO_VERSION}"
    curl -s -L --retry 15 --retry-delay 2 $GO_URL -o ${DOWNLOAD_FILE}

    DOWNLOAD_SHA=$(sha256sum ${DOWNLOAD_FILE} | cut -d ' ' -f 1)
    if [[ $DOWNLOAD_SHA != $GO_SHA ]]; then
      echo "       **ERROR** SHA mismatch: got $DOWNLOAD_SHA expected $GO_SHA"
      exit 1
    fi
  else
    echo "-----> go install package available in cache"
  fi
fi

if [ ! -f $GoInstallDir/bin/go ]; then
  tar xzf ${DOWNLOAD_FILE} -C $GoInstallDir
fi

if [ ! -f $GoInstallDir/bin/go ]; then
  echo "       **ERROR** Could not download go"
  exit 1
fi
