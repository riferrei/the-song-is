#!/bin/bash

###########################################
########### Twitter Connector #############
###########################################

CONNECTOR_NAME=$(curl -X GET ${kafka_connect_url}/connectors/myTwitterSourceConnector | jq '.name')

if [ -n "$CONNECTOR_NAME" ]; then
   curl -X DELETE ${kafka_connect_url}/connectors/myTwitterSourceConnector
fi

curl -s -X POST -H 'Content-Type: application/json' --data @twitterConnector.json ${kafka_connect_url}/connectors

###########################################
############## KSQL Streams ###############
###########################################

ksql ${ksql_server_url} <<EOF

  CREATE STREAM CURRENT_IDENTITY_STAGE_1 (ID BIGINT, TEXT VARCHAR, USER STRUCT<NAME VARCHAR>) WITH (KAFKA_TOPIC='TWEET_STREAM', VALUE_FORMAT='AVRO');

  CREATE STREAM CURRENT_IDENTITY_STAGE_2 AS SELECT UCASE(TRIM(SUBSTRING(TEXT, 16, LEN(TEXT)))) AS HERO_NAME, TRIM(USER->NAME) AS CURRENT_IDENTITY FROM CURRENT_IDENTITY_STAGE_1 PARTITION BY HERO_NAME;

  CREATE STREAM CURRENT_IDENTITY_OUTPUT AS SELECT CURRENT_IDENTITY FROM CURRENT_IDENTITY_STAGE_2 WITH (KEY='HERO_NAME');
  
EOF

###########################################
############ Redis Connector ##############
###########################################

CONNECTOR_NAME=$(curl -X GET ${kafka_connect_url}/connectors/myRedisSinkConnector | jq '.name')

if [ -n "$CONNECTOR_NAME" ]; then
   curl -X DELETE ${kafka_connect_url}/connectors/myRedisSinkConnector
fi

curl -s -X POST -H 'Content-Type: application/json' --data @redisConnector.json ${kafka_connect_url}/connectors

###########################################
############### Serverless ################
###########################################

#mvn clean -f "../../serverless/pom.xml"
#mvn compile -f "../../serverless/pom.xml"
#mvn install -f "../../serverless/pom.xml"

#cd ../../serverless
#sls deploy -v