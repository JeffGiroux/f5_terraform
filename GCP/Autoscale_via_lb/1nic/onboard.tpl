#!/bin/bash
source /usr/lib/bigstart/bigip-ready-functions

# BIG-IP ONBOARD SCRIPT

mkdir -p /config/cloud
mkdir -p /var/log/cloud

LOG_FILE=${onboard_log}

# If file exists, exit as we only want to run once
if [ ! -e $LOG_FILE ]; then
  touch $LOG_FILE
  exec &>>$LOG_FILE
else
  exit
fi

date
echo "Starting onboard script"

# ********************************************************************
# ********************************************************************

####################################
#### do.json - Declaration File ####
####################################

# DO
cat <<'EOF' > /config/cloud/do.json
${DO_Document}
EOF

#####################################
#### as3.json - Declaration File ####
#####################################

# AS3
cat <<'EOF' > /config/cloud/as3.json
${AS3_Document}
EOF

####################################
#### ts.json - Declaration File ####
####################################

# TS
cat <<'EOF' > /config/cloud/ts.json
${TS_Document}
EOF

##############################
#### collect-interface.sh ####
##############################

# Retrieve Network Metadata from Google
cat  <<'EOF' > /config/cloud/collect-interface.sh
#!/bin/bash
# Collect network information
COMPUTE_BASE_URL="http://metadata.google.internal/computeMetadata/v1"
echo "INT1ADDRESS=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/0/ip" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "INT1MASK=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/0/subnetmask" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "INT1GATEWAY=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/0/gateway" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "HOSTNAME=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/hostname" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
chmod 755 /config/cloud/interface.config
date
EOF

##########################
#### custom-config.sh ####
##########################

# TMSH, DO, AS3, TS declarations
cat  <<'EOF' > /config/cloud/custom-config.sh
#!/bin/bash
source /usr/lib/bigstart/bigip-ready-functions
wait_bigip_ready

source /config/cloud/interface.config
INT1NETWORK=$(/bin/ipcalc -n $INT1ADDRESS $INT1MASK | cut -d= -f2)
echo "INT1NETWORK=$INT1NETWORK" >> /config/cloud/interface.config

PROGNAME=$(basename $0)

if [ -f /config/startupFinished ]; then
  exit
fi

date
echo "Starting custom config"

# Error Exit Function
function error_exit {
  echo "$${PROGNAME}: $${1:-\"Unknown Error\"}" 1>&2
  exit 1
}

# Network Wait Function
waitNetwork () {
checks=0
echo "Testing network: curl http://example.com"
while [ $checks -lt 120 ]; do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! VE is Ready!"
    break
  fi
  echo "Status code: $STATUS  Not done yet..."
  let checks=checks+1
  sleep 10
done
}

