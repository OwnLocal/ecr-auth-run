#!/bin/sh

$(aws ecr get-login)
docker run "$@"
