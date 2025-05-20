#!/bin/bash

ZONE_ID="Z05489693LFV4727Y7R4T"
services=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

for service in "${services[@]}"; do
  echo "Deleting DNS records for $service and $service-internal"

  # Fetch current public IP(s) for $service.doubtfree.online
  PUBLIC_IPS=$(aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" \
    --query "ResourceRecordSets[?Name == '${service}.doubtfree.online.'].[ResourceRecords[].Value]" --output text)

  # Delete public DNS record if exists
  if [[ -n "$PUBLIC_IPS" ]]; then
    for ip in $PUBLIC_IPS; do
      echo "Deleting public DNS record: $service -> $ip"
      aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "$(cat <<EOF
{
  "Changes": [{
    "Action": "DELETE",
    "ResourceRecordSet": {
      "Name": "${service}.doubtfree.online",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "${ip}"}]
    }
  }]
}
EOF
)"
    done
  else
    echo "No public DNS record found for $service"
  fi

  # Fetch current private/internal IP(s) for $service-internal.doubtfree.online
  INTERNAL_IPS=$(aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" \
    --query "ResourceRecordSets[?Name == '${service}-internal.doubtfree.online.'].[ResourceRecords[].Value]" --output text)

  # Delete internal DNS record if exists
  if [[ -n "$INTERNAL_IPS" ]]; then
    for ip in $INTERNAL_IPS; do
      echo "Deleting internal DNS record: $service-internal -> $ip"
      aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "$(cat <<EOF
{
  "Changes": [{
    "Action": "DELETE",
    "ResourceRecordSet": {
      "Name": "${service}-internal.doubtfree.online",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "${ip}"}]
    }
  }]
}
EOF
)"
    done
  else
    echo "No internal DNS record found for $service-internal"
  fi
done

echo "Done deleting DNS records."
