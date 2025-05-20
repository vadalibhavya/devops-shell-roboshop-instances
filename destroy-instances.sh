#!/bin/bash

echo "Destroying the instances and updating tag Name to 'old'"

instances=("frontend" "mongodb" "catalogue" "cart" "user" "shipping" "payment" "dispatch" "redis" "mysql" "rabbitmq")

for instance in "${instances[@]}"
do
  echo "Processing $instance"

  INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}-latest" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)

  if [[ "$INSTANCE_ID" == "None" || -z "$INSTANCE_ID" ]]; then
    echo "No instance found with tag Name=${instance}-latest. Skipping..."
    continue
  fi

  echo "Updating tag Name to '${instance}-old' for instance $INSTANCE_ID"
  aws ec2 create-tags --resources "$INSTANCE_ID" --tags "Key=Name,Value=${instance}-old"

  echo "Terminating instance $INSTANCE_ID"
  aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"

done

echo "Done destroying instances."
