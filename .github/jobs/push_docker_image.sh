#! /bin/bash

source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

# assumes METPLUS_COMPONENT is set to either met or metviewer

DOCKERHUB_TAG_BASE=$(get_dockerhub_tag ${DOCKERHUB_BASE_REPO} ${GITHUB_NAME})
DOCKERHUB_TAG_UNIT_TEST=$(get_dockerhub_tag ${DOCKERHUB_UNIT_TEST_REPO} ${GITHUB_NAME})
DOCKERHUB_TAG_METVIEWER=$(get_dockerhub_tag ${DOCKERHUB_METVIEWER_REPO} ${GITHUB_NAME})

# Skip docker push if credentials are not set
if [ -z ${DOCKER_USERNAME+x} ] || [ -z ${DOCKER_PASSWORD+x} ]; then
  echo "DockerHub credentials not set. Skipping docker push"
  exit 1
fi

if [ "$METPLUS_COMPONENT" != "met" ] && [ "$METPLUS_COMPONENT" != "metviewer" ]; then
  echo "ERROR: Invalid value set for METPLUS_COMPONENT: ${METPLUS_COMPONENT}"
  exit 1
fi

echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin

if [ "$METPLUS_COMPONENT" == "met" ]; then
  # Push dtcenter/met-base
  time_command_exit docker push ${DOCKERHUB_TAG_BASE}

  # Push dtcenter/met-base-unit-test
  time_command_exit docker push ${DOCKERHUB_TAG_UNIT_TEST}
fi

if [ "$METPLUS_COMPONENT" == "metviewer" ]; then
  # Push dtcenter/met-base-metviewer
  time_command_exit docker push ${DOCKERHUB_TAG_METVIEWER}
fi

# For the release-docker-images.yml workflow, push X.Y-latest for vX.Y.Z versions
if [[ "${UPDATE_LATEST}" == "true" && "${GITHUB_NAME}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  LATEST_TAG=$(echo ${GITHUB_NAME} | sed 's/^v//g' | cut -f1,2 -d'.')-latest

  if [ "$METPLUS_COMPONENT" == "met" ]; then
    time_command_exit docker tag ${DOCKERHUB_TAG_BASE} ${DOCKERHUB_BASE_REPO}:${LATEST_TAG}
    time_command_exit docker push ${DOCKERHUB_BASE_REPO}:${LATEST_TAG}

    time_command_exit docker tag ${DOCKERHUB_TAG_UNIT_TEST} ${DOCKERHUB_UNIT_TEST_REPO}:${LATEST_TAG}
    time_command_exit docker push ${DOCKERHUB_UNIT_TEST_REPO}:${LATEST_TAG}
  fi

  if [ "$METPLUS_COMPONENT" == "metviewer" ]; then
    time_command_exit docker tag ${DOCKERHUB_TAG_METVIEWER} ${DOCKERHUB_METVIEWER_REPO}:${LATEST_TAG}
    time_command_exit docker push ${DOCKERHUB_METVIEWER_REPO}:${LATEST_TAG}
  fi
fi
