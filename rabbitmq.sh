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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> $LOG_FILE
VALIDATE $? "copying rabbitmq.repo"

dnf install rabbitmq-server -y &>> $LOG_FILE
VALIDATE $? "installing rabbitmq-server"

systemctl enable rabbitmq-server &>> $LOG_FILE
VALIDATE $? "enabling rabbitmq-server"

systemctl start rabbitmq-server &>> $LOG_FILE
VALIDATE $? "starting rabbitmq-server"

rabbitmqctl add_user roboshop roboshop123 &>> $LOG_FILE
VALIDATE $? "adding user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE
VALIDATE $? "setting permissions"

echo "Script completed executing at $(date)" | tee -a $LOG_FILE



