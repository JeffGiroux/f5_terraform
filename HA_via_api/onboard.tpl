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

tmsh modify sys db config.allow.rfc3927 value enable
tmsh create sys management-route fometa_route network 169.254.169.254/32 gateway '${mgmt_gw}'
tmsh save sys config

### DOWNLOAD ONBOARDING PKGS
# Could be pre-packaged or hosted internally

admin_username='${uname}'
admin_password='${upassword}'
CREDS="admin:"$admin_password
DO_URL='${DO_onboard_URL}'
DO_FN=$(basename "$DO_URL")
AS3_URL='${AS3_URL}'
AS3_FN=$(basename "$AS3_URL")
TS_URL='${TS_URL}'
TS_FN=$(basename "$TS_URL")
CF_URL='${CF_URL}'
CF_FN=$(basename "$CF_URL")


mkdir -p ${libs_dir}

echo -e "\n"$(date) "Download TS Pkg"
curl -L -k -o ${libs_dir}/$TS_FN $TS_URL

echo -e "\n"$(date) "Download Declarative Onboarding Pkg"
curl -L -k -o ${libs_dir}/$DO_FN $DO_URL

echo -e "\n"$(date) "Download AS3 Pkg"
curl -L -k -o ${libs_dir}/$AS3_FN $AS3_URL

echo -e "\n"$(date) "Download CF Pkg"
curl -L -k -o ${libs_dir}/$CF_FN $CF_URL
sleep 20

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

# Install CF Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$CF_FN\"}"
echo -e "\n"$(date) "Install CF Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

sleep 10

# Check DO Ready
CNT=0
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/declarative-onboarding | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! Declarative Onboarding is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  DO Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

# Check AS3 Ready
CNT=0
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/appsvcs/info | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! AS3 is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  AS3 Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

# Check TS Ready
CNT=0
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/telemetry/declare | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! TS is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  TS Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

# Check CF Ready
CNT=0
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/cloud-failover/info | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! TS is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  TS Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

sleep 60
