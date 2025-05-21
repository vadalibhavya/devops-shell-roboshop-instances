#!/bin/bash

ZONE_ID="Z05489693LFV4727Y7R4T"
services=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

for service in "${services[@]}"; do
  for suffix in "" "-internal"; do
    RECORD_NAME="${service}${suffix}.doubtfree.online."

    echo "Checking and deleting: $RECORD_NAME"

    # Get the current record set
    RECORD_SET=$(aws route53 list-resource-record-sets \
      --hosted-zone-id "$ZONE_ID" \
      --query "ResourceRecordSets[?Name == '${RECORD_NAME}']" \
      --output json)

    if [[ "$RECORD_SET" != "[]" ]]; then
      echo "Deleting DNS record: $RECORD_NAME"

      aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "{
          \"Changes\": [
            {
              \"Action\": \"DELETE\",
              \"ResourceRecordSet\": ${RECORD_SET}
            }
          ]
        }"
    else
      echo "Record $RECORD_NAME not found or already deleted."
    fi
  done
done
