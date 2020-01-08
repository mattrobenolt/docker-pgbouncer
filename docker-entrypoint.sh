#!/bin/sh
set -e

if [ "${1#-}" != "$1" ] ; then
    set -- pgbouncer "$@"
fi

if [ "$1" = 'pgbouncer' -a "$(id -u)" = '0' ]; then
    exec su-exec pgbouncer "$0" "$@"
fi

exec "$@"
