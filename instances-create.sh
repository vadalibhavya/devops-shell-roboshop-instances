#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
INSTANCE_TYPE="t2.micro"
SECURITY_GROUP_ID="sg-02e8b8d9dcc4131b2"
ZONE_ID="Z05489693LFV4727Y7R4T"

instances=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "shipping" "payment" "dispatch" "mysql" "rabbitmq")
#checking if aws cli is installed or not
if aws --version &> /dev/null; then
  echo "AWS CLI is installed"
else
  echo "AWS CLI is NOT installed"
  dnf install awscli -y
  echo "aws cli installed successfully"
fi

for instance in "${instances[@]}"; do
  echo "Creating $instance instance"

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}],Tags=[{Key=Name,Value=$instance-latest}]" \
    --query "Instances[0].InstanceId" \
    --output text)

  echo "Created instance with ID:: $INSTANCE_ID"
done
