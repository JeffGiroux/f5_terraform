#!/bin/bash

# BIG-IP ONBOARD SCRIPT

########################
#### Log File Setup ####
########################

LOG_FILE=${onboard_log}

# If file exists, exit as we only want to run once
if [ ! -e $LOG_FILE ]; then
  touch $LOG_FILE
  exec &>>$LOG_FILE
else
  exit
fi

exec 1>$LOG_FILE 2>&1
echo "Starting onboard script"

###################
#### Variables ####
###################

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

# mcpd Wait Function
waitMcpd () {
CNT=0
echo "Checking status of mcpd"
while [[ $CNT -lt 120 ]]; do
  tmsh -a show sys mcp-state field-fmt | grep -q running
  if [ $? == 0 ]; then
    echo "mcpd ready"
    break
  fi
  echo "mcpd not ready yet"
  CNT=$[$CNT+1]
  sleep 10
done
}

# Network Wait Function
waitNetwork () {
CNT=0
echo "Testing network: curl http://example.com"
while [[ $CNT -lt 120 ]]; do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! VE is Ready!"
    break
  fi
  echo "Status code: $STATUS  Not done yet..."
  CNT=$[$CNT+1]
  sleep 10
done
}

#######################
#### Swap Mgmt NIC ####
#######################

# Swap management interface to NIC1 (mgmt)
# https://clouddocs.f5.com/cloud/public/v1/shared/change_mgmt_nic_google.html
# https://cloud.google.com/load-balancing/docs/load-balancing-overview#backend_region_and_network
date
echo "Change management interface to eth1"
waitMcpd
bigstart stop tmm
tmsh modify sys db provision.managementeth value eth1
tmsh modify sys db provision.1nicautoconfig value disable
bigstart start tmm
waitMcpd
date
echo "---Mgmt interface setting---"
tmsh list sys db provision.managementeth
tmsh list sys db provision.1nicautoconfig

# Modify ASM interface
# https://cdn.f5.com/product/bugtracker/ID726401.html
cp /etc/ts/common/image.cfg /etc/ts/common/image.cfg.bak
sed -i "s/iface0=eth0/iface0=eth1/g" /etc/ts/common/image.cfg
echo "Done changing interface"

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
if [[ $admin_username == "admin" ]]; then
  tmsh modify auth user $admin_username password "$admin_password";
else
  tmsh create auth user $admin_username password "$admin_password" shell bash partition-access add { all-partitions { role admin } };
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

###############################################
#### Download F5 Automation Toolchain RPMs ####
###############################################

date
mkdir -p $rpmFilePath
echo "Downloading toolchain RPMs"
curl -L -s -f --retry 20 -o $rpmFilePath/$TS_FN $TS_URL
curl -L -s -f --retry 20 -o $rpmFilePath/$DO_FN $DO_URL
curl -L -s -f --retry 20 -o $rpmFilePath/$AS3_FN $AS3_URL
sleep 10

##############################################
#### Install F5 Automation Toolchain RPMs ####
##############################################

echo -e "\n"$(date) "Installing TS Pkg"
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$TS_FN\"}"
curl -s -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA
sleep 10

echo -e "\n"$(date) "Installing DO Pkg"
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$DO_FN\"}"
curl -s -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA
sleep 10

echo -e "\n"$(date) "Installing AS3 Pkg"
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$AS3_FN\"}"
curl -s -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA
sleep 10

###############################################
#### Retrieve Network Metadata from Google ####
###############################################

date
mkdir -p /config/cloud
echo "Retrieving network instance metadata"

# Collect network information
echo "MGMTADDRESS=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/ip' -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "MGMTMASK=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/subnetmask' -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "MGMTGATEWAY=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/gateway' -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "INT2ADDRESS=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip' -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "INT2MASK=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/subnetmask' -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "INT2GATEWAY=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/gateway' -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
chmod 755 /config/cloud/interface.config

################################
#### Declaration JSON Files ####
################################

# AS3
cat <<'EOF' > /config/cloud/as3.json
${AS3_Document}
EOF

# ********************************************************************
# ********************************************************************

#####################################
#### Post-Reboot Startup Scripts ####
#####################################

# Scripts for /config/startup
# https://support.f5.com/csp/article/K11948
chmod +w /config/startup
echo "(/config/cloud/mgmtroute.sh; /config/cloud/custom-config.sh) &" >> /config/startup


