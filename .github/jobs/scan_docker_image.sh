#! /bin/bash

source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

# Scan the images
ret1 = cve_scan_image ${DOCKERHUB_BASE_REPO}:${GITHUB_NAME}
ret2 = cve_scan_image ${DOCKERHUB_UNIT_TEST_REPO}:${GITHUB_NAME}
ret3 = cve_scan_image ${DOCKERHUB_METVIEWER_REPO}:${GITHUB_NAME}

# Check for bad return status
if [[ $ret1 -ne 0 || $ret2 -ne 0 || $ret3 -ne0 ]]; then
  echo "ERROR: Critical CVEs found!"
  exit 1
fi
