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

######################################
#### POST DO and AS3 Declarations ####
######################################

# Variables DO urls
doUrl="/mgmt/shared/declarative-onboarding"
doCheckUrl="/mgmt/shared/declarative-onboarding/info"
doTaskUrl="/mgmt/shared/declarative-onboarding/task"
# Variables AS3 urls
as3Url="/mgmt/shared/appsvcs/declare"
as3CheckUrl="/mgmt/shared/appsvcs/info"
as3TaskUrl="/mgmt/shared/appsvcs/task"
# Variables TS urls
tsUrl="/mgmt/shared/telemetry/declare"
tsCheckUrl="/mgmt/shared/telemetry/info"
tsTaskUrl="/mgmt/shared/telemetry/task"

# Declaration content
cat > /config/do.json <<EOF
${DO_Document}
EOF
cat > /config/as3.json <<'EOF'
${AS3_Document}
EOF
cat > /config/ts.json <<EOF
${TS_Document}
EOF

# Collect network metadata from Azure
hostName=`echo $(curl -s -f -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-06-01" | jq -r '.["name"]')`
local_selfip=`echo $(curl -s -f -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface?api-version=2019-06-01" | jq -r '.[1].ipv4[]' | grep private | awk '{print $2}' | awk -F \" '{print $2}') | awk '{print $1}'`

# Modify DO json file with retreived Azure metadata
sed -i "s/-device-hostname-/$hostName/g" /config/do.json
sed -i "s/-external-self-address-/$local_selfip/g" /config/do.json

# Submit DO Declaration
echo -e "\n"$(date) "Submitting DO declaration"
curl -u $CREDS -X POST -k https://localhost/$doUrl -d @/config/do.json

# Check DO Task
CNT=0
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k https://localhost/$doTaskUrl)
  if ( echo $STATUS | grep "OK" ); then
    echo -e "\n"$(date) "DO task successful"
    break
  elif [ $CNT -le 30 ]; then
    echo -e "\n"$(date) "DO task working..."
    CNT=$[$CNT+1]
  else
    echo -e "\n"$(date) "DO task fail"
    break
  fi
  sleep 10
done

# Submit TS Declaration
echo -e "\n"$(date) "Submitting TS declaration"
curl -u $CREDS -H "Content-Type: Application/json" -X POST -k https://localhost/$tsUrl -d @/config/ts.json

# Submit AS3 Declaration
echo -e "\n"$(date) "Submitting AS3 declaration"
curl -u $CREDS -X POST -k https://localhost/$as3Url -d @/config/as3.json

# Delete declaration files (do.json, as3.json) packages
echo -e "\n"$(date) "Removing DO and AS3 declaration files"
rm -rf /config/do.json /config/as3.json /config/ts.json

# Done
echo -e "\n"$(date) "===Onboard Complete==="
