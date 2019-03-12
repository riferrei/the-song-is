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

  CREATE STREAM CURRENT_SONG_WRAPPER (NAME VARCHAR, AUTHOR VARCHAR) WITH (KAFKA_TOPIC='CURRENT_SONG', VALUE_FORMAT='JSON');
  CREATE STREAM CURRENT_SONG_STAGE_1 AS SELECT UCASE(NAME) AS SONG_KEY, NAME, AUTHOR FROM CURRENT_SONG_WRAPPER;
  CREATE STREAM CURRENT_SONG_STAGE_2 AS SELECT 'CURRENT_SONG' AS CURRENT_SONG, SONG_KEY, NAME, AUTHOR FROM CURRENT_SONG_STAGE_1 PARTITION BY CURRENT_SONG;
  CREATE TABLE SONG (CURRENT_SONG VARCHAR, SONG_KEY VARCHAR, NAME VARCHAR, AUTHOR VARCHAR) WITH (KAFKA_TOPIC='CURRENT_SONG_STAGE_2', VALUE_FORMAT='JSON', KEY='CURRENT_SONG');

  CREATE STREAM GUESSES_WRAPPER (GUESS VARCHAR, USER VARCHAR) WITH (KAFKA_TOPIC='GUESSES', VALUE_FORMAT='JSON');
  CREATE STREAM GUESSES_STAGE_1 AS SELECT UCASE(GUESS) AS SONG_KEY, GUESS, USER FROM GUESSES_WRAPPER;
  CREATE STREAM GUESSES_STAGE_2 AS SELECT SONG_KEY, GUESS, USER, 'CURRENT_SONG' AS CURRENT_SONG FROM GUESSES_STAGE_1;
  CREATE STREAM WINNERS AS SELECT TIMESTAMPTOSTRING(T.ROWTIME, 'yyyy-MM-dd hh:mm:ss') AS TIMESTAMP, T.USER FROM GUESSES_STAGE_2 T LEFT JOIN SONG S ON T.CURRENT_SONG = S.CURRENT_SONG WHERE T.SONG_KEY = S.SONG_KEY PARTITION BY TIMESTAMP;

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