# ownlocal/ecr-auth-run

Authenticates with ECR by running `aws ecr get-login` and then calls `docker run` with any arguments
passed into the run. This is useful when you want to run a docker container hosted in ECR in a
situation where there's no easy way to first authenticate.

One example use-case is launching an ECR container via cloud-config in RancherOS:

```
#cloud-config
ssh_authorized_keys:
  - ssh-rsa SSH-KEY-HERE
rancher:
  services:
    my_container:
      image: ownlocal/ecr-auth-run
      command: [12345.dkr.ecr.us-east-1.amazonaws.com/my_container:latest, --log-driver=awslogs, --log-opt, awslogs-region=us-east-1, --log-opt, awslogs-group=MyLogGroup]
      environment:
        AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
        AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        AWS_DEFAULT_REGION: us-east-1
      privileged: true
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
        - /usr/bin/docker:/usr/bin/docker
```

If you have assigned an IAM Role to the instance which has the permissions needed to access the ECR
repo, you can even leave out the access key and secret, but the region will still need to be
specified. Of course, a different log driver can be used, if desired.

Any environment variables or other arguments to your container will need to be included in the
`command` portion of the config, as the service config is for the initial container.

Both of the specified bind mounts (in the "volumes" section) are required for this container to
function properly. If the `docker` executable is somewhere else on the Docker host, you will need to
adjust the /usr/bin/docker mount accordingly.

Running this from the command-line would look something like this:
```
$ docker run --rm -it -e AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
    -e AWS_DEFAULT_REGION=us-east-1 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /usr/bin/docker:/usr/bin/docker \
    ownlocal/ecr-auth-run \
    --log-driver=awslogs --log-opt awslogs-region=us-east-1 --log-opt awslogs-group=MyLogGroup \
    12345.dkr.ecr.us-east-1.amazonaws.com/my-container
```

Note that any `docker run` arguments need to come before the name of the image and any container
arguments need to come after the name of the image. Also in order for the awslogs driver to work
this needs to either be run on an EC2 instance with an IAM role which allows CloudWatch logging or
the docker daemon needs to have been run with the appropriate AWS_ACCESS_KEY_ID and
AWS_SECRET_ACCESS_KEY environment variables set (see https://github.com/docker/docker/issues/16551).
