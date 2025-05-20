#!/bin/bash
ZONE_ID="Z05489693LFV4727Y7R4T"
instances=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "shipping" "payment" "dispatch" "mysql" "rabbitmq")
# create/update the dns records for the instances with public ip to be instance-internal/instance-public my domain is doubtfree.online
echo "creating private and public dns records if not available for instances, else updating the dns records"

for instance in "${instances[@]}"
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
    --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$instance'-private.doubtfree.online","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'$PRIVATE_IP'"}]}}]}' \
    --output text
  echo "Private DNS record created/updated for $instance"
done
echo "All instances created and dns records updated"