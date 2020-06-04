#!/bin/bash

# BIG-IPS ONBOARD SCRIPT

LOG_FILE=${onboard_log}

if [ ! -e $LOG_FILE ]
then
     touch $LOG_FILE
     exec &>>$LOG_FILE
else
    #if file exists, exit as only want to run once
    exit
fi

exec 1>$LOG_FILE 2>&1

# CHECK TO SEE NETWORK IS READY
CNT=0
while true
do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! VE is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

sleep 60

###############################################
#### Download F5 Automation Toolchain RPMs ####
###############################################

# Variables
admin_username='${admin_user}'
admin_password='${admin_password}'
CREDS="admin:"$admin_password
DO_URL='${DO_URL}'
DO_FN=$(basename "$DO_URL")
AS3_URL='${AS3_URL}'
AS3_FN=$(basename "$AS3_URL")
TS_URL='${TS_URL}'
TS_FN=$(basename "$TS_URL")

mkdir -p ${libs_dir}

echo -e "\n"$(date) "Download Telemetry (TS) Pkg"
curl -L -k -o ${libs_dir}/$TS_FN $TS_URL

echo -e "\n"$(date) "Download Declarative Onboarding (DO) Pkg"
curl -L -k -o ${libs_dir}/$DO_FN $DO_URL

echo -e "\n"$(date) "Download Application Services 3 (AS3) Pkg"
curl -L -k -o ${libs_dir}/$AS3_FN $AS3_URL

sleep 10

# Copy the RPM Pkg to the file location
cp ${libs_dir}/*.rpm /var/config/rest/downloads/

# Install Telemetry Streaming Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$TS_FN\"}"
echo -e "\n"$(date) "Install TS Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

sleep 10

# Install Declarative Onboarding Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$DO_FN\"}"
echo -e "\n"$(date) "Install DO Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

sleep 10

# Install AS3 Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$AS3_FN\"}"
echo -e "\n"$(date) "Install AS3 Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

sleep 10

# Check DO Ready
CNT=0
echo -e "\n"$(date) "Check DO Ready"
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/declarative-onboarding/info | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo -e "\n"$(date) "Got 200! DO is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo -e "\n"$(date) "Status code: $STATUS  DO Not done yet..."
    CNT=$[$CNT+1]
  else
    echo -e "\n"$(date) "(DO) GIVE UP..."
    break
  fi
  sleep 10
done

# Check AS3 Ready
CNT=0
echo -e "\n"$(date) "Check AS3 Ready"
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/appsvcs/info | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo -e "\n"$(date) "Got 200! AS3 is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo -e "\n"$(date) "Status code: $STATUS  AS3 Not done yet..."
    CNT=$[$CNT+1]
  else
    echo -e "\n"$(date) "(AS3) GIVE UP..."
    break
  fi
  sleep 10
done

# Check TS Ready
CNT=0
echo -e "\n"$(date) "Check TS Ready"
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/telemetry/info | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo -e "\n"$(date) "Got 200! TS is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo -e "\n"$(date) "Status code: $STATUS  TS Not done yet..."
    CNT=$[$CNT+1]
  else
    echo -e "\n"$(date) "(TS) GIVE UP..."
    break
  fi
  sleep 10
done

# Delete RPM packages
echo -e "\n"$(date) "Removing temporary RPM install packages"
rm -rf /var/config/rest/downloads/*.rpm

sleep 5
