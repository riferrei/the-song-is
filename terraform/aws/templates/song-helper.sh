#!/bin/bash

export BOOTSTRAP_SERVERS=${broker_list}
export ACCESS_KEY=${access_key}
export ACCESS_SECRET=${secret_key}

export CLIENT_ID=${client_id}
export CLIENT_SECRET=${client_secret}
export DEVICE_NAME='${device_name}'

if [ "$1" != "" ] && [ "$2" != "" ]; then
  java -jar ../../song-helper/target/song-helper-spring-boot-1.0.jar --spotify.access.token=$1 --spotify.refresh.token=$2
else
  echo "You need to provide the access token and refresh token as parameters!"
fi
