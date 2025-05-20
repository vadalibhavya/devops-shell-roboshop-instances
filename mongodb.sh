#!/bin/bash

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
SCRIPT_DIR=$PWD

echo "Script started executing at $(date)" | tee -a "$LOG_FILE"

if [ "$USERID" -ne 0 ]; then
    echo -e "${R}You are not root user. Please run the script as root.${N}"
    exit 1
else
    echo -e "${G}You are root user${N}"
fi

mkdir -p "$LOGS_FOLDER"

VALIDATE() {
  if [ "$1" -eq 0 ]; then
    echo -e " $2 is ... ${G}SUCCESS${N}" | tee -a "$LOG_FILE"
  else
    echo -e " $2 is ... ${R}FAILURE${N}" | tee -a "$LOG_FILE"
    exit 1
  fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> "$LOG_FILE"
VALIDATE $? "copying mongo.repo"

dnf install mongodb-org -y &>> "$LOG_FILE"
VALIDATE $? "installing mongodb"

systemctl enable mongod &>> "$LOG_FILE"
systemctl start mongod &>> "$LOG_FILE"
VALIDATE $? "starting mongodb"

sed -i -e 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf &>> "$LOG_FILE"
VALIDATE $? "configuring mongodb"

systemctl restart mongod &>> "$LOG_FILE"
VALIDATE $? "restarting mongodb"
