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
mkdir -p $LOGS_FOLDER

echo "Script started executing at $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo -e "${R}You are not root user${N}"
  #switching to root
  sudo -i
  exit 1
else
  echo -e "${G}You are root user${N}"
fi


VALIDATE() {
  if [ $1 -eq 0 ]; then
    echo -e " $2 is ... ${G}SUCCESS${N}" | tee -a $LOG_FILE
  else
    echo -e " $2 is ... ${R}FAILURE${N}" | tee -a $LOG_FILE
    exit 1
  fi
}

dnf install python3 gcc python3-devel  -y &>> $LOG_FILE
VALIDATE $? "installing python3"

cp payment.service /etc/systemd/system/payment.service &>> $LOG_FILE
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

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip
VALIDATE $? "downloading payment artifact"

# shellcheck disable=SC2164
cd /app

unzip -o /tmp/payment.zip &>> $LOG_FILE
VALIDATE $? "unzipping payment artifact"

# shellcheck disable=SC2164
cd /app

pip3 install -r requirements.txt &>> $LOG_FILE
VALIDATE $? "installing dependencies"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable payment &>> $LOG_FILE
VALIDATE $? "enabling payment service"

systemctl restart payment &>> $LOG_FILE
VALIDATE $? "restarting payment service"

echo "Script completed executing at $(date)" | tee -a $LOG_FILE
