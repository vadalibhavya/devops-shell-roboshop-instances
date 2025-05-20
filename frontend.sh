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

echo "Disabling default nginx"
dnf module disable -y nginx
VALIDATE $? "Disabling default nginx"

dnf module enable -y nginx:1.24 &>> $LOG_FILE
VALIDATE $? "enabling nginx"


echo "Installing nginx"
dnf install nginx -y
VALIDATE $? "Installing nginx"

echo " enabling nginx"
systemctl enable nginx
systemctl start nginx
VALIDATE $? "enabling and starting nginx"

rm -rf /usr/share/nginx/html/* &>> $LOG_FILE
VALIDATE $? "removing default content"

echo "Downloading frontend content"
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend.zip &>> $LOG_FILE
VALIDATE $? "Downloading frontend content"

echo "Extracting frontend content"
cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>> $LOG_FILE
VALIDATE $? "Extracting frontend content"

echo "Configuring frontend"
rm -rf /etc/nginx/nginx.conf &>> $LOG_FILE
# over write the existing nginx.conf
cp -o nginx.conf /etc/nginx/nginx.conf &>> $LOG_FILE
VALIDATE $? "Configuring frontend"

echo "Restarting nginx"
systemctl restart nginx
VALIDATE $? "Restarting nginx"
