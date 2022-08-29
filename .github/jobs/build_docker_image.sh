#! /bin/bash                                                                                                                                                    
source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

MET_BASE_IMAGE=${GITHUB_TAG}

DOCKERHUB_TAG_BASE=${DOCKERHUB_BASE_REPO}:${MET_BASE_IMAGE}

DOCKERFILE_PATH=${GITHUB_WORKSPACE}/Dockerfile

CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build_base_image.log

time_command docker build -t ${DOCKERHUB_TAG_BASE} \
    -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}
if [ $? != 0 ]; then
  cat ${GITHUB_WORKSPACE}/docker_build_base_image.log
  exit 1
fi

MET_BASE_UNIT_TEST_IMAGE=${GITHUB_TAG}

DOCKERHUB_TAG_UNIT_TEST=${DOCKERHUB_UNIT_TEST_REPO}:${GITHUB_TAG}

DOCKERFILE_PATH=${GITHUB_WORKSPACE}/Dockerfile.unit_test_env

CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build_unit_test_env.log

time_command docker build -t ${DOCKERHUB_TAG_UNIT_TEST} \
    --build-arg MET_BASE_UNIT_TEST_IMAGE=${MET_BASE_UNIT_TEST_IMAGE} \
    -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}
if [ $? != 0 ]; then
  cat ${GITHUB_WORKSPACE}/docker_build_unit_test_env.log
  exit 1
fi


