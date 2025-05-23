#!/bin/bash

IMAGE=registry.metabarcoding.org/phyloskims/annot
#IMAGE=phyloskims/annotate
TAG=latest

singularity -h >/dev/null  2>&1 && DOCKER="singularity --silent exec --bind .:/data docker://"
docker -h  >/dev/null 2>&1 && DOCKER="docker run --rm --volume .:/data "

if [[ -z "$DOCKER" ]] ; then 
    echo "Cannot found neither singularity or docker on your system"
    exit 1 
fi

eval "${DOCKER}${IMAGE}:${TAG} organnot $*" 
