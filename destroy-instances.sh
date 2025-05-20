#!/bin/bash

echo "Destroying the instances"

instances=("frontend" "mongodb" "catalogue" "cart" "user" "shipping" "payment" "dispatch" "redis" "mysql" "rabbitmq")

for instance in "${instances[@]}"
do
  echo "Destroying $instance"
  INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$instance" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)
  echo "Destroying $INSTANCE_ID"
  aws ec2 terminate-instances \
    --instance-ids "$INSTANCE_ID"
done