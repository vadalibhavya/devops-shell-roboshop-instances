#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
M="\e[35m"
C="\e[36m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD


echo "Script started executing at $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo -e "${R}You are not root user${N}"
  #switching to root
  sudo -i
    exit 1
else
  echo -e "${G}You are root user${N}"
fi
mkdir -p $LOGS_FOLDER

VALIDATE() {
  if [ $1 -eq 0 ]; then
    echo -e " $2 is ... ${G}SUCCESS${N}" | tee -a $LOG_FILE
  else
    echo -e " $2 is ... ${R}FAILURE${N}" | tee -a $LOG_FILE
    exit 1
  fi
}

dnf module disaable nodejs -y &>> $LOG_FILE
VALIDATE $? "disabling default nodejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "enabling nodejs"

cp $SCRIPT_DIR/$SCRIPT_NAME.service /etc/systemd/system/$SCRIPT_NAME.service &>> $LOG_FILE
VALIDATE $? "copying service file"
dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "installing nodejs"

useradd roboshop &>> $LOG_FILE
VALIDATE $? "creating roboshop user"

mkdir -p /app &>> $LOG_FILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/$SCRIPT_NAME.zip https://roboshop-artifacts.s3.amazonaws.com/$SCRIPT_NAME-v3.zip &>> $LOG_FILE
VALIDATE $? "downloading $SCRIPT_NAME artifact"

cd /app &>> $LOG_FILE
VALIDATE $? "moving to app directory"

unzip /tmp/$SCRIPT_NAME.zip &>> $LOG_FILE
VALIDATE $? "unzipping $SCRIPT_NAME artifact"

npm install &>> $LOG_FILE
VALIDATE $? "installing dependencies"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable $SCRIPT_NAME &>> $LOG_FILE
VALIDATE $? "enabling $SCRIPT_NAME"

systemctl start $SCRIPT_NAME &>> $LOG_FILE
VALIDATE $? "starting $SCRIPT_NAME"

