#! /bin/bash

# utility function to run command get log the time it took to run
# if CMD_LOGFILE is set, send output to that file and unset var
# ::group:: and ::endgroup:: create collapsible log groups on GitHub Actions
function time_command {
  local start_seconds=$SECONDS
  echo "::group::RUNNING: $*"

  local retval
  # pipe output to log file if set
  if [ "x$CMD_LOGFILE" == "x" ]; then
    "$@"
    retval=$?
  else
    echo "Logging to ${CMD_LOGFILE}"
    "$@" >> $CMD_LOGFILE 2>&1
    retval=$?
    unset CMD_LOGFILE
  fi

  local duration=$(( SECONDS - start_seconds ))
  echo "TIMING: Command took `printf '%02d' $(($duration / 60))`:`printf '%02d' $(($duration % 60))` (MM:SS): '$*'"
  echo "::endgroup::"
  if [ $retval -ne 0 ]; then
    echo "ERROR: '$*' exited with status = ${retval}"
  fi
  return $retval
}

# run command and exit on bad status
function time_command_exit {
  time_command $@
  retval=$?
  if [ $retval -ne 0 ]; then
    exit $retval
  fi
  return $retval
}

# utility function to construct the DockerHub tag name to be used,
# replacing slashes with underscores in the branch name, and
# omitting the leading 'v' from the DockerHub version

function get_dockerhub_tag {
  echo ${1}:$(echo ${2} | sed 's%/%_%g' | sed 's%^v%%g' )
}
