#!/bin/sh

set -e

if [ $(echo $1 | cut -c1) = - ]; then
  set -- ruby /gitlab_license.rb "$@"
fi

if [ $1 = gitlab-license ]; then
  set -- ruby /gitlab_license.rb "${@:1}"
fi

exec "$@"
