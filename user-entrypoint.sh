#!/bin/bash

# If USER_ID and GROUP_ID are provided, modify the metplus_user accordingly
if [ -n "${USER_ID:-}" ] && [ -n "${GROUP_ID:-}" ]; then
      # Special case: if both USER_ID and GROUP_ID are 0, run as root
    if [ "$USER_ID" = "0" ] && [ "$GROUP_ID" = "0" ]; then
        echo "Running as root (UID:GID = 0:0)"
        exec "$@"
    else
        echo "Adjusting user metplus_user to UID:GID = $USER_ID:$GROUP_ID"

        # Modify group first
        groupmod -g "$GROUP_ID" metplus_user 2>/dev/null || \
            groupadd -g "$GROUP_ID" metplus_user 2>/dev/null

        # Modify user
        usermod -u "$USER_ID" -g "$GROUP_ID" metplus_user 2>/dev/null

        # Fix ownership of directories that metplus_user needs to write to
        chown -R metplus_user:metplus_user /home/metplus_user 2>/dev/null

        # Switch to metplus_user and execute the command
        exec gosu metplus_user "$@"
    fi
else
    # No USER_ID/GROUP_ID provided, use default metplus_user
    exec gosu metplus_user "$@"
fi
