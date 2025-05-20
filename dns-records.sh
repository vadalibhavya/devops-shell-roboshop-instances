#!/bin/bash
ZONE_ID="Z05489693LFV4727Y7R4T"
#fetch all the instances with tag name and ignore the instances with no tag name
instances=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*latest" \
  --query "Reservations[*].Instances[*].{InstanceId:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" \
  --output text)

for instance in "${instances[@]}"
do
  echo "Processing $instance"
  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$instance'.doubtfree.online","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'$PUBLIC_IP'"}]}}]}' \
    --output text
  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$instance-internal'.doubtfree.online","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'$PRIVATE_IP'"}]}}]}' \
    --output text
done