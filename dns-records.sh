#!/bin/bash
ZONE_ID="Z05489693LFV4727Y7R4T"
#fetch all the instances with tag name and ignore the instances with no tag name
instances=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=*" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].InstanceId" --output text)
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
  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$instance'.doubtfree.online","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'$PUBLIC_IP'"}]}}]}' \
    --output text
  echo "Public DNS record created/updated for $instance"
  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$instance-internal'.doubtfree.online","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'$PRIVATE_IP'"}]}}]}' \
    --output text
  echo "Private DNS record created/updated for $instance"
done
echo "DNS records created/updated successfully"
