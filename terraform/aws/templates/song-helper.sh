#!/bin/bash

export BOOTSTRAP_SERVERS=${broker_list}
export ACCESS_KEY=${access_key}
export ACCESS_SECRET=${secret_key}
export DEVICE_ID=${device_id}

if [ "$1" != "" ]; then
  java -jar ../../song-helper/target/song-helper-spring-boot-1.0.jar --spotify.token=$1
else
  echo "You need to provide the Spotify token"
fi
