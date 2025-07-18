#! /bin/bash

source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

# Scan the images
cve_scan_image ${DOCKERHUB_BASE_REPO}:${GITHUB_NAME}
retval1=$?
cve_scan_image ${DOCKERHUB_UNIT_TEST_REPO}:${GITHUB_NAME}
retval2=$?
cve_scan_image ${DOCKERHUB_METVIEWER_REPO}:${GITHUB_NAME}
retval3=$?

# Check for bad return status
if [[ $retval1 -ne 0 || $retval2 -ne 0 || $retval3 -ne 0 ]]; then
  echo "ERROR: Critical CVEs found!"
  exit 1
fi
