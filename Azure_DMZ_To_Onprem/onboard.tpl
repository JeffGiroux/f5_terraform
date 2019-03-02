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
if ! ping github.com -c 1; then echo "Not Ready, wait for 10sec" && sleep 10; fi

### DOWNLOAD ONBOARDING PKGS
# Could be pre-packaged or hosted internally

admin_username='${uname}'
admin_password='${upassword}'
CREDS="admin:"$admin_password
DO_URL='${DO_onboard_URL}'
DO_FN=$(basename "$DO_URL")
AS3_URL='${AS3_URL}'
AS3_FN=$(basename "$AS3_URL")

mkdir -p ${libs_dir}

echo -e "\n"$(date) "Download Declarative Onboarding Pkg"
curl -o ${libs_dir}/$DO_FN $DO_URL

echo -e "\n"$(date) "Download AS3 Pkg"
curl -o ${libs_dir}/$AS3_FN $AS3_URL
sleep 20

# Copy the RPM Pkg to the file location
cp ${libs_dir}/*.rpm /var/config/rest/downloads/

# Install Declarative Onboarding Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$DO_FN\"}"
echo -e "\n"$(date) "Install DO Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

# Install AS3 Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$AS3_FN\"}"
echo -e "\n"$(date) "Install AS3 Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

sleep 5

echo -e "\n"$(date) "Setup Cluster With Declarative Onboarding"
curl -k -u $CREDS -X POST https://localhost/mgmt/shared/declarative-onboarding -d @/var/tmp/vm_do.json

echo -e "\n"$(date) "Configure HTTPS/HTTP Virtual with AS3"
curl -k -u $CREDS -X POST https://localhost/mgmt/shared/appsvcs/declare -d @/var/tmp/as3.json
