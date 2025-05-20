#!/bin/bash
ZONE_ID="Z05489693LFV4727Y7R4T"

# Fetch instance IDs with their Name tags (space-separated)
instances=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=*" \
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name']|[0].Value]" --output text)

while read -r INSTANCE_ID NAME_TAG; do
  echo "Processing $NAME_TAG ($INSTANCE_ID)"

  # Get public and private IP by instance ID
  PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
  PRIVATE_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)

  # Only update if public IP is valid
  if [[ "$PUBLIC_IP" != "None" && -n "$PUBLIC_IP" ]]; then
    aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'"$NAME_TAG"'.doubtfree.online","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'"$PUBLIC_IP"'"}]}}]}' --output text
    echo "Public DNS record created/updated for $NAME_TAG"
  else
    echo "No valid public IP for $NAME_TAG, skipping public DNS update"
  fi

  # Only update if private IP is valid
  if [[ "$PRIVATE_IP" != "None" && -n "$PRIVATE_IP" ]]; then
    aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'"$NAME_TAG"'-internal.doubtfree.online","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'"$PRIVATE_IP"'"}]}}]}' --output text
    echo "Private DNS record created/updated for $NAME_TAG"
  else
    echo "No valid private IP for $NAME_TAG, skipping private DNS update"
  fi

done <<< "$instances"

echo "DNS records created/updated successfully"
