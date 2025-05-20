#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
INSTANCE_TYPE="t2.micro"
SECURITY_GROUP_ID="sg-02e8b8d9dcc4131b2"
ZONE_ID="Z05489693LFV4727Y7R4T"

instances=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "shipping" "payment" "dispatch" "mysql" "rabbitmq")

# Check and install AWS CLI
if ! aws --version &> /dev/null; then
  echo "AWS CLI is NOT installed"
  dnf install awscli -y
else
  echo "AWS CLI is installed"
fi

# Check and install Git
if ! git --version &> /dev/null; then
  echo "Git is NOT installed"
  dnf install git -y
else
  echo "Git is installed"
fi

git clone https://github.com/roboshop-devops-projects/devops-shell-roboshop-instances.git

for instance in "${instances[@]}"; do
  echo "Creating $instance instance"

  # Create user data script for EC2 instance
  USER_DATA=$(base64 <<EOF
#!/bin/bash
dnf install git -y
git clone https://github.com/roboshop-devops-projects/devops-shell-roboshop-instances.git
cd devops-shell-roboshop-instances
bash $instance.sh
EOF
)

  # Launch EC2 with user data
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance-latest},{Key=service,Value=$instance}]" \
    --user-data "$USER_DATA" \
    --query "Instances[0].InstanceId" \
    --output text)

  echo "Created instance with ID: $INSTANCE_ID"
done
