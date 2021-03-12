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

##############################
#### collect-interface.sh ####
##############################

# Retrieve Network Metadata from AWS
cat  <<'EOF' > /config/cloud/collect-interface.sh
#!/bin/bash
# Collect network information
#MACS=`curl -s -f --retry 10 http://169.254.169.254/latest/meta-data/network/interfaces/macs`
#MGMT_MAC=`curl -s -f --retry 10 http://169.254.169.254/latest/meta-data/mac`
#INT1_MAC=$(echo $MACS | awk -F/ '{ print $1 }')
INT1_MAC=`curl -s -f --retry 10 http://169.254.169.254/latest/meta-data/mac`
GATEWAY_CIDR_BLOCK=`curl -s -f --retry 10 http://169.254.169.254/latest/meta-data/network/interfaces/macs/$${INT1_MAC}/subnet-ipv4-cidr-block`
INT1_NETWORK=$${GATEWAY_CIDR_BLOCK%/*}
INT1_GATEWAY=`echo $${INT1_NETWORK} | awk -F. '{ print $1"."$2"."$3"."$4+1 }'`

# Save to file
#echo "MGMT_ADDRESS=$(curl -s -f --retry 10 "http://169.254.169.254/latest/meta-data/local-ipv4")" >> /config/cloud/interface.config
#echo "INT1_ADDRESS=$(curl -s -f --retry 10 "http://169.254.169.254/latest/meta-data/network/interfaces/macs/$${INT1_MAC}/local-ipv4s")" >> /config/cloud/interface.config
echo "INT1_ADDRESS=$(curl -s -f --retry 10 "http://169.254.169.254/latest/meta-data/local-ipv4")" >> /config/cloud/interface.config
echo "INT1_NETWORK=$INT1_NETWORK" >> /config/cloud/interface.config
echo "INT1_MASK=$${GATEWAY_CIDR_BLOCK#*/}" >> /config/cloud/interface.config
echo "INT1_GATEWAY=$INT1_GATEWAY" >> /config/cloud/interface.config
echo "HOSTNAME=$(curl -s -f --retry 10 "http://169.254.169.254/latest/meta-data/hostname")" >> /config/cloud/interface.config
chmod 755 /config/cloud/interface.config
date
echo "Rebooting for NIC swap to complete..."
reboot
EOF

##########################
#### custom-config.sh ####
##########################

# TMSH and DO declarations
cat  <<'EOF' > /config/cloud/custom-config.sh
#!/bin/bash
source /config/cloud/interface.config
source /usr/lib/bigstart/bigip-ready-functions
wait_bigip_ready

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
uSecret='${uSecret}'
mgmtGuiPort="443"

# Workaround: Use TMSH commands for networking
# DO doesn't support "interface" as route target
# https://github.com/F5Networks/f5-declarative-onboarding/issues/147
echo "Set TMM networks"
tmsh+=(
"tmsh modify sys global-settings gui-setup disabled"
"tmsh modify sys global-settings mgmt-dhcp disabled"
"tmsh delete sys management-route all"
"tmsh delete sys management-ip all"
"tmsh create net vlan external interfaces add { 1.0 } mtu 1460"
"tmsh create net self self_external address $${INT1_ADDRESS}/$${INT1_MASK} vlan external allow-service default"
"tmsh create net route default gw $${INT1_GATEWAY}"
"tmsh modify sys dns name-servers add { 10.0.0.2 }"
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
# // Need to update and use AWS Secrets Manager (to do)
#echo "Retrieving BIG-IP password from Metadata secret"
#svcacct_token=$(curl -s -f --retry 10 "http://metadata..." | jq -r ".<filter>")
#passwd=$(curl -s -f --retry 10 "https://secretmanager-metdata.../$uSecret..." -H "Authorization: Bearer $svcacct_token" | jq -r ".<filter>")

# // remove 'f5_password' later, use AWS Secrets Mgr instead
passwd='${f5_password}'

date

# Submit DO Declaration
wait_for_ready declarative-onboarding
file_loc="/config/cloud/do.json"
echo "Submitting DO declaration"
sed -i "s/\$${admin_password}/$passwd/g" $file_loc
sed -i "s/\$${bigIqPassword}/$passwd/g" $file_loc
sed -i "s/\$${local_selfip_ext}/$INT1ADDRESS/g" $file_loc
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

# Cleanup
echo "Removing DO/AS3/TS declaration files"
#rm -rf /config/cloud/do.json /config/cloud/as3.json /config/cloud/ts.json

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
uSecret='${uSecret}'
admin_username='${f5_username}'
DO_URL='${DO_URL}'
DO_FN=$(basename "$DO_URL")
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
#### Swap Mgmt NIC ####
#######################

# Swap management interface to NIC1 (mgmt)
# https://clouddocs.f5.com/cloud/public/v1/shared/change_mgmt_nic_google.html
echo "Waiting for mcpd"
wait_bigip_ready
echo "Change management interface to eth1"
bigstart stop tmm
tmsh modify sys db provision.managementeth value eth1
tmsh modify sys db provision.1nicautoconfig value disable
bigstart start tmm
wait_bigip_ready
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
# // Need to update and use AWS Secrets Manager (to do)
#svcacct_token=$(curl -s -f --retry 10 "http://metadata..." | jq -r ".<filter>")
#admin_password=$(curl -s -f --retry 10 "https://secretmanager-metdata.../$uSecret..." -H "Authorization: Bearer $svcacct_token" | jq -r ".<filter>")

# // remove 'f5_password' later, use AWS Secrets Mgr instead
admin_password='${f5_password}'

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

##########################
#### restjavad memory ####
##########################

# date
# wait_bigip_ready
# # Modify restjavad memory
# echo "Increasing extramb for restjavad"
# tmsh modify sys db provision.extramb value 1000
# tmsh modify sys db restjavad.useextramb value true
# tmsh save sys config
# tmsh restart sys service restjavad
# wait_bigip_ready

##############################################
#### Install F5 Automation Toolchain RPMs ####
##############################################

date
mkdir -p $rpmFilePath

echo "Downloading toolchain RPMs"
curl -L -s -f --retry 20 -o $rpmFilePath/$DO_FN $DO_URL
sleep 10

echo "Installing DO Pkg"
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$DO_FN\"}"
curl -s -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA
sleep 10
echo
echo "Removing temporary RPM install packages"
rm -rf $rpmFilePath/*.rpm

#############################
#### Set and Run Scripts ####
#############################

# https://support.f5.com/csp/article/K11948
echo "(/config/cloud/custom-config.sh | tee /var/log/cloud/custom-config.log >> $LOG_FILE) &" >> /config/startup
chmod +w /config/startup
chmod +x /config/cloud/custom-config.sh
chmod +x /config/cloud/collect-interface.sh

/config/cloud/collect-interface.sh >> $LOG_FILE
# collect-interface.sh ends in 'reboot'
# After reboot, custom-config.sh will run
