#!/bin/bash

PASSWORD="DevOps321"
USER="ec2-user"
DOMAIN="doubtfree.online"

services=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

for service in "${services[@]}"; do
  echo "Connecting to $service"

  sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$service.$DOMAIN" 'bash -s' <<EOF
cd /home/ec2-user
if [ ! -d "devops-shell-roboshop-instances" ]; then
  git clone https://github.com/vadalibhavya/devops-shell-roboshop-instances.git
fi
cd devops-shell-roboshop-instances
git pull
chmod +x $service.sh
sudo bash $service.sh
EOF

done
