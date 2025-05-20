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

dnf install golang -y
VALIDATE $? "installing golang"



id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
  VALIDATE $? "creating roboshop user"
else
  echo "user already exists"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip
VALIDATE $? "downloading dispatch artifact"

# shellcheck disable=SC2164
cd /app
unzip -o /tmp/dispatch.zip
VALIDATE $? "unzipping dispatch artifact"

# shellcheck disable=SC2164
cd /app

go mod init dispatch &>> $LOG_FILE
VALIDATE $? "initializing go module"

go get &>> $LOG_FILE
VALIDATE $? "downloading dependencies"

go build &>> $LOG_FILE
VALIDATE $? "building go application"

cp dispatch.service /etc/systemd/system/dispatch.service &>> $LOG_FILE
VALIDATE $? "copying service file"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable dispatch &>> $LOG_FILE
VALIDATE $? "enabling dispatch"

systemctl start dispatch &>> $LOG_FILE
VALIDATE $? "starting dispatch"

echo "Script completed executing at $(date)" | tee -a $LOG_FILE