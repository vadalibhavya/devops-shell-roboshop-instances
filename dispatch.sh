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

dnf install golang -y &>> $LOG_FILE
VALIDATE $? "installing golang"

cp dispatch.service /etc/systemd/system/dispatch.service &>> $LOG_FILE
VALIDATE $? "copying service file"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "creating roboshop user"
else
  echo "user already exists"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>> $LOG_FILE
VALIDATE $? "downloading dispatch artifact"

# shellcheck disable=SC2164
cd /app
unzip /tmp/dispatch.zip &>> "$LOG_FILE"
VALIDATE $? "unzipping dispatch artifact"

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