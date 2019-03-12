#!/bin/bash

########### Update and Install ###########

yum update -y
yum install wget -y
yum install unzip -y
sudo yum install gcc -y

########### Initial Bootstrap ###########

mkdir /etc/redis
cd /etc/redis
wget http://download.redis.io/redis-stable.tar.gz
tar -xvzf redis-stable.tar.gz
cd redis-stable
rm redis.conf

cat > /etc/redis/redis-stable/redis.conf <<- "EOF"
${redis_config}
EOF

make distclean
make

########### Creating the Service ############

cat > /lib/systemd/system/redis-server.service <<- "EOF"
[Unit]
Description=Redis Server
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=/etc/redis/redis-stable/src/redis-server /etc/redis/redis-stable/redis.conf

[Install]
WantedBy=multi-user.target
EOF

########### Enable and Start ###########

systemctl enable redis-server
systemctl start redis-server