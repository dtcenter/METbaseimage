#!/bin/bash

if [ "$(id -u)" -eq 0 ]; then
    # if running as root (e.g. Docker), modify uid/gid and run as metplus_user

    # if group ID is set and not 0 (root), adjust GID of metplus_user
    if [ -n "${GROUP_ID:-}" ] && [ "$GROUP_ID" != "0" ]; then
        echo "Adjusting user metplus_user to GID = $GROUP_ID"
        groupmod -g "$GROUP_ID" metplus_user
        usermod -g "$GROUP_ID" metplus_user
    fi

    # if user ID is set and not 0 (root), adjust UID of metplus_user
    if [ -n "${USER_ID:-}" ] && [ "$USER_ID" != "0" ]; then
        echo "Adjusting user metplus_user to UID = $USER_ID"
        usermod -u "$USER_ID" metplus_user
    fi

    # change ownership of home dir in case uid or gid of metplus_user were modified
    chown -R metplus_user:metplus_user /home/metplus_user

    # switch to metplus_user and execute command
    exec gosu metplus_user "$@"
else
    # if running as non-root (e.g Apptainer), then skip user/group mods and run
    echo "Running as non-root user ($(id -un)), skipping user/group modifications"

    # Execute command directly as the current user
    exec "$@"
fi