# Toolchain Wait Function
function wait_for_ready {
  app=$1
  checks=0
  checks_max=10
  ready_response=""
  while [ $checks -lt $checks_max ] ; do
    ready_response=$(curl -sku admin:$passwd -w "%%{http_code}" -X GET  https://localhost:$${mgmtGuiPort}/mgmt/shared/$${app}/info -o /dev/null)
    if [[ $ready_response == *200 ]]; then
        echo "$${app} is ready"
        break
    else
        echo "$${app} is not ready: $checks, response: $ready_response"
        let checks=checks+1
        if [[ $checks == $((checks_max/2)) ]]; then
            echo "restarting restnoded"
            bigstart restart restnoded
        fi
        sleep 15
    fi
  done
  if [[ $ready_response != *200 ]]; then
    error_exit "$LINENO: $${app} was not installed correctly. Exit."
  fi
}

# Variables
projectId='${gcp_project_id}'
usecret='${usecret}'
ksecret='${ksecret}'
mgmtGuiPort="8443"

# TMSH commands
tmsh+=(
"tmsh modify sys management-dhcp sys-mgmt-dhcp-config request-options delete { ntp-servers }"
'tmsh save /sys config'
)
for CMD in "$${tmsh[@]}"
do
  if $CMD;then
    echo "command $CMD successfully executed."
  else
    error_exit "$LINENO: An error has occurred while executing $CMD. Aborting!"
  fi
done

date

# BIG-IP Credentials
waitNetwork
echo "Retrieving BIG-IP password from Metadata secret"
svcacct_token=$(curl -s -f --retry 20 "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" -H "Metadata-Flavor: Google" | jq -r ".access_token")
passwd=$(curl -s -f --retry 20 "https://secretmanager.googleapis.com/v1/projects/$projectId/secrets/$usecret/versions/1:access" -H "Authorization: Bearer $svcacct_token" | jq -r ".payload.data" | base64 --decode)

date

# Submit DO Declaration
wait_for_ready declarative-onboarding
file_loc="/config/cloud/do.json"
echo "Submitting DO declaration"
sed -i "s/\$${admin_password}/$passwd/g" $file_loc
sed -i "s/\$${bigIqPassword}/$passwd/g" $file_loc
sed -i "s/\$${local_host}/$HOSTNAME/g" $file_loc
response_code=$(/usr/bin/curl -sku admin:$passwd -w "%%{http_code}" -X POST -H "Content-Type: application/json" -H "Expect:" https://localhost:$${mgmtGuiPort}/mgmt/shared/declarative-onboarding -d @$file_loc -o /dev/null)
if [[ $response_code == *200 || $response_code == *202 ]]; then
  echo "DO task created"
else
  error_exit "$LINENO: DO creation failed. Exit."
fi

# Check DO Task
checks=0
response_code=""
while [ $checks -lt 30 ] ; do
  response_code=$(curl -sku admin:$passwd -X GET  https://localhost:$${mgmtGuiPort}/mgmt/shared/declarative-onboarding/task | jq -r ".[].result.code")
  if [[ $response_code == *200 ]]; then
    echo "DO task successful"
    break
  else
    echo "DO task working..."
    let checks=checks+1
    sleep 10
  fi
done
if [[ $response_code != *200 ]]; then
  error_exit "$LINENO: DO task failed. Exit."
fi

date

# Submit AS3 Declaration
wait_for_ready appsvcs
file_loc="/config/cloud/as3.json"
echo "Submitting AS3 declaration"
sed -i "s/\$${local_selfip_ext}/$INT1ADDRESS/g" $file_loc
response_code=$(/usr/bin/curl -sku admin:$passwd -w "%%{http_code}" -X POST -H "Content-Type: application/json" -H "Expect:" https://localhost:$${mgmtGuiPort}/mgmt/shared/appsvcs/declare -d @$file_loc -o /dev/null)
if [[ $response_code == *200 || $response_code == *502 ]]; then
  echo "Deployment of AS3 succeeded"
else
  echo "Failed to deploy AS3; continuing..."
  echo "Response code: $${response_code}"
fi

date

# # Submit TS Declaration
# wait_for_ready telemetry
# file_loc="/config/cloud/ts.json"
# echo "Submitting TS declaration"
# echo "Retrieving private key from Metadata secret for GCP Cloud Monitoring"
# privateKey=$(curl -s -f --retry 20 "https://secretmanager.googleapis.com/v1/projects/$projectId/secrets/$ksecret/versions/1:access" -H "Authorization: Bearer $svcacct_token" | jq -r ".payload.data" )
# sed -i "s@\$${privateKey}@$privateKey@g" $file_loc
# response_code=$(/usr/bin/curl -sku admin:$passwd -w "%%{http_code}" -X POST -H "Content-Type: application/json" -H "Expect:" https://localhost:$${mgmtGuiPort}/mgmt/shared/telemetry/declare -d @$file_loc -o /dev/null)
# if [[ $response_code == *200 || $response_code == *502 ]]; then
#   echo "Deployment of TS succeeded"
# else
#   echo "Failed to deploy TS; continuing..."
#   echo "Response code: $${response_code}"
# fi

# Cleanup
echo "Removing DO/AS3/TS declaration files"
rm -rf /config/cloud/do.json /config/cloud/as3.json /config/cloud/ts.json

date
echo "Finished custom config"
touch /config/startupFinished
EOF

# ********************************************************************
# ********************************************************************

##############
#### Main ####
##############

# Variables
projectId='${gcp_project_id}'
usecret='${usecret}'
admin_username='${uname}'
DO_URL='${DO_URL}'
DO_FN=$(basename "$DO_URL")
AS3_URL='${AS3_URL}'
AS3_FN=$(basename "$AS3_URL")
TS_URL='${TS_URL}'
TS_FN=$(basename "$TS_URL")
rpmFilePath="/var/config/rest/downloads"

###################
#### Functions ####
###################

# Network Wait Function
waitNetwork () {
checks=0
echo "Testing network: curl http://example.com"
while [ $checks -lt 120 ]; do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! VE is Ready!"
    break
  fi
  echo "Status code: $STATUS  Not done yet..."
  let checks=checks+1
  sleep 10
done
}

#######################
#### Admin Account ####
#######################

date
waitNetwork

# BIG-IP Credentials
svcacct_token=$(curl -s -f --retry 20 "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" -H "Metadata-Flavor: Google" | jq -r ".access_token")
admin_password=$(curl -s -f --retry 20 "https://secretmanager.googleapis.com/v1/projects/$projectId/secrets/$usecret/versions/1:access" -H "Authorization: Bearer $svcacct_token" | jq -r ".payload.data" | base64 --decode)
CREDS="admin:"$admin_password

# Create admin account and password
echo "Updating admin account"
if [[ $admin_username != "admin" ]]; then
  tmsh create auth user $admin_username password "$admin_password" shell bash partition-access add { all-partitions { role admin } };
else
  tmsh modify auth user admin password "$admin_password";
fi

# Copy SSH key
echo "Copying SSH key"
mkdir -p /home/$admin_username/.ssh/
cp /home/admin/.ssh/authorized_keys /home/$admin_username/.ssh/authorized_keys
echo "Admin account updated"

#########################
#### Directory Sizes ####
#########################

date
# Modify appdata directory size
echo "Setting app directory size"
tmsh show sys disk directory /appdata
tmsh modify /sys disk directory /appdata new-size 52256768
tmsh show sys disk directory /appdata
echo "Done setting app directory size"
tmsh save sys config

##########################
#### restjavad memory ####
##########################

date
wait_bigip_ready
# Modify restjavad memory
echo "Increasing extramb for restjavad"
tmsh modify sys db provision.extramb value 500
tmsh modify sys db restjavad.useextramb value true
tmsh save sys config
tmsh restart sys service restjavad
wait_bigip_ready

##############################################
#### Install F5 Automation Toolchain RPMs ####
##############################################

date
mkdir -p $rpmFilePath

echo "Downloading toolchain RPMs"
curl -L -s -f --retry 20 -o $rpmFilePath/$TS_FN $TS_URL
curl -L -s -f --retry 20 -o $rpmFilePath/$DO_FN $DO_URL
curl -L -s -f --retry 20 -o $rpmFilePath/$AS3_FN $AS3_URL
sleep 10

echo "Installing TS Pkg"
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$TS_FN\"}"
curl -s -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA
sleep 10
echo
echo "Installing DO Pkg"
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$DO_FN\"}"
curl -s -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA
sleep 10
echo
echo "Installing AS3 Pkg"
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$AS3_FN\"}"
curl -s -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA
sleep 10
echo
echo "Removing temporary RPM install packages"
rm -rf $rpmFilePath/*.rpm

#############################
#### Set and Run Scripts ####
#############################

chmod +x /config/cloud/custom-config.sh
chmod +x /config/cloud/collect-interface.sh

/config/cloud/collect-interface.sh >> $LOG_FILE
/config/cloud/custom-config.sh >> $LOG_FILE