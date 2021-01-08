#!/bin/bash -ex

# this script first removes all cgifederal images from the local machine, and
# then does a general system prune. removing all cgifederal images is okay,
# because anything we intend to keep is pushed to the registry anyways

export DOCKER_CONTEXT=local

docker image ls --format='{{.Repository}}:{{.Tag}}' | grep -E 'cgifederal.com|^[[:alnum:]]{8,16}_config-svcs' | grep -v "<none>" | xargs -r docker image rm
docker system prune -f

# export DOCKER_CONTEXT=builder

# docker system prune -f
