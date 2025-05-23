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

dnf install maven -y &>> $LOG_FILE
# shellcheck disable=SC2218
VALIDATE $? "installing maven"

cp $SCRIPT_DIR/$SCRIPT_NAME.service /etc/systemd/system/$SCRIPT_NAME.service &>> $LOG_FILE
# shellcheck disable=SC2218
VALIDATE $? "copying service file"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "creating roboshop user"
else
  echo "user already exists"
fi

mkdir -p /app &>> $LOG_FILE
# shellcheck disable=SC2218
VALIDATE $? "creating app directory"

#!/bin/bash

# Helper function
VALIDATE() {
  if [ "$1" -eq 0 ]; then
    echo -e "\e[32mSUCCESS\e[0m - $2"
  else
    echo -e "\e[31mFAILURE\e[0m - $2"
    exit 1
  fi
}

echo "Downloading shipping artifact..."
curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip
VALIDATE $? "Downloading shipping artifact"

echo "Preparing /app directory..."
mkdir -p /app
cd /app || { echo "Failed to move to /app"; exit 1; }
VALIDATE $? "Moving to app directory"

echo "Unzipping shipping artifact..."
unzip -o /tmp/shipping.zip &>/dev/null
VALIDATE $? "Unzipping shipping artifact"

# Final check
cd /app || exit


mvn clean package &>> $LOG_FILE
VALIDATE $? "mvn clean package"

mv target/$SCRIPT_NAME-1.0.jar $SCRIPT_NAME.jar &>> $LOG_FILE
VALIDATE $? "mvn clean package"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable $SCRIPT_NAME &>> $LOG_FILE
VALIDATE $? "enabling $SCRIPT_NAME service"

systemctl start $SCRIPT_NAME &>> $LOG_FILE
VALIDATE $? "starting $SCRIPT_NAME service"

dnf install mysql -y &>> $LOG_FILE
VALIDATE $? "installing mysql"

mysql -h mysql-internal.doubtfree.online -uroot -pRoboShop@1 < /app/db/schema.sql
mysql -h mysql-internal.doubtfree.online -uroot -pRoboShop@1 < /app/db/app-user.sql
mysql -h mysql-internal.doubtfree.online -uroot -pRoboShop@1 < /app/db/master-data.sql
systemctl restart shipping
