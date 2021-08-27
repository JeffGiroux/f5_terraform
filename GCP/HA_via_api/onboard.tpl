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

#####################################
#### cfe.json - Declaration File ####
#####################################

# CFE
cat <<'EOF' > /config/cloud/cfe.json
${CFE_Document}
EOF

#######################
#### mgmt-route.sh ####
#######################

# Add mgmt route after each reboot
# https://support.f5.com/csp/article/K85730674
cat  <<'EOF' > /config/cloud/mgmt-route.sh
#!/bin/bash
source /config/cloud/interface.config
source /usr/lib/bigstart/bigip-ready-functions
# Log File Setup
LOG_FILE="/var/log/cloud/mgmt-route.log"
exec &>>$LOG_FILE
date
echo "Waiting for mcpd"
wait_bigip_ready
date
echo "First try"
tmsh delete sys management-route default
tmsh create sys management-route default gateway $MGMTGATEWAY mtu 1460
sleep 120
echo "Second try"
tmsh delete sys management-route default
tmsh create sys management-route default gateway $MGMTGATEWAY mtu 1460
tmsh save sys config
date
echo "Done"
EOF

##############################
#### collect-interface.sh ####
##############################

# Retrieve Network Metadata from Google
cat  <<'EOF' > /config/cloud/collect-interface.sh
#!/bin/bash
# Collect network information
COMPUTE_BASE_URL="http://metadata.google.internal/computeMetadata/v1"
echo "MGMTADDRESS=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/1/ip" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "MGMTMASK=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/1/subnetmask" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "MGMTGATEWAY=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/1/gateway" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "INT1ADDRESS=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/0/ip" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "INT1MASK=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/0/subnetmask" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "INT1GATEWAY=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/0/gateway" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "INT2ADDRESS=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/2/ip" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "INT2MASK=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/2/subnetmask" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "INT2GATEWAY=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/network-interfaces/2/gateway" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
echo "HOSTNAME=$(curl -s -f --retry 10 "$${COMPUTE_BASE_URL}/instance/hostname" -H 'Metadata-Flavor: Google')" >> /config/cloud/interface.config
chmod 755 /config/cloud/interface.config
date
echo "Rebooting for NIC swap to complete..."
reboot
EOF

##########################
#### custom-config.sh ####
##########################

# TMSH, DO, AS3, TS, CFE declarations
cat  <<'EOF' > /config/cloud/custom-config.sh
#!/bin/bash
source /usr/lib/bigstart/bigip-ready-functions
wait_bigip_ready

source /config/cloud/interface.config
MGMTNETWORK=$(/bin/ipcalc -n $MGMTADDRESS $MGMTMASK | cut -d= -f2)
INT1NETWORK=$(/bin/ipcalc -n $INT1ADDRESS $INT1MASK | cut -d= -f2)
INT2NETWORK=$(/bin/ipcalc -n $INT2ADDRESS $INT2MASK | cut -d= -f2)
echo "MGMTNETWORK=$MGMTNETWORK" >> /config/cloud/interface.config
echo "INT1NETWORK=$INT1NETWORK" >> /config/cloud/interface.config
echo "INT2NETWORK=$INT2NETWORK" >> /config/cloud/interface.config

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
"tmsh create sys management-ip $${MGMTADDRESS}/32"
"tmsh create sys management-route mgmt_gw network $${MGMTGATEWAY}/32 type interface mtu 1460"
"tmsh create sys management-route mgmt_net network $${MGMTNETWORK}/$${MGMTMASK} gateway $${MGMTGATEWAY} mtu 1460"
"tmsh create sys management-route default gateway $${MGMTGATEWAY} mtu 1460"
"tmsh create net vlan external interfaces add { 1.0 } mtu 1460"
"tmsh create net self self_external address $${INT1ADDRESS}/32 vlan external"
"tmsh create net route ext_gw_interface network $${INT1GATEWAY}/32 interface external"
"tmsh create net route ext_rt network $${INT1NETWORK}/$${INT1MASK} gw $${INT1GATEWAY}"
"tmsh create net route default gw $${INT1GATEWAY}"
"tmsh create net vlan internal interfaces add { 1.2 } mtu 1460"
"tmsh create net self self_internal address $${INT2ADDRESS}/32 vlan internal allow-service add { tcp:443 tcp:4353 udp:1026 }"
"tmsh create net route int_gw_interface network $${INT2GATEWAY}/32 interface internal"
"tmsh create net route int_rt network $${INT2NETWORK}/$${INT2MASK} gw $${INT2GATEWAY}"
"tmsh modify sys global-settings remote-host add { metadata.google.internal { hostname metadata.google.internal addr 169.254.169.254 } }"
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
sed -i "s/\$${local_selfip_ext}/$INT1ADDRESS/g" $file_loc
sed -i "s/\$${local_selfip_int}/$INT2ADDRESS/g" $file_loc
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
response_code=$(/usr/bin/curl -sku admin:$passwd -w "%%{http_code}" -X POST -H "Content-Type: application/json" -H "Expect:" https://localhost:$${mgmtGuiPort}/mgmt/shared/appsvcs/declare -d @$file_loc -o /dev/null)
if [[ $response_code == *200 || $response_code == *502 ]]; then
  echo "Deployment of AS3 succeeded"
else
  echo "Failed to deploy AS3; continuing..."
  echo "Response code: $${response_code}"
fi

date

# Submit CFE Declaration
wait_for_ready cloud-failover
file_loc="/config/cloud/cfe.json"
echo "Submitting CFE declaration"
sed -i "s/\$${local_selfip_ext}/$INT1ADDRESS/g" $file_loc
response_code=$(/usr/bin/curl -sku admin:$passwd -w "%%{http_code}" -X POST -H "Content-Type: application/json" -H "Expect:" https://localhost:$${mgmtGuiPort}/mgmt/shared/cloud-failover/declare -d @$file_loc -o /dev/null)
if [[ $response_code == *200 || $response_code == *502 ]]; then
  echo "Deployment of CFE succeeded"
else
  echo "Failed to deploy CFE; continuing..."
  echo "Response code: $${response_code}"
fi

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
echo "Removing DO/AS3/TS/CFE declaration files"
rm -rf /config/cloud/do.json /config/cloud/as3.json /config/cloud/ts.json /config/cloud/cfe.json

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
CFE_URL='${CFE_URL}'
CFE_FN=$(basename "$CFE_URL")
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
# https://cloud.google.com/load-balancing/docs/load-balancing-overview#backend_region_and_network
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
curl -L -s -f --retry 20 -o $rpmFilePath/$TS_FN $TS_URL
curl -L -s -f --retry 20 -o $rpmFilePath/$DO_FN $DO_URL
curl -L -s -f --retry 20 -o $rpmFilePath/$AS3_FN $AS3_URL
curl -L -s -f --retry 20 -o $rpmFilePath/$CFE_FN $CFE_URL
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
echo "Installing CFE Pkg"
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$CFE_FN\"}"
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
chmod +x /config/cloud/mgmt-route.sh
chmod +x /config/cloud/custom-config.sh
chmod +x /config/cloud/collect-interface.sh

/config/cloud/collect-interface.sh >> $LOG_FILE
# collect-interface.sh ends in 'reboot'
# After reboot, custom-config.sh will run
