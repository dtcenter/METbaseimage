#! /bin/bash

source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

DOCKERHUB_TAG_MIN=${DOCKERHUB_REPO}:minimum_${GITHUB_TAG}
DOCKERHUB_TAG_TEST=${DOCKERHUB_REPO}:unit_test_${GITHUB_TAG}


# skip docker push if credentials are not set
if [ -z ${DOCKER_USERNAME+x} ] || [ -z ${DOCKER_PASSWORD+x} ]; then
    echo "DockerHub credentials not set. Skipping docker push"
    exit 1
fi

echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin

time_command docker push ${DOCKERHUB_TAG_MIN}
if [ $? != 0 ]; then
  exit 1
fi
time_command docker push ${DOCKERHUB_TAG_TEST}
