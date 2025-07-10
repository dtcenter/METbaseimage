#! /bin/bash

source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

DOCKERHUB_TAG_BASE=${DOCKERHUB_BASE_REPO}:${GITHUB_NAME}
DOCKERHUB_TAG_UNIT_TEST=${DOCKERHUB_UNIT_TEST_REPO}:${GITHUB_NAME}
DOCKERHUB_TAG_METVIEWER=${DOCKERHUB_METVIEWER_REPO}:${GITHUB_NAME}

function scan_image {
  echo "Scanning image $1"
  LOG_FILE="${GITHUB_WORKSPACE}/logs/CVE_Scan_`echo $1 | sed 's%/%_%g'`.log"
  time_command "grype ${DOCKERHUB_TAG_BASE} > ${LOG_FILE} 2>&1"
  N_CRITICAL=`grep "Critical" ${LOG_FILE} | wc -l`
  if [ $N_CRITICAL > 0 ]; then
    echo "WARNING: Found ${N_CRITICAL} CVEs for image $1 in ${LOG_FILE}:"
    echo
    egrep "SEVERITY|Critical" ${LOG_FILE}
    echo
  fi
}

# Scan the images
scan_image ${DOCKERHUB_TAG_BASE}
scan_image ${DOCKERHUB_TAG_UNIT_TEST}
scan_image ${DOCKERHUB_TAG_METVIEWER}

