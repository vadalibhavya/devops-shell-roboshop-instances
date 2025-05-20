#!/bin/bash
USERID=$(id -u)
R="/e[31m"
G="/e[32m"
B="/e[34m"
Y="/e[33m"
M="/e[35m"
C="/e[36m"
N="/e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
  echo -e "${R}You are not root user${N}"
  exit 1
else
  echo -e "${G}You are root user${N}"
fi

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE
VALIDATE $? "copying mongo.repo"

dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "installing mongodb"

systemctl enable mongod &>> $LOG_FILE
systemctl start mongod &>> $LOG_FILE
VALIDATE $? "starting mongodb"
sed -i -e 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf &>> $LOG_FILE
VALIDATE $? "configuring mongodb"

systemctl restart mongod &>> $LOG_FILE
VALIDATE $? "restarting mongodb"
