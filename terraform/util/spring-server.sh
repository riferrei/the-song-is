#!/bin/bash

########### Update and Install ###########

yum update -y
yum install wget -y
yum install unzip -y
yum install java-1.8.0-openjdk-devel.x86_64 -y
yum install git -y
yum install maven -y

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

systemctl enable spring-server
systemctl start spring-server