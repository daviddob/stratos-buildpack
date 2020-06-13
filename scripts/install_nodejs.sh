#!/bin/bash
set -euo pipefail

NODE_VERSION=$(yq r $BUILDPACK_DIR/manifest.yml 'dependencies.(name==node)'.version)
NODE_SHA=$(yq r $BUILDPACK_DIR/manifest.yml 'dependencies.(name==node)'.sha256)
NODE_URL=$(yq r $BUILDPACK_DIR/manifest.yml 'dependencies.(name==node)'.uri)

DOWNLOAD_FOLDER=${CACHE_DIR}/Downloads
mkdir -p ${DOWNLOAD_FOLDER}
DOWNLOAD_FILE=${DOWNLOAD_FOLDER}/node${NODE_VERSION}.tar.gz

export NodeInstallDir="${DEPS_DIR}/${INDEX}/node"
mkdir -p $NodeInstallDir

CACHED_DOWNLOAD_FILE=${BUILDPACK_DIR}/$(yq r $BUILDPACK_DIR/manifest.yml 'dependencies.(name==node)'.file)
if [ -f $CACHED_DOWNLOAD_FILE ]; then
  echo "-----> nodejs install package included in offline buildpack"
  DOWNLOAD_FILE=$CACHED_DOWNLOAD_FILE
else
  # Download the archive if we do not have it cached
  if [ ! -f ${DOWNLOAD_FILE} ]; then
    # Delete any cached node downloads, since those are now out of date
    rm -rf ${DOWNLOAD_FOLDER}/node*.tar.gz

    echo "-----> Download Nodejs ${NODE_VERSION}"
    curl -s -L --retry 15 --retry-delay 2 $NODE_URL -o ${DOWNLOAD_FILE}

    DOWNLOAD_SHA=$(sha256sum ${DOWNLOAD_FILE} | cut -d ' ' -f 1)
    if [[ $DOWNLOAD_SHA != $NODE_SHA ]]; then
      echo "       **ERROR** SHA mismatch: got $DOWNLOAD_SHA expected $NODE_SHA"
      exit 1
    fi
  else
    echo "-----> Nodejs install package available in cache"
  fi
fi

if [ ! -f $NodeInstallDir/bin/node ]; then
  tar xzf ${DOWNLOAD_FILE} -C $NodeInstallDir
fi

if [ ! -f $NodeInstallDir/bin/node ]; then
  echo "       **ERROR** Could not download nodejs"
  exit 1
fi

export NODE_HOME=$NodeInstallDir
