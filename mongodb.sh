#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

USERID=$(id -u)
R="\033[31m"
G="\033[32m"
B="\033[34m"
Y="\033[33m"
M="\033[35m"
C="\033[36m"
N="\033[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

echo "Script started executing at $(date)" | tee -a "$LOG_FILE"

if [ "$USERID" -ne 0 ]; then
    echo -e "${R}You are not root user. Please run the script as root.${N}" | tee -a "$LOG_FILE"
    exit 1
else
    echo -e "${G}You are root user${N}" | tee -a "$LOG_FILE"
fi

mkdir -p "$LOGS_FOLDER"

function VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "${R}$2 - Failure${N}" | tee -a "$LOG_FILE"
        exit 1
    else
        echo -e "${G}$2 - Success${N}" | tee -a "$LOG_FILE"
    fi
}

# Copy mongo repo config
cp mongo.repo /etc/yum.repos.d/mongo.repo &>> "$LOG_FILE"
VALIDATE $? "Copying mongo.repo"

# Install mongodb-org package
dnf install mongodb-org -y &>> "$LOG_FILE"
VALIDATE $? "Installing mongodb-org"

# Enable and start mongod service
systemctl enable mongod &>> "$LOG_FILE"
VALIDATE $? "Enabling mongod service"

systemctl start mongod &>> "$LOG_FILE"
VALIDATE $? "Starting mongod service"

# Configure mongodb to listen on all interfaces (replace bindIp)
sed -i -e 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
VALIDATE $? "Configuring mongod bindIp"

# Restart mongod to apply config changes
systemctl restart mongod &>> "$LOG_FILE"
VALIDATE $? "Restarting mongod service"

echo -e "${G}MongoDB installation and configuration completed successfully.${N}" | tee -a "$LOG_FILE"
