#!/bin/bash

ZONE_ID="Z05489693LFV4727Y7R4T"

# Get a list of running instances with tag Name=*latest
instances=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*latest" \
  --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='service']|[0].Value]" \
  --output text)


# Loop through each line of instance details
while read -r INSTANCE_ID SERVICE_TAG; do
  echo "Processing $INSTANCE_ID ($SERVICE_TAG)"

  # Get public and private IPs
  PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

  PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)

  # Skip if public IP is empty or None
  if [[ -z "$PUBLIC_IP" || "$PUBLIC_IP" == "None" ]]; then
    echo "Skipping $SERVICE_TAG due to missing public IP"
    continue
  fi

  # Create/Update Route53 records
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch '{
      "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "'$SERVICE_TAG'.doubtfree.online",
          "Type": "A",
          "TTL": 5,
          "ResourceRecords": [{"Value": "'$PUBLIC_IP'"}]
        }
      }]
    }'

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch '{
      "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "'$SERVICE_TAG'-internal.doubtfree.online",
          "Type": "A",
          "TTL": 5,
          "ResourceRecords": [{"Value": "'$PRIVATE_IP'"}]
        }
      }]
    }'

  echo "DNS records created/updated for $SERVICE_TAG"

done <<< "$instances"

echo "All DNS updates completed."