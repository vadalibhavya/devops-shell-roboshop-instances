#!/bin/bash
ZONE_ID="Z05489693LFV4727Y7R4T"

# Get running instances with tag:Name matching *latest
instances=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*latest" \
  --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='service']|[0].Value]" \
  --output text)

# Loop through each line: INSTANCE_ID and NAME_TAG
while read -r INSTANCE_ID NAME_TAG; do
  echo "Deleting DNS records for $NAME_TAG ($INSTANCE_ID)"

  # Get current public and private IPs (required to delete A records properly)
  PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

  PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)

  # Skip if no IPs are found
  if [[ -z "$PUBLIC_IP" || "$PUBLIC_IP" == "None" ]]; then
    echo "No public IP found for $NAME_TAG — skipping public record delete"
  else
    aws route53 change-resource-record-sets \
      --hosted-zone-id "$ZONE_ID" \
      --change-batch '{
        "Changes": [{
          "Action": "DELETE",
          "ResourceRecordSet": {
            "Name": "'$NAME_TAG'.doubtfree.online",
            "Type": "A",
            "TTL": 300,
            "ResourceRecords": [{"Value": "'$PUBLIC_IP'"}]
          }
        }]
      }'
    echo "Deleted public DNS record for $NAME_TAG"
  fi

  if [[ -z "$PRIVATE_IP" || "$PRIVATE_IP" == "None" ]]; then
    echo "No private IP found for $NAME_TAG — skipping internal record delete"
  else
    aws route53 change-resource-record-sets \
      --hosted-zone-id "$ZONE_ID" \
      --change-batch '{
        "Changes": [{
          "Action": "DELETE",
          "ResourceRecordSet": {
            "Name": "'$NAME_TAG'-internal.doubtfree.online",
            "Type": "A",
            "TTL": 300,
            "ResourceRecords": [{"Value": "'$PRIVATE_IP'"}]
          }
        }]
      }'
    echo "Deleted internal DNS record for $NAME_TAG"
  fi

done <<< "$instances"

echo "All DNS record deletions completed."
