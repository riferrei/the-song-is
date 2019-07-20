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
unzip confluent-5.3.0-2.12.zip
mkdir /etc/confluent
mv confluent-5.3.0 /etc/confluent
mkdir ${confluent_home_value}/data

############ Jaeger Tracing #############

cd /tmp
git clone https://github.com/riferrei/kafka-tracing-support.git
cd kafka-tracing-support
mvn package
cd target
cp kafka-tracing-support-1.0.jar ${confluent_home_value}/share/java/monitoring-interceptors

cd /tmp
curl -O https://riferrei.net/wp-content/uploads/2019/06/dependencies.zip
unzip dependencies.zip
cp *.jar ${confluent_home_value}/share/java/monitoring-interceptors
cp kafka-run-class kafka-rest-run-class ksql-run-class ${confluent_home_value}/bin

cd /tmp
wget ${jaeger_tracing_location}
tar -xvzf jaeger-1.13.0-linux-amd64.tar.gz
mkdir /etc/jaeger
mv jaeger-1.13.0-linux-amd64 /etc/jaeger

cat > /etc/jaeger/jaeger-1.13.0-linux-amd64/jaeger-agent.yaml <<- "EOF"
reporter:
  type: tchannel
  tchannel:
    host-port: ${jaeger_collector}
EOF

########### Generating Props File ###########

cat > ${confluent_home_value}/etc/ksql/ksql-server-ccloud.properties <<- "EOF"
${ksql_server_properties}
EOF

############ Custom Start Script ############

cat > ${confluent_home_value}/bin/startKSQL.sh <<- "EOF"
#!/bin/bash

export JAEGER_SERVICE_NAME='KSQL Server'
export JAEGER_SAMPLER_TYPE=const
export JAEGER_SAMPLER_PARAM=1
export JAEGER_REPORTER_LOG_SPANS=true

${confluent_home_value}/bin/ksql-server-start ${confluent_home_value}/etc/ksql/ksql-server-ccloud.properties

EOF

chmod 775 ${confluent_home_value}/bin/startKSQL.sh

########### Creating the Service ############

cat > /lib/systemd/system/jaeger-agent.service <<- "EOF"
[Unit]
Description=Jaeger Agent
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=/etc/jaeger/jaeger-1.13.0-linux-amd64/jaeger-agent --config-file=/etc/jaeger/jaeger-1.13.0-linux-amd64/jaeger-agent.yaml

[Install]
WantedBy=multi-user.target
EOF

cat > /lib/systemd/system/ksql-server.service <<- "EOF"
[Unit]
Description=Confluent KSQL Server
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=${confluent_home_value}/bin/startKSQL.sh
ExecStop=${confluent_home_value}/bin/ksql-server-stop ${confluent_home_value}/etc/ksql/ksql-server-ccloud.properties

[Install]
WantedBy=multi-user.target
EOF

########### Enable and Start ###########

systemctl enable jaeger-agent
systemctl start jaeger-agent

systemctl enable ksql-server
systemctl start ksql-server
