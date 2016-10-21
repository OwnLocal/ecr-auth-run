#!/bin/sh

$(aws ecr get-login)
/usr/bin/docker run "$@"
