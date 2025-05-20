#!/bin/bash
ZONE_ID="Z05489693LFV4727Y7R4T"
#fetch all the instances with tag name and ignore the instances with no tag name
instances=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*latest" \
  --query "Reservations[*].Instances[*].{InstanceId:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" \
  --output text)


for instance in $instances
do
  PUBLIC_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$instance" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)
  PRIVATE_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$instance" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)

  if [[ -n "$PUBLIC_IP" && "$PUBLIC_IP" != "None" ]]; then
    aws route53 change-resource-record-sets \
      --hosted-zone-id $ZONE_ID \
      --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$instance'.doubtfree.online","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'$PUBLIC_IP'"}]}}]}' \
      --output text
    echo "Public DNS record created/updated for $instance"
  else
    echo "Skipping public DNS update for $instance: No valid public IP"
  fi

  if [[ -n "$PRIVATE_IP" && "$PRIVATE_IP" != "None" ]]; then
    aws route53 change-resource-record-sets \
      --hosted-zone-id $ZONE_ID \
      --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$instance-internal'.doubtfree.online","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'$PRIVATE_IP'"}]}}]}' \
      --output text
    echo "Private DNS record ccreated/updated for $instance"
  else
    echo "Skipping private DNS update for $instance: No valid private IP"
  fi
done
