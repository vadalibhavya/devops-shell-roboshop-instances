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
echo "disabling default nodejs"
dnf module disable -y nodejs &>> $LOG_FILE
VALIDATE $? "disabling default nodejs"

echo " enablining nodejs"
dnf module enable -y nodejs:20 -y  &>> $LOG_FILE
VALIDATE $? "enablining nodejs"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "installing nodejs"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "creating roboshop user"
else
  echo "user already exists"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -L -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOG_FILE
VALIDATE $? "downloading catalogue artifact"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>> $LOG_FILE
VALIDATE $? "unzipping catalogue artifact"

npm install &>> $LOG_FILE
VALIDATE $? "installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>> $LOG_FILE
VALIDATE $? "copying catalogue.service"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable catalogue &>> $LOG_FILE
VALIDATE $? "enabling catalogue"

systemctl start catalogue &>> $LOG_FILE
VALIDATE $? "starting catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE
VALIDATE $? "copying mongo.repo"

dnf install mongodb-mongosh -y &>> $LOG_FILE
VALIDATE $? "installing mongodb-mongosh"


STATUS=$(mongosh --host mongodb-internal.doubtfree.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -eq 0 ]; then
  echo "catalogue database exists"
  mongosh --host mongodb-internal.doubtfree.online </app/db/master-data.js &>> $LOG_FILE
else
  echo -e "Data is already loaded ... $Y SKIPPING"
  exit 1
fi