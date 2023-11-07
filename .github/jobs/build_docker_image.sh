#! /bin/bash                                                                                                                                                    

source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

# Required environment variables:
#   $GITHUB_WORKSPACE is the full path to METbaseimage.
#   $GITHUB_TAG is the tag name (e.g. vX.Y).
#   $DOCKERHUB_BASE_REPO is dtcenter/met-base.
#   $DOCKERHUB_UNIT_TEST_REPO is dtcenter/met-base-unit-test.

MET_BASE_TAG=${GITHUB_TAG}

DOCKERHUB_TAG_BASE=${DOCKERHUB_BASE_REPO}:${MET_BASE_TAG}

DOCKERFILE_PATH=${GITHUB_WORKSPACE}/Dockerfile

CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build_base_image.log

time_command docker build -t ${DOCKERHUB_TAG_BASE} \
    -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}
if [ $? != 0 ]; then
  cat ${GITHUB_WORKSPACE}/docker_build_base_image.log
  exit 1
fi

DOCKERHUB_TAG_UNIT_TEST=${DOCKERHUB_UNIT_TEST_REPO}:${GITHUB_TAG}

DOCKERFILE_PATH=${GITHUB_WORKSPACE}/Dockerfile.unit_test_env

CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build_unit_test_env.log

time_command docker build -t ${DOCKERHUB_TAG_UNIT_TEST} \
    --build-arg MET_BASE_TAG=${MET_BASE_TAG} \
    -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}
if [ $? != 0 ]; then
  cat ${GITHUB_WORKSPACE}/docker_build_unit_test_env.log
  exit 1
fi


