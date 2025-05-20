#!/bin/bash
instances=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "shipping" "payment" "dispatch" "mysql" "rabbitmq")


# create/update the dns records for the instances with public ip to be instance-internal/instance-public my domain is doubtfree.online
echo "creating private and public dns records if not available for instances, else updating the dns records"
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


echo "All instances created and dns records updated"