#!/bin/bash

yum update -y
amazon-linux-extras install redis4.0 -y

cat > /home/ec2-user/deleteKeys.sh <<- "EOF"
#!/bin/bash
redis-cli -h ${redis_host} -p ${redis_port} FLUSHALL
EOF

chmod 775 /home/ec2-user/deleteKeys.sh
chown ec2-user:ec2-user /home/ec2-user/deleteKeys.sh
