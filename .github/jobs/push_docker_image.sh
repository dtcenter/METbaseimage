#! /bin/bash

source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

DOCKERHUB_TAG_BASE=${DOCKERHUB_BASE_REPO}:${GITHUB_NAME}
DOCKERHUB_TAG_UNIT_TEST=${DOCKERHUB_UNIT_TEST_REPO}:${GITHUB_NAME}
DOCKERHUB_TAG_METVIEWER=${DOCKERHUB_METVIEWER_REPO}:${GITHUB_NAME}

# skip docker push if credentials are not set
if [ -z ${DOCKER_USERNAME+x} ] || [ -z ${DOCKER_PASSWORD+x} ]; then
  echo "DockerHub credentials not set. Skipping docker push"
  exit 1
fi

echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin

# Push dtcenter/met-base
time_command docker push ${DOCKERHUB_TAG_BASE}
if [ $? != 0 ]; then
  exit 1
fi

# Push dtcenter/met-base-unit-test
time_command docker push ${DOCKERHUB_TAG_UNIT_TEST}
if [ $? != 0 ]; then
  exit 1
fi

# Push dtcenter/met-base-metviewer
time_command docker push ${DOCKERHUB_TAG_METVIEWER}
if [ $? != 0 ]; then
  exit 1
fi

