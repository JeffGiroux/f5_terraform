#!/bin/bash

# BIG-IP ONBOARD SCRIPT

########################
#### Log File Setup ####
########################

mkdir -p /var/log/cloud/google

LOG_FILE=${onboard_log}

# If file exists, exit as we only want to run once
if [ ! -e $LOG_FILE ]
then
     touch $LOG_FILE
     exec &>>$LOG_FILE
else
    exit
fi

exec 1>$LOG_FILE 2>&1
echo -e $(date) "---Starting---"

###################
#### Variables ####
###################

# Variables
projectId='${gcp_project_id}'
usecret='${usecret}'
admin_username='${uname}'

# BIG-IP password from Metadata
svcacct_token=$(curl -s -f --retry 20 "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" -H "Metadata-Flavor: Google" | jq -r ".access_token")
admin_password=$(curl -s -f --retry 20 "https://secretmanager.googleapis.com/v1/projects/$projectId/secrets/$usecret/versions/1:access" -H "Authorization: Bearer $svcacct_token" | jq -r ".payload.data" | base64 --decode)

# RPM Download/Install Folders
CREDS="admin:"$admin_password
local_host="http://localhost:8100"
local_host443="https://localhost"
rpmInstallUrl="/mgmt/shared/iapp/package-management-tasks"
rpmFilePath="/var/config/rest/downloads"

# DO urls
DO_URL='${DO_URL}'
DO_FN=$(basename "$DO_URL")
doUrl="/mgmt/shared/declarative-onboarding"
doCheckUrl="/mgmt/shared/declarative-onboarding/info"
doTaskUrl="/mgmt/shared/declarative-onboarding/task"
# AS3 urls
AS3_URL='${AS3_URL}'
AS3_FN=$(basename "$AS3_URL")
as3Url="/mgmt/shared/appsvcs/declare"
as3CheckUrl="/mgmt/shared/appsvcs/info"
as3TaskUrl="/mgmt/shared/appsvcs/task"
# TS urls
TS_URL='${TS_URL}'
TS_FN=$(basename "$TS_URL")
tsUrl="/mgmt/shared/telemetry/declare"
tsCheckUrl="/mgmt/shared/telemetry/info"
tsTaskUrl="/mgmt/shared/telemetry/task"

###################
#### Functions ####
###################

# mcpd Wait Function
waitMcpd () {
CNT=0
echo -e $(date) "Checking status of mcpd"
while [[ $CNT -lt 120 ]]; do
  tmsh -a show sys mcp-state field-fmt | grep -q running
  if [ $? == 0 ]; then
    echo -e $(date) "mcpd ready"
    break
  fi
  echo -e $(date) "mcpd not ready yet"
  CNT=$[$CNT+1]
  sleep 10
done
}

