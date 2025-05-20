#!/bin/bash
ZONE_ID="Z05489693LFV4727Y7R4T"
#delete the dns records that are created
instances=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*latest" \
  --query "Reservations[*].Instances[*].{InstanceId:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" \
  --output text)
for instance in "${instances[@]}"
do
  echo "Deleting dns records for $instance"
  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":{"Name":"'$instance'.doubtfree.online","Type":"A"}}]}' \
    --output text
  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":{"Name":"'$instance-internal'.doubtfree.online","Type":"A"}}]}' \
    --output text
done
echo "Deleted Dns records for all instances"