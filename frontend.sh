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

echo "Disabling default nginx"
dnf module disable -y nginx
VALIDATE $? "Disabling default nginx"

dnf module enable -y nginx:1.24 &>> $LOG_FILE
VALIDATE $? "enabling nginx"


echo "Installing nginx"
dnf install nginx -y
VALIDATE $? "Installing nginx"

echo " enabling nginx"
systemctl enable nginx
systemctl start nginx
VALIDATE $? "enabling and starting nginx"

rm -rf /usr/share/nginx/html/* &>> $LOG_FILE
VALIDATE $? "removing default content"

echo "Downloading frontend content"
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend.zip &>> $LOG_FILE
VALIDATE $? "Downloading frontend content"

echo "Extracting frontend content"
cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>> $LOG_FILE
VALIDATE $? "Extracting frontend content"

echo "Configuring frontend"
rm -rf /etc/nginx/nginx.conf &>> $LOG_FILE
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>> $LOG_FILE
VALIDATE $? "Configuring frontend"

echo "Restarting nginx"
systemctl restart nginx
VALIDATE $? "Restarting nginx"
