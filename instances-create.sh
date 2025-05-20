#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
INSTANCE_TYPE="t2.micro"
SECURITY_GROUP_ID="sg-02e8b8d9dcc4131b2"
ZONE_ID="Z05489693LFV4727Y7R4T"

instances=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "shipping" "payment" "dispatch" "mysql" "rabbitmq")

# shellcheck disable=SC2068
for instance in ${instances[@]}; do
  echo "Creating $instance instance"
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --security-group-ids $SECURITY_GROUP_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId")
  echo "Created $INSTANCE_ID"
done

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