# Script #1 -- Mgmt reboot workaround
# Add mgmt default route
# https://support.f5.com/csp/article/K85730674
cat  <<'EOF' > /config/cloud/mgmtroute.sh
#!/bin/bash
source /config/cloud/interface.config
# Log File Setup
LOG_FILE="/var/log/mgmtroute.log"
exec &>>$LOG_FILE
echo "Waiting for mcpd"
sleep 120
echo "First try"
tmsh delete sys management-route default
tmsh create sys management-route default gateway $MGMTGATEWAY mtu 1460
sleep 120
echo "Second try"
tmsh delete sys management-route default
tmsh create sys management-route default gateway $MGMTGATEWAY mtu 1460
tmsh save sys config
echo "Done"
EOF
chmod +x /config/cloud/mgmtroute.sh
# End Script #1 -- Mgmt reboot workaround


# Script #2 -- Declarations for F5 Automation Toolchain
# Add network, vlans, IPs, profiles, etc - runs only once
cat  <<'EOF' > /config/cloud/custom-config.sh
#!/bin/bash
source /config/cloud/interface.config
MGMTNETWORK=$(/bin/ipcalc -n $MGMTADDRESS $MGMTMASK | cut -d= -f2)
INT2NETWORK=$(/bin/ipcalc -n $INT2ADDRESS $INT2MASK | cut -d= -f2)
PROGNAME=$(basename $0)

# BIG-IP F5 CUSTOM CONFIG SCRIPT

########################
#### Log File Setup ####
########################

LOG_FILE="/var/log/custom-config.log"

# If file exists, exit as we only want to run once
if [ ! -e $LOG_FILE ]; then
  touch $LOG_FILE
  exec &>>$LOG_FILE
else
  exit
fi

exec 1>$LOG_FILE 2>&1
date
echo "Starting custom-config.sh"

###################
#### Functions ####
###################

function error_exit {
  echo "$${PROGNAME}: $${1:-\"Unknown Error\"}" 1>&2
  exit 1
}

# mcpd Wait Function
waitMcpd () {
CNT=0
echo "Checking status of mcpd"
while [[ $CNT -lt 120 ]]; do
  tmsh -a show sys mcp-state field-fmt | grep -q running
  if [ $? == 0 ]; then
    echo "mcpd ready"
    break
  fi
  echo "mcpd not ready yet"
  CNT=$[$CNT+1]
  sleep 10
done
}

