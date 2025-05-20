#!/bin/bash

PASSWORD="DevOps321"
USER="ec2-user"
DOMAIN="doubtfree.online"

services=("frontend" "mongodb" "catalogue" "cart" "user" "shipping" "payment" "dispatch" "redis" "mysql" "rabbitmq")

for service in "${services[@]}"; do
  echo "Connecting to $service"

  sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$service.$DOMAIN" 'bash -s' <<EOF
cd /home/ec2-user
if [ ! -d "devops-shell-roboshop-instances" ]; then
  git clone https://github.com/roboshop-devops-projects/devops-shell-roboshop-instances.git
fi
cd devops-shell-roboshop-instances
bash $service.sh
EOF

done
