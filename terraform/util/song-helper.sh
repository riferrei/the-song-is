#!/bin/bash

########### Update and Install ###########

yum update -y
yum install wget -y
yum install unzip -y
yum install java-1.8.0-openjdk-devel.x86_64 -y
yum install git -y
yum install maven -y

######## Song Helper Application #########

cd /tmp
git clone https://github.com/riferrei/the-song-is.git
cd the-song-is/song-helper
mvn package
cd target
mkdir /etc/song-helper
cp song-helper-1.0.jar /etc/song-helper

cat > /etc/song-helper/start.sh <<- "EOF"
#!/bin/bash

export BOOTSTRAP_SERVERS=${broker_list}
export ACCESS_KEY=${access_key}
export ACCESS_SECRET=${secret_key}

export CLIENT_ID=${client_id}
export CLIENT_SECRET=${client_secret}
export ACCESS_TOKEN=${access_token}
export REFRESH_TOKEN=${refresh_token}
export DEVICE_NAME='${device_name}'

java -jar /etc/song-helper/song-helper-1.0.jar
EOF

chmod 775 /etc/song-helper/start.sh

########### Creating the Service ############

cat > /lib/systemd/system/song-helper.service <<- "EOF"
[Unit]
Description=Song Helper Application
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=/etc/song-helper/start.sh

[Install]
WantedBy=multi-user.target
EOF

########### Enable and Start ###########

systemctl enable song-helper
systemctl start song-helper