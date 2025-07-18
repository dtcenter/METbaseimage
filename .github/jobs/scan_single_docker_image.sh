#! /bin/bash

source ${GITHUB_WORKSPACE}/.github/jobs/bash_functions.sh

if ! cve_scan_image $1; then
  echo "WARNING: Critical CVEs found!"
fi