# Network Wait Function
waitNetwork () {
CNT=0
echo -e $(date) "Testing network: curl http://example.com"
while [[ $CNT -lt 120 ]]; do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo -e $(date) "Got 200! VE is Ready!"
    break
  fi
  echo -e $(date) "Status code: $STATUS  Not done yet..."
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
echo -e $(date) "Change management interface to eth1"
waitMcpd
bigstart stop tmm
tmsh modify sys db provision.managementeth value eth1
tmsh modify sys db provision.1nicautoconfig value disable
bigstart start tmm
waitMcpd
echo -e $(date) "---Mgmt interface setting---"
tmsh list sys db provision.managementeth
tmsh list sys db provision.1nicautoconfig

# Modify ASM interface
# https://cdn.f5.com/product/bugtracker/ID726401.html
cp /etc/ts/common/image.cfg /etc/ts/common/image.cfg.bak
sed -i "s/iface0=eth0/iface0=eth1/g" /etc/ts/common/image.cfg
echo -e $(date) "Done changing interface"

#######################
#### Admin Account ####
#######################

waitNetwork

# Create admin account and password
echo -e $(date) "Updating admin account"
if [[ $admin_username == "admin" ]]; then
  tmsh modify auth user $admin_username password "$admin_password";
else
  tmsh create auth user $admin_username password "$admin_password" shell bash partition-access add { all-partitions { role admin } };
fi
tmsh list auth user $admin_username

# Copy SSH key
echo -e $(date) "Copying SSH key"
mkdir -p /home/$admin_username/.ssh/
cp /home/admin/.ssh/authorized_keys /home/$admin_username/.ssh/authorized_keys
echo -e $(date) "Admin account updated"

#########################
#### Directory Sizes ####
#########################

# Modify appdata directory size
echo -e $(date) "Setting app directory size"
tmsh show sys disk directory /appdata
tmsh modify /sys disk directory /appdata new-size 52256768
tmsh show sys disk directory /appdata
echo -e $(date) "Done setting app directory size"
tmsh save sys config

###############################################
#### Download F5 Automation Toolchain RPMs ####
###############################################

mkdir -p $rpmFilePath

# Download the RPM files
echo -e "\n"$(date) "Download Telemetry (TS) Pkg"
curl -L -k -o $rpmFilePath/$TS_FN $TS_URL

echo -e "\n"$(date) "Download Declarative Onboarding (DO) Pkg"
curl -L -k -o $rpmFilePath/$DO_FN $DO_URL

echo -e "\n"$(date) "Download Application Services 3 (AS3) Pkg"
curl -L -k -o $rpmFilePath/$AS3_FN $AS3_URL

sleep 10

##############################################
#### Install F5 Automation Toolchain RPMs ####
##############################################

# Install Telemetry Streaming Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$TS_FN\"}"
echo -e "\n"$(date) "Install TS Pkg"
curl -u $CREDS -X POST $local_host$rpmInstallUrl -d $DATA

sleep 10

# Install Declarative Onboarding Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$DO_FN\"}"
echo -e "\n"$(date) "Install DO Pkg"
curl -u $CREDS -X POST $local_host$rpmInstallUrl -d $DATA

sleep 10

# Install AS3 Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$AS3_FN\"}"
echo -e "\n"$(date) "Install AS3 Pkg"
curl -u $CREDS -X POST $local_host$rpmInstallUrl -d $DATA

sleep 10

#################################################
#### Validate F5 Automation Toolchain Status ####
#################################################

# Check DO Ready
CNT=0
echo -e "\n"$(date) "Check DO Ready"
while [[ $CNT -lt 6 ]]; do
  STATUS=$(curl -u $CREDS -X GET -s -k -I $local_host443$doCheckUrl | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo -e $(date) "Got 200! DO is Ready!"
    break
  fi
  echo -e $(date) "Status code: $STATUS  DO Not done yet..."
  CNT=$[$CNT+1]
  sleep 10
done

# Check AS3 Ready
CNT=0
echo -e "\n"$(date) "Check AS3 Ready"
while [[ $CNT -lt 6 ]]; do
  STATUS=$(curl -u $CREDS -X GET -s -k -I $local_host443$as3CheckUrl | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo -e $(date) "Got 200! AS3 is Ready!"
    break
  fi
  echo -e $(date) "Status code: $STATUS  AS3 Not done yet..."
  CNT=$[$CNT+1]
  sleep 10
done

# Check TS Ready
CNT=0
echo -e "\n"$(date) "Check TS Ready"
while [[ $CNT -lt 6 ]]; do
  STATUS=$(curl -u $CREDS -X GET -s -k -I $local_host443$tsCheckUrl | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo -e $(date) "Got 200! TS is Ready!"
    break
  fi
  echo -e $(date) "Status code: $STATUS  TS Not done yet..."
  CNT=$[$CNT+1]
  sleep 10
done

###############################################
#### Retrieve Network Metadata from Google ####
###############################################

echo -e $(date) "Retrieving instance metadata from Google"

# Collect network information
MGMTADDRESS=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/ip' -H 'Metadata-Flavor: Google')
MGMTMASK=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/subnetmask' -H 'Metadata-Flavor: Google')
MGMTGATEWAY=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/gateway' -H 'Metadata-Flavor: Google')

INT2ADDRESS=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip' -H 'Metadata-Flavor: Google')
INT2MASK=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/subnetmask' -H 'Metadata-Flavor: Google')
INT2GATEWAY=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/gateway' -H 'Metadata-Flavor: Google')

MGMTNETWORK=$(/bin/ipcalc -n $MGMTADDRESS $MGMTMASK | cut -d= -f2)
INT2NETWORK=$(/bin/ipcalc -n $INT2ADDRESS $INT2MASK | cut -d= -f2)

echo -e $(date) "---Network Settings---"
echo "mgmt:$MGMTADDRESS,$MGMTMASK,$MGMTGATEWAY"
echo "external:$INT2ADDRESS,$INT2MASK,$INT2GATEWAY"
echo "cidr: $MGMTNETWORK,$INT2NETWORK"

####################################
#### Additional Startup Scripts ####
####################################

mkdir -p /config/cloud/gce

# Scripts for /config/startup
# https://support.f5.com/csp/article/K11948
chmod +w /config/startup
echo "/config/cloud/gce/mgmtroute.sh &" >> /config/startup
echo "/config/cloud/gce/custom-config.sh &" >> /config/startup

# Script #1 -- Mgmt reboot workaround
# Add mgmt default route and set MTU 1460
# https://support.f5.com/csp/article/K47835034
cat  <<EOF > /config/cloud/gce/mgmtroute.sh
#!/bin/bash

# Log File Setup
LOG_FILE="/var/log/cloud/google/mgmtroute.log"
exec &>>\$LOG_FILE

# mcpd Wait Function
waitMcpd () {
CNT=0
echo -e \$(date) "Checking status of mcpd"
while [[ \$CNT -lt 120 ]]; do
  tmsh -a show sys mcp-state field-fmt | grep -q running
  if [ \$? == 0 ]; then
    echo -e \$(date) "mcpd ready"
    break
  fi
  echo -e \$(date) "mcpd not ready yet"
  CNT=\$[\$CNT+1]
  sleep 10
done
}

echo -e \$(date) "Checking status of mcpd"
waitMcpd

echo -e \$(date) "Fixing Mgmt Route - First try"
tmsh delete sys management-route default
tmsh create sys management-route default gateway $MGMTGATEWAY mtu 1460
sleep 120
echo -e \$(date) "Fixing Mgmt Route - Second try"
tmsh delete sys management-route default
tmsh create sys management-route default gateway $MGMTGATEWAY mtu 1460
tmsh save sys config
echo -e \$(date) "Done"
EOF
chmod +x /config/cloud/gce/mgmtroute.sh
# End Script #1 -- Mgmt reboot workaround


# Script #2 -- Declarations for F5 Automation Toolchain
# Add network, vlans, IPs, profiles, etc
cat  <<EOF > /config/cloud/gce/custom-config.sh
#!/bin/bash

# BIG-IP F5 CUSTOM CONFIG SCRIPT

########################
#### Log File Setup ####
########################

LOG_FILE="/var/log/cloud/google/custom-config.log"

# If file exists, exit as we only want to run once
if [ ! -e \$LOG_FILE ]
then
     touch \$LOG_FILE
     exec &>>\$LOG_FILE
else
    exit
fi

exec 1>\$LOG_FILE 2>&1
echo -e \$(date) "---Starting---"

###################
#### Functions ####
###################

# mcpd Wait Function
waitMcpd () {
CNT=0
echo -e \$(date) "Checking status of mcpd"
while [[ \$CNT -lt 120 ]]; do
  tmsh -a show sys mcp-state field-fmt | grep -q running
  if [ \$? == 0 ]; then
    echo -e \$(date) "mcpd ready"
    break
  fi
  echo -e \$(date) "mcpd not ready yet"
  CNT=\$[\$CNT+1]
  sleep 10
done
}

######################################
#### POST DO and AS3 Declarations ####
######################################

# To Do:
# 1. change tmsh commands for network to DO
# 2. optionally add AS3 too

waitMcpd

echo -e \$(date) "Disable GUI setup"
tmsh modify sys global-settings gui-setup disabled

echo -e \$(date) "Set TMM networks"
echo -e "create cli transaction;
modify sys global-settings mgmt-dhcp disabled;
delete sys management-route all;
delete sys management-ip all;
create sys management-ip $MGMTADDRESS/32;
create sys management-route mgmt_gw network $MGMTGATEWAY/32 type interface mtu 1460;
create sys management-route mgmt_net network $MGMTNETWORK/$MGMTMASK gateway $MGMTGATEWAY mtu 1460;
create sys management-route default gateway $MGMTGATEWAY mtu 1460;
modify sys management-dhcp sys-mgmt-dhcp-config request-options delete { ntp-servers };
create net vlan external interfaces add { 1.0 } mtu 1460;
create net self external-self address $INT2ADDRESS/32 vlan external;
create net route ext_gw_interface network $INT2GATEWAY/32 interface external;
create net route ext_rt network $INT2NETWORK/$INT2MASK gw $INT2GATEWAY;
create net route default gw $INT2GATEWAY;
submit cli transaction" | tmsh -q
tmsh save sys config
echo -e \$(date) "---Complete---"

exit
EOF
chmod +x /config/cloud/gce/custom-config.sh
# End Script #2 -- Declarations for F5 Automation Toolchain

#################
#### Cleanup ####
#################

# Delete RPM packages
echo -e $(date) "Removing temporary RPM install packages"
rm -rf $rpmFilePath/*.rpm

################
#### Reboot ####
################

echo -e $(date) "Rebooting for NIC swap to complete..."
reboot
