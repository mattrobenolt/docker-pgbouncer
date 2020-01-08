#!/bin/bash
set -eu

aliases='1 1.12 latest'
tag='mattrobenolt/pgbouncer'

fullVersion=$(awk '$1 == "ENV" && $2 == "PGBOUNCER_VERSION" { print $3; exit }' Dockerfile)

docker build --pull --rm -t $tag:$fullVersion .
docker push $tag:$fullVersion

for alias in $aliases; do
    docker tag $tag:$fullVersion $tag:$alias
    docker push $tag:$alias
done
