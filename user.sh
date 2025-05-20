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
# shellcheck disable=SC2164
dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "disabling default nodejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "enabling nodejs"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "installing nodejs"

cp user.service /etc/systemd/system/user.service
VALIDATE $? "copying service file"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
  VALIDATE $? "creating roboshop user"
else
  echo "user already exists"
fi

mkdir -p /app &>> $LOG_FILE
VALIDATE $? "creating app directory"


echo "Downloading user artifact..."
curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip
VALIDATE $? "Downloading user artifact"

echo "Creating and moving to /app directory..."
mkdir -p /app
cd /app
VALIDATE $? "Changing directory to /app"

echo "Unzipping user artifact..."
unzip -o /tmp/user.zip &>/dev/null
VALIDATE $? "Unzipping user artifact"

cd /app
VALIDATE $? "moving to app directory"

npm install &>> $LOG_FILE
VALIDATE $? "installing dependencies"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable $SCRIPT_NAME &>> $LOG_FILE
VALIDATE $? "enabling $SCRIPT_NAME service"

systemctl start $SCRIPT_NAME &>> $LOG_FILE
VALIDATE $? "starting $SCRIPT_NAME service"

echo "Script completed executing at $(date)" | tee -a $LOG_FILE

exit 0