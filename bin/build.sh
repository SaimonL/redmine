#!/bin/bash

echo '' > log/airbrake.log
echo '' > log/development.log
echo '' > log/test.log

version=$(cat version.txt)
version=$(echo "${version}" | awk '{gsub(/^ +| +$/,"")} {print $0}')

podman build --platform linux/amd64 -t "$DOCKER_REGISTRY"/rails/redmine:"$version" .
podman push "$DOCKER_REGISTRY"/rails/redmine:"$version"

echo
echo "Current Version: $version"
echo "Image: $DOCKER_REGISTRY/rails/redmine:$version"
echo