# DO Wait Function
function do_wait_for_ready {
  checks=0
  ready_response=""
  ready_response_declare=""
  while [ $checks -lt 120 ] ; do
    ready_response=$(curl -sku admin:$passwd -w "%%{http_code}" -X GET  https://localhost:$${mgmtGuiPort}/mgmt/shared/declarative-onboarding/info -o /dev/null)
    ready_response_declare=$(curl -sku admin:$passwd -w "%%{http_code}" -X GET  https://localhost:$${mgmtGuiPort}/mgmt/shared/declarative-onboarding -o /dev/null)
    if [[ $ready_response == *200 && $ready_response_declare == *200 ]]; then
      echo "DO is ready"
      break
    else
      echo "DO" is not ready: $checks, response: $ready_response $ready_response_declare
      let checks=checks+1
      if [[ $checks == 60 ]]; then
        bigstart restart restnoded
      fi
      sleep 5
    fi
  done
  if [[ $ready_response != *200 || $ready_response_declare != *200 ]]; then
    error_exit "$LINENO: DO was not installed correctly. Exit."
  fi
}

# TS Wait Function
function ts_wait_for_ready {
  checks=0
  ready_response=""
  ready_response_declare=""
  while [ $checks -lt 120 ] ; do
    ready_response=$(curl -sku admin:$passwd -w "%%{http_code}" -X GET  https://localhost:$${mgmtGuiPort}/mgmt/shared/telemetry/info -o /dev/null)
    ready_response_declare=$(curl -sku admin:$passwd -w "%%{http_code}" -X GET  https://localhost:$${mgmtGuiPort}/mgmt/shared/telemetry/declare -o /dev/null)
    if [[ $ready_response == *200 && $ready_response_declare == *200 ]]; then
      echo "TS is ready"
      break
    else
      echo "TS" is not ready: $checks, response: $ready_response $ready_response_declare
      let checks=checks+1
      if [[ $checks == 60 ]]; then
        bigstart restart restnoded
      fi
      sleep 5
    fi
  done
  if [[ $ready_response != *200 || $ready_response_declare != *200 ]]; then
    error_exit "$LINENO: TS was not installed correctly. Exit."
  fi
}

# AS3 Wait Function
function as3_wait_for_ready {
  checks=0
  ready_response=""
  ready_response_declare=""
  while [ $checks -lt 120 ] ; do
    ready_response=$(curl -sku admin:$passwd -w "%%{http_code}" -X GET  https://localhost:$${mgmtGuiPort}/mgmt/shared/appsvcs/info -o /dev/null)
    ready_response_declare=$(curl -sku admin:$passwd -w "%%{http_code}" -X GET  https://localhost:$${mgmtGuiPort}/mgmt/shared/appsvcs/declare -o /dev/null)
    if [[ $ready_response == *200 && $ready_response_declare == *204 ]]; then
      echo "AS3 is ready"
      break
    else
      echo "AS3" is not ready: $checks, response: $ready_response $ready_response_declare
      let checks=checks+1
      if [[ $checks == 60 ]]; then
        bigstart restart restnoded
      fi
      sleep 5
    fi
  done
  if [[ $ready_response != *200 || $ready_response_declare != *204 ]]; then
    error_exit "$LINENO: AS3 was not installed correctly. Exit."
  fi
}

###################
#### Variables ####
###################

# Variables
projectId='${gcp_project_id}'
usecret='${usecret}'
mgmtGuiPort="443"
doUrl="/mgmt/shared/declarative-onboarding"
doCheckUrl="/mgmt/shared/declarative-onboarding/info"
doTaskUrl="/mgmt/shared/declarative-onboarding/task"
as3Url="/mgmt/shared/appsvcs/declare"
as3CheckUrl="/mgmt/shared/appsvcs/info"
as3TaskUrl="/mgmt/shared/appsvcs/task"
tsUrl="/mgmt/shared/telemetry/declare"
tsCheckUrl="/mgmt/shared/telemetry/info"
tsTaskUrl="/mgmt/shared/telemetry/task"

########################################
#### TMSH, DO, AS3, TS Declarations ####
########################################

# To Do:
# 1. change tmsh commands for network to DO
# 2. optionally add AS3 too

date
waitMcpd

# BIG-IP Credentials
echo "Retrieving BIG-IP password from Metadata secret"
svcacct_token=$(curl -s -f --retry 20 "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" -H "Metadata-Flavor: Google" | jq -r ".access_token")
passwd=$(curl -s -f --retry 20 "https://secretmanager.googleapis.com/v1/projects/$projectId/secrets/$usecret/versions/1:access" -H "Authorization: Bearer $svcacct_token" | jq -r ".payload.data" | base64 --decode)

# Configure BIG-IP network settings
echo "Set TMM networks"
tmsh+=(
"tmsh modify sys global-settings gui-setup disabled"
"tmsh modify sys global-settings mgmt-dhcp disabled"
"tmsh delete sys management-route all"
"tmsh delete sys management-ip all"
"tmsh create sys management-ip $${MGMTADDRESS}/32"
"tmsh create sys management-route mgmt_gw network $${MGMTGATEWAY}/32 type interface mtu 1460"
"tmsh create sys management-route mgmt_net network $${MGMTNETWORK}/$${MGMTMASK} gateway $${MGMTGATEWAY} mtu 1460"
"tmsh create sys management-route default gateway $${MGMTGATEWAY} mtu 1460"
"tmsh create net vlan external interfaces add { 1.0 } mtu 1460"
"tmsh create net self self_external address $${INT2ADDRESS}/32 vlan external"
"tmsh create net route ext_gw_interface network $${INT2GATEWAY}/32 interface external"
"tmsh create net route ext_rt network $${INT2NETWORK}/$${INT2MASK} gw $${INT2GATEWAY}"
"tmsh create net route default gw $${INT2GATEWAY}"
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

# Submit DO Declaration
do_wait_for_ready

# Submit TS Declaration
ts_wait_for_ready

# Submit AS3 Declaration
as3_wait_for_ready
file_loc="/config/cloud/as3.json"
echo "Submitting AS3 declaration"
response_code=$(/usr/bin/curl -sku admin:$passwd -w "%%{http_code}" -X POST -H "Content-Type: application/json" -H "Expect:" https://localhost:$${mgmtGuiPort}/mgmt/shared/appsvcs/declare -d @$file_loc -o /dev/null)
if [[ $response_code == *200 || $response_code == *502 ]]; then
  echo "Deployment of custom application succeeded"
else
  echo "Failed to deploy custom application; continuing..."
  echo "Response code: $${response_code}"
fi

# Delete declaration files (do.json, as3.json) packages
echo "Removing DO and AS3 declaration files"
rm -rf /config/cloud/do.json /config/cloud/as3.json /config/cloud/ts.json

date
echo "Finished custom-config.sh"

exit
EOF
chmod +x /config/cloud/custom-config.sh
# End Script #2 - Declarations for F5 Automation Toolchain

# ********************************************************************
# ********************************************************************

#################
#### Cleanup ####
#################

date
echo "Removing temporary RPM install packages"
rm -rf $rpmFilePath/*.rpm
echo "Rebooting for NIC swap to complete..."
reboot
