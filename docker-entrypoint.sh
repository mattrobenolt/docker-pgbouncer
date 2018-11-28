#!/bin/sh
set -e

if [ "${1#-}" != "$1" ] ; then
    set -- pgbouncer "$@"
fi

if [ "$1" = 'pgbouncer' -a "$(id -u)" = '0' ]; then
    mkdir -p $PGBOUNCER_RUNDIR
    chown pgbouncer:pgbouncer -R $PGBOUNCER_RUNDIR
    chmod 755 $PGBOUNCER_RUNDIR
    exec su-exec pgbouncer "$0" "$@"
fi

exec "$@"
