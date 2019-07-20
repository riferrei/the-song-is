#!/bin/bash

###########################################
############ Redis Connector ##############
###########################################

CONNECTOR_NAME=$(curl -X GET ${kafka_connect_url}/connectors/myRedisSinkConnector | jq '.name')

if [ -n "$CONNECTOR_NAME" ]; then
   curl -X DELETE ${kafka_connect_url}/connectors/myRedisSinkConnector
fi

###########################################
############### Serverless ################
###########################################

cd ../../serverless
sls remove -f
