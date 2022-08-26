#! /bin/bash                                                                                                                                                    
source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

MET_BASE_IMAGE=minimum_${GITHUB_TAG}

DOCKERHUB_TAG_MIN=${DOCKERHUB_REPO}:${MET_BASE_IMAGE}

DOCKERFILE_PATH=${GITHUB_WORKSPACE}/Dockerfile

CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build.log

time_command docker build -t ${DOCKERHUB_TAG_MIN} \
    -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}
if [ $? != 0 ]; then
  cat ${GITHUB_WORKSPACE}/docker_build_base_image.log
  exit 1
fi

DOCKERHUB_TAG_TEST=${DOCKERHUB_REPO}:unit_test_${GITHUB_TAG}

DOCKERFILE_PATH=${GITHUB_WORKSPACE}/Dockerfile.unit_test_env

CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build.log

time_command docker build -t ${DOCKERHUB_TAG_TEST} \
    --build-arg MET_BASE_IMAGE \
    -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}
if [ $? != 0 ]; then
  cat ${GITHUB_WORKSPACE}/docker_build_unit_test_env.log
  exit 1
fi


