#!/bin/bash

###########################################
############ Redis Connector ##############
###########################################

CONNECTOR_NAME=$(curl -X GET http://the-song-is-kafka-connect-1129402609.us-east-1.elb.amazonaws.com/connectors/myRedisSinkConnector | jq '.name')

if [ -n "$CONNECTOR_NAME" ]; then
   curl -X DELETE http://the-song-is-kafka-connect-1129402609.us-east-1.elb.amazonaws.com/connectors/myRedisSinkConnector
fi

###########################################
############### Serverless ################
###########################################

cd ../../alexa-skills
./undeploy.sh
