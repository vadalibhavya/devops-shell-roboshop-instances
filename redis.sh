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

dnf module disable redis -y &>> $LOG_FILE
VALIDATE $? "disabling default redis"

dnf module enable redis:7 -y &>> $LOG_FILE
VALIDATE $? "enabling redis"

dnf install redis -y &>> $LOG_FILE
VALIDATE $? "installing redis"

sed -i 's/127.0.0.1/0.0.0.0/' /etc/redis/redis.conf &>> $LOG_FILE
sed -i 's/proctected-mode yes/protected-mode no/' /etc/redis/redis.conf &>> $LOG_FILE

systemctl enable redis &>> $LOG_FILE
systemctl start redis &>> $LOG_FILE
VALIDATE $? "starting redis"

echo -e "${Y}Check redis status${N}"
systemctl status redis | grep running &>> $LOG_FILE


