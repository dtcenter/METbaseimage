#! /bin/bash

source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

# Required environment variables:
#   $GITHUB_WORKSPACE is the full path to METbaseimage.
#   $GITHUB_TAG is the tag name (e.g. vX.Y).
#   $DOCKERHUB_BASE_REPO is dtcenter/met-base.
#   $DOCKERHUB_UNIT_TEST_REPO is dtcenter/met-base-unit-test.
#   $DOCKERHUB_METVIEWER_REPO is dtcenter/met-base-metviewer.

MET_BASE_TAG=${GITHUB_TAG}

# Build dtcenter/met-base
DOCKERHUB_TAG_BASE=${DOCKERHUB_BASE_REPO}:${MET_BASE_TAG}
DOCKERFILE_PATH=${GITHUB_WORKSPACE}/Dockerfile
CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build_met_base_image.log

time_command docker build -t ${DOCKERHUB_TAG_BASE} \
    -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}
if [ $? != 0 ]; then
  cat ${GITHUB_WORKSPACE}/docker_build_met_base_image.log
  exit 1
fi

# Build dtcenter/met-base-unit-test
DOCKERHUB_TAG_UNIT_TEST=${DOCKERHUB_UNIT_TEST_REPO}:${GITHUB_TAG}
DOCKERFILE_PATH=${GITHUB_WORKSPACE}/Dockerfile.unit_test_env
CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build_met_base_unit_test_env_image.log

time_command docker build -t ${DOCKERHUB_TAG_UNIT_TEST} \
    --build-arg MET_BASE_TAG=${MET_BASE_TAG} \
    -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}
if [ $? != 0 ]; then
  cat ${GITHUB_WORKSPACE}/docker_build_met_base_unit_test_env_image.log
  exit 1
fi

# Build dtcenter/met-base-metviewer
DOCKERHUB_TAG_METVIEWER=${DOCKERHUB_METVIEWER_REPO}:${GITHUB_TAG}
DOCKERFILE_PATH=${GITHUB_WORKSPACE}/Dockerfile.metviewer
CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build_met_base_metviewer_image.log

time_command docker build -t ${DOCKERHUB_TAG_METVIEWER} \
    --build-arg MET_BASE_TAG=${MET_BASE_TAG} \
    -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}
if [ $? != 0 ]; then
  cat ${GITHUB_WORKSPACE}/docker_build_met_base_metviewer_image.log
  exit 1
fi

