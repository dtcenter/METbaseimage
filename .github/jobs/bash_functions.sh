#! /bin/bash

# utility function to run command get log the time it took to run
# if CMD_LOGFILE is set, send output to that file and unset var
# ::group:: and ::endgroup:: create collapsible log groups on GitHub Actions
function time_command {
  local start_seconds=$SECONDS
  echo "::group::RUNNING: $*"

  local error
  # pipe output to log file if set
  if [ "x$CMD_LOGFILE" == "x" ]; then
      "$@"
      error=$?
  else
      echo "Logging to ${CMD_LOGFILE}"
      "$@" >> $CMD_LOGFILE 2>&1
      error=$?
      unset CMD_LOGFILE
  fi

  local duration=$(( SECONDS - start_seconds ))
  echo "TIMING: Command took `printf '%02d' $(($duration / 60))`:`printf '%02d' $(($duration % 60))` (MM:SS): '$*'"
  echo "::endgroup::"
  if [ ${error} -ne 0 ]; then
    echo "ERROR: '$*' exited with status = ${error}"
  fi
  return $error
}

# utilty function to scan a Docker image for vulnerabilities
function cve_scan_image {
  echo "Scanning image $1"
  CMD_LOGFILE="${GITHUB_WORKSPACE}/CVE_Scan_`echo $1 | sed 's%[/,:]%_%g'`.log"
  time_command grype $1
  CMD_LOGFILE="${GITHUB_WORKSPACE}/CVE_Scan_`echo $1 | sed 's%[/,:]%_%g'`.log"

  # print CVE counts
  echo "Found $(grep -E " Critical | High | Medium | Low | Negligible " $CMD_LOGFILE | wc -l) CVEs for image $1"
  grep -E -o " Critical | High | Medium | Low | Negligible " $CMD_LOGFILE | sort | uniq -c

  # return bad status for non-zero Criticals
  N_CRITICAL=`grep " Critical " ${CMD_LOGFILE} | wc -l`
  if [ ${N_CRITICAL} -gt 0 ]; then
    echo "WARNING: Found ${N_CRITICAL} Critical CVEs for image $1 in ${CMD_LOGFILE}"
    echo
    egrep "SEVERITY|Critical" ${CMD_LOGFILE}
    echo
    return 1
  fi

  return 0
}
