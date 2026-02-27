#!/bin/bash
set -e

# If running as root (e.g. to fix permissions), step down to dashboard user
if [ "$(id -u)" = "0" ]; then
    # Update dashboard user's UID/GID if PUID/PGID are set
    PUID="${PUID:-998}"
    PGID="${PGID:-998}"

    if [ "$(id -u dashboard)" != "$PUID" ]; then
        usermod -u "$PUID" dashboard 2>/dev/null || true
    fi
    if [ "$(id -g dashboard)" != "$PGID" ]; then
        groupmod -g "$PGID" dashboard 2>/dev/null || true
    fi

    chown -R dashboard:dashboard /app
    exec gosu dashboard "$@"
fi

exec "$@"
