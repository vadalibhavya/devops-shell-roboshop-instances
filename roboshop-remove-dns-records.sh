#!/bin/bash

ZONE_ID="Z05489693LFV4727Y7R4T"
services=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

for service in "${services[@]}"; do
  for suffix in "" "-internal"; do
    RECORD_NAME="${service}${suffix}.doubtfree.online."

    echo "Checking and deleting: $RECORD_NAME"

    # Get the current record set (only first match)
    RECORD_JSON=$(aws route53 list-resource-record-sets \
      --hosted-zone-id "$ZONE_ID" \
      --query "ResourceRecordSets[?Name == '${RECORD_NAME}'] | [0]" \
      --output json)

    # Skip if empty
    if [[ "$RECORD_JSON" == "null" ]]; then
      echo "Record $RECORD_NAME not found or already deleted."
      continue
    fi

    echo "Deleting DNS record: $RECORD_NAME"

    aws route53 change-resource-record-sets \
      --hosted-zone-id "$ZONE_ID" \
      --change-batch "{
        \"Changes\": [
          {
            \"Action\": \"DELETE\",
            \"ResourceRecordSet\": $RECORD_JSON
          }
        ]
      }"
  done
done
