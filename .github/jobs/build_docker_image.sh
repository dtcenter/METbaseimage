#! /bin/bash

source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

# Required environment variables:
#   $GITHUB_WORKSPACE is the full path to METbaseimage.
#   $GITHUB_NAME is the tag or branch name (e.g. vX.Y or develop).
#   $DOCKERHUB_BASE_REPO is dtcenter/met-base(-dev).
#   $DOCKERHUB_UNIT_TEST_REPO is dtcenter/met-base-unit-test(-dev).
#   $DOCKERHUB_METVIEWER_REPO is dtcenter/met-base-metviewer(-dev).
#   $DEBIAN_REGISTRY is debian Docker registry name -- IronBank or docker.io
#   $DEBIAN_IMAGE is debian Docker image name -- IronBank or DockerHub
#   $METPLUS_COMPONENT is component to build -- either met or metviewer

if [ "$METPLUS_COMPONENT" == "met" ]; then
    # remove leading 'v' from version tag
    MET_BASE_TAG=$(echo ${GITHUB_NAME} | sed 's%/%_%g' | sed 's%^v%%g' )

    # Build dtcenter/met-base
    DOCKERHUB_TAG_BASE=$(get_dockerhub_tag ${DOCKERHUB_BASE_REPO} ${GITHUB_NAME})
    DOCKERFILE_PATH=${GITHUB_WORKSPACE}/${GITHUB_NAME}/Dockerfile
    CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build_met_base_image.log

    if ! time_command docker build -t ${DOCKERHUB_TAG_BASE} \
             --build-arg BASE_REGISTRY=${DEBIAN_REGISTRY} \
             --build-arg BASE_IMAGE=${DEBIAN_IMAGE} \
             -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}; then
      echo "::group::${GITHUB_WORKSPACE}/docker_build_met_base_image.log"
      cat ${GITHUB_WORKSPACE}/docker_build_met_base_image.log
      echo "::endgroup::"
      exit 1
    fi

    # Build dtcenter/met-base-unit-test
    DOCKERHUB_TAG_UNIT_TEST=$(get_dockerhub_tag ${DOCKERHUB_UNIT_TEST_REPO} ${GITHUB_NAME})
    DOCKERFILE_PATH=${GITHUB_WORKSPACE}/${GITHUB_NAME}/Dockerfile.unit_test_env
    CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build_met_base_unit_test_env_image.log

    if ! time_command docker build -t ${DOCKERHUB_TAG_UNIT_TEST} \
         --build-arg MET_BASE_REPO=${DOCKERHUB_BASE_REPO} \
         --build-arg MET_BASE_TAG=${MET_BASE_TAG} \
         -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}; then
      echo "::group::${GITHUB_WORKSPACE}/docker_build_met_unit_test_env_image.log"
      cat ${GITHUB_WORKSPACE}/docker_build_met_base_unit_test_env_image.log
      echo "::endgroup::"
      exit 1
    fi
    # end of MET and MET unit test section
    exit 0
fi

# exit if METplus component is not set to either met or metviewer
if [ "$METPLUS_COMPONENT" != "metviewer" ]; then
    echo "ERROR: METPLUS_COMPONENT must be set to either met or metviewer: ${METPLUS_COMPONENT}"
    exit 1
fi

# Build dtcenter/met-base-metviewer
DOCKERHUB_TAG_METVIEWER=$(get_dockerhub_tag ${DOCKERHUB_METVIEWER_REPO} ${GITHUB_NAME})
DOCKERFILE_PATH=${GITHUB_WORKSPACE}/${GITHUB_NAME}/Dockerfile.metviewer
CMD_LOGFILE=${GITHUB_WORKSPACE}/docker_build_met_base_metviewer_image.log

if ! time_command docker build -t ${DOCKERHUB_TAG_METVIEWER} \
         --build-arg BASE_REGISTRY=${DEBIAN_REGISTRY} \
         --build-arg BASE_IMAGE=${DEBIAN_IMAGE} \
         -f $DOCKERFILE_PATH ${GITHUB_WORKSPACE}; then
  echo "::group::${GITHUB_WORKSPACE}/docker_build_met_base_metviewer_image.log"
  cat ${GITHUB_WORKSPACE}/docker_build_met_base_metviewer_image.log
  echo "::endgroup::"
  exit 1
fi
