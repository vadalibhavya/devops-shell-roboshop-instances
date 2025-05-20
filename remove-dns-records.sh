#!/bin/bash
ZONE_ID="Z05489693LFV4727Y7R4T"
instances=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "shipping" "payment" "dispatch" "mysql" "rabbitmq")

echo "Deleting dns public and private records for instances"

for instance in "${instances[@]}"
do
  echo "Deleting dns records for $instance"
  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":{"Name":"'$instance'.doubtfree.online","Type":"A"}}]}' \
    --output text
  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":{"Name":"'$instance'-private.doubtfree.online","Type":"A"}}]}' \
    --output text
done

echo "Deleted dns public and private records for instances"
