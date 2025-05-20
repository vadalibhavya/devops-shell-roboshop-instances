# EC2 Multi-Instance Deployment Script

This repository contains a Bash script to automate the deployment of multiple AWS EC2 instances using the AWS CLI. 
It is designed to set up instances for a microservices-based application stack, including services like frontend, backend components, databases, and message queues.

The script performs the following actions:

1. Installs the AWS CLI (via `dnf` package manager).
2. Iterates through a list of microservices.
3. Launches an EC2 instance for each service with a specified AMI, instance type, and security group.
4. Tags each instance with a unique name matching the service.

The following instances will be created:

- frontend  
- mongodb  
- catalogue  
- redis  
- user  
- cart  
- shipping  
- payment  
- dispatch  
- mysql  
- rabbitmq  

## Prerequisites

- An AWS account with necessary permissions to create EC2 instances.
- A valid **AMI ID**, **Security Group ID**, and **Zone ID**.
- AWS CLI installed and configured with credentials (`aws configure`).
- The script is intended for Amazon Linux or any OS with `dnf`.

## Variables to Update
Make sure to update these variables in the script with your own values:
AMI_ID="ami-xxxxxxxxxxxxxxxxx"
INSTANCE_TYPE="t2.micro"
SECURITY_GROUP_ID="sg-xxxxxxxxxxxxxxxxx"
ZONE_ID="Zxxxxxxxxxxxxxxxxxxx"
