#!/bin/bash

########### Update and Install ###########

yum update -y
yum install wget -y
yum install unzip -y
yum install java-1.8.0-openjdk-devel.x86_64 -y
yum install git -y
yum install maven -y

########### Initial Bootstrap ###########

cd /tmp
wget ${confluent_platform_location}
unzip confluent-5.1.0-2.11.zip
mkdir /etc/confluent
mv confluent-5.1.0 /etc/confluent
mkdir ${confluent_home_value}/etc/kafka-connect

############ Jaeger Tracing #############

cd /tmp
git clone https://github.com/riferrei/jaeger-tracing-support.git
cd jaeger-tracing-support
mvn clean
mvn compile
mvn install
cd target
cp jaeger-tracing-support-1.0.jar ${confluent_home_value}/share/java/monitoring-interceptors

cd /tmp
curl -O https://riferrei.net/wp-content/uploads/2019/03/dependencies.zip
unzip dependencies.zip
cp *.jar ${confluent_home_value}/share/java/monitoring-interceptors
cp kafka-run-class kafka-rest-run-class ksql-run-class ${confluent_home_value}/bin

cd /tmp
wget ${jaeger_tracing_location}
tar -xvzf jaeger-1.10.0-linux-amd64.tar.gz
mkdir /etc/jaeger
mv jaeger-1.10.0-linux-amd64 /etc/jaeger

cat > /etc/jaeger/jaeger-1.10.0-linux-amd64/jaeger-agent.yaml <<- "EOF"
reporter:
  type: tchannel
  tchannel:
    host-port: ${jaeger_collector}
EOF

########### Generating Props File ###########

cd ${confluent_home_value}/etc/kafka-connect

cat > kafka-connect-ccloud.properties <<- "EOF"
${kafka_connect_properties}
EOF

cat > interceptorsConfig.json <<- "EOF"
{
   "services":[
      {
         "service":"Kafka Connect",
         "config":{
            "sampler":{
               "type" : "const",
               "param" : 1
            },
            "reporter":{
               "logSpans":true
            }
         },
         "topics":[
            "TWEETS", "GUESSES", "CURRENT_SONG", "WINNERS",
            "CURRENT_SONG_WRAPPER", "GUESSES_WRAPPER",
            "CURRENT_SONG_STAGE_1", "CURRENT_SONG_STAGE_2",
            "SONG", "GUESSES_STAGE_1", "GUESSES_STAGE_2",
            "GUESSES_STAGE_3", "GUESSES_STAGE_4", "GUESSES_STAGE_5"
         ]
      }
   ]
}
EOF

######## Twitter & Redis Connectors #########

${confluent_home_value}/bin/confluent-hub install jcustenborder/kafka-connect-twitter:0.2.32 --component-dir ${confluent_home_value}/share/java --no-prompt
${confluent_home_value}/bin/confluent-hub install jcustenborder/kafka-connect-redis:0.0.2.7 --component-dir ${confluent_home_value}/share/java --no-prompt

########### Creating the Service ############

cat > /lib/systemd/system/jaeger-agent.service <<- "EOF"
[Unit]
Description=Jaeger Agent
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=/etc/jaeger/jaeger-1.10.0-linux-amd64/jaeger-agent --config-file=/etc/jaeger/jaeger-1.10.0-linux-amd64/jaeger-agent.yaml

[Install]
WantedBy=multi-user.target
EOF

cat > /lib/systemd/system/kafka-connect.service <<- "EOF"
[Unit]
Description=Kafka Connect

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=${confluent_home_value}/bin/connect-distributed ${confluent_home_value}/etc/kafka-connect/kafka-connect-ccloud.properties

[Install]
WantedBy=multi-user.target
EOF

########### Enable and Start ###########

systemctl enable jaeger-agent
systemctl start jaeger-agent

systemctl enable kafka-connect
systemctl start kafka-connect
