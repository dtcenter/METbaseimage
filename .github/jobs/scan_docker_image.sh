#! /bin/bash

source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

# Scan the images
cve_scan_image ${DOCKERHUB_BASE_REPO}:${GITHUB_NAME}
cve_scan_image ${DOCKERHUB_UNIT_TEST_REPO}:${GITHUB_NAME}
cve_scan_image ${DOCKERHUB_METVIEWER_REPO}:${GITHUB_NAME}

