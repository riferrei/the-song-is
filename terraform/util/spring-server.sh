#!/bin/bash

########### Update and Install ###########

yum update -y
yum install wget -y
yum install unzip -y
yum install java-1.8.0-openjdk-devel.x86_64 -y
yum install git -y
yum install maven -y

############ Jaeger Tracing #############

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

######## SpringBoot Application ########

cd /tmp
git clone https://github.com/riferrei/the-song-is.git
cd the-song-is/spring-boot
mvn clean
mvn compile
mvn install
cd target
mkdir /etc/the-song-is
cp the-song-is-spring-boot-1.0.jar /etc/the-song-is

cat > /etc/the-song-is/interceptorsConfig.json <<- "EOF"
{
   "services":[
      {
         "service":"Spring Consumer",
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
            "TWEETS"
         ]
      },
      {
         "service":"Spring Producer",
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
            "GUESSES"
         ]
      }
   ]
}
EOF

cat > /etc/the-song-is/start.sh <<- "EOF"
#!/bin/bash

export BOOTSTRAP_SERVERS=${broker_list}
export ACCESS_KEY=${access_key}
export ACCESS_SECRET=${secret_key}
export SCHEMA_REGISTRY_URL=${schema_registry_url}

java -jar /etc/the-song-is/the-song-is-spring-boot-1.0.jar
EOF

chmod 775 /etc/the-song-is/start.sh

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

cat > /lib/systemd/system/spring-server.service <<- "EOF"
[Unit]
Description=SpringBoot Application
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=/etc/the-song-is/start.sh

[Install]
WantedBy=multi-user.target
EOF

########### Enable and Start ###########

systemctl enable jaeger-agent
systemctl start jaeger-agent

systemctl enable spring-server
systemctl start spring-server