#!/bin/bash

# List of instance names
instances=("frontend" "mongodb" "catalogue" "cart" "user" "shipping" "payment" "dispatch" "redis" "mysql" "rabbitmq")

# Replace with your actual values
PASSWORD="DevOps321"
USER="ec2-user"

git clone https://github.com/vadalibhavya/devops-shell-roboshop-instances.git
for instance in "${instances[@]}"
do
  echo "Processing $instance"

  sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$instance.doubtfree.online" 'bash -s' <<EOF
    git clone https://github.com/vadalibhavya/devops-shell-roboshop-instances.git
    cd /home/ec2-user/devops-shell-roboshop-instances
    bash $instance.sh
EOF

done

echo "All instances have been processed."
