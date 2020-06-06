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

startTime=$(date +%s)
echo "timestamp start: $(date)"
function timer () {
    echo "Time Elapsed: $(( ${1} / 3600 ))h $(( (${1} / 60) % 60 ))m $(( ${1} % 60 ))s"
}
waitMcpd () {
checks=0
while [[ "$checks" -lt 120 ]]; do 
    tmsh -a show sys mcp-state field-fmt | grep -q running
   if [ $? == 0 ]; then
       echo "mcpd ready"
       break
   fi
   echo "mcpd not ready yet"
   let checks=checks+1
   sleep 10
done
}

#swap management interface for glb target group
echo "change management interface to eth1"
waitMcpd
bigstart stop tmm
tmsh modify sys db provision.managementeth value eth1
#https://clouddocs.f5.com/cloud/public/v1/google/Google_routes.html
tmsh modify sys db provision.1nicautoconfig value disable
bigstart start tmm
waitMcpd
echo "---mgmt interface setting----"
tmsh list sys db provision.managementeth
tmsh list sys db provision.1nicautoconfig
# modify asm interface
cp /etc/ts/common/image.cfg /etc/ts/common/image.cfg.bak
sed -i "s/iface0=eth0/iface0=eth1/g" /etc/ts/common/image.cfg
echo "---done changing interface----"
# end management swap

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


# get device id for do
deviceId=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/attributes/deviceId' -H 'Metadata-Flavor: Google')

echo  "wait for mcpd"
checks=0
while [[ "$checks" -lt 120 ]]; do 
    echo "checking mcpd"
    tmsh -a show sys mcp-state field-fmt | grep -q running
   if [ $? == 0 ]; then
       echo "mcpd ready"
       break
   fi
   echo "mcpd not ready yet"
   let checks=checks+1
   sleep 10
done 

function delay () {
# $1 count #2 item
count=0
while [[ $count  -lt $1 ]]; do 
    echo "still working... $2"
    sleep 1
    count=$[$count+1]
done
}

# create admin account and password
echo "create admin account"
admin_username='${uname}'
admin_password='${upassword}'
tmsh create auth user $admin_username password "$admin_password" shell bash partition-access add { all-partitions { role admin } };
tmsh list auth user $admin_username
# copy ssh key
mkdir -p /home/$admin_username/.ssh/
cp /home/admin/.ssh/authorized_keys /home/$admin_username/.ssh/authorized_keys
echo " admin account changed"
# end admin account and password

# start modify appdata directory size
echo "setting app directory size"
tmsh show sys disk directory /appdata
# 130,985,984 26,128,384 52,256,768
tmsh modify /sys disk directory /appdata new-size 52256768
tmsh show sys disk directory /appdata
echo "done setting app directory size"
# end modify appdata directory size

# save sys config
tmsh save sys config

# Variables
CREDS="$admin_username:$admin_password"
# constants
local_host="http://localhost:8100"
mgmt_port=`tmsh list sys httpd ssl-port | grep ssl-port | sed 's/ssl-port //;s/ //g'`
authUrl="/mgmt/shared/authn/login"
rpmInstallUrl="/mgmt/shared/iapp/package-management-tasks"
rpmFilePath="/var/config/rest/downloads"
# do
doUrl="/mgmt/shared/declarative-onboarding"
doCheckUrl="/mgmt/shared/declarative-onboarding/info"
doTaskUrl="/mgmt/shared/declarative-onboarding/task"
# as3
as3Url="/mgmt/shared/appsvcs/declare"
as3CheckUrl="/mgmt/shared/appsvcs/info"
as3TaskUrl="/mgmt/shared/appsvcs/task"
# ts
tsUrl="/mgmt/shared/telemetry/declare"
tsCheckUrl="/mgmt/shared/telemetry/info" 
# cloud failover ext
cfUrl="/mgmt/shared/cloud-failover/declare"
cfCheckUrl="/mgmt/shared/cloud-failover/info"
# F5 application services templates (FAST)
fastCheckUrl="/mgmt/shared/fast/info"

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

###############################################
#### Download F5 Automation Toolchain RPMs ####
###############################################

# download latest atc tools
toolsList=$(cat -<<EOF
{
  "tools": [
      {
        "name": "f5-declarative-onboarding",
        "version": "${doVersion}"
      },
      {
        "name": "f5-appsvcs-extension",
        "version": "${as3Version}"
      },
      {
        "name": "f5-telemetry-streaming",
        "version": "${tsVersion}"
      },
      {
        "name": "f5-cloud-failover-extension",
        "version": "${cfVersion}"
      },
      {
        "name": "f5-appsvcs-templates",
        "version": "${fastVersion}"
      }
  ]
}
EOF
)
function getAtc () {
atc=$(echo $toolsList | jq -r .tools[].name)
for tool in $atc
do
    version=$(echo $toolsList | jq -r ".tools[]| select(.name| contains (\"$tool\")).version")
    if [ $version == "latest" ]; then
        path=''
    else
        path='tags/v'
    fi
    echo "downloading $tool, $version"
    #if [[ $tool == "f5-cloud-failover-extension" || $tool == "f5-appsvcs-templates" ]]; then
    if [ $tool == "f5-new-tool" ]; then
        files=$(/usr/bin/curl -sk --interface mgmt https://api.github.com/repos/f5devcentral/$tool/releases/$path$version | jq -r '.assets[] | select(.name | contains (".rpm")) | .browser_download_url')
    else
        files=$(/usr/bin/curl -sk --interface mgmt https://api.github.com/repos/F5Networks/$tool/releases/$path$version | jq -r '.assets[] | select(.name | contains (".rpm")) | .browser_download_url')
    fi
    for file in $files
    do
    echo "download: $file"
    name=$(basename $file )
    # make download dir
    mkdir -p /var/config/rest/downloads
    result=$(/usr/bin/curl -Lsk  $file -o /var/config/rest/downloads/$name)
    done
done
}
getAtc

# install atc tools
# install atc tools
rpms=$(find $rpmFilePath -name "*.rpm" -type f)
for rpm in $rpms
do
  filename=$(basename $rpm)
  echo "installing $filename"
  if [ -f $rpmFilePath/$filename ]; then
     postBody="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$filename\"}"
     while true
     do
        iappApiStatus=$(curl -i -u "$CREDS"  $local_host$rpmInstallUrl | grep HTTP | awk '{print $2}')
        case $iappApiStatus in 
            404)
                echo "api not ready status: $iappApiStatus"
                sleep 2
                ;;
            200)
                echo "api ready starting install task $filename"
                install=$(restcurl -u "$CREDS" -X POST -d $postBody $rpmInstallUrl | jq -r .id )
                break
                ;;
              *)
                echo "other error status: $iappApiStatus"
                debug=$(restcurl -u "$CREDS" $rpmInstallUrl)
                echo "ipp install debug: $debug"
                ;;
        esac
    done
  else
    echo " file: $filename not found"
  fi 
  while true
  do
    status=$(restcurl -u "$CREDS" $rpmInstallUrl/$install | jq -r .status)
    case $status in 
        FINISHED)
            # finished
            echo " rpm: $filename task: $install status: $status"
            break
            ;;
        STARTED)
            # started
            echo " rpm: $filename task: $install status: $status"
            ;;
        RUNNING)
            # running
            echo " rpm: $filename task: $install status: $status"
            ;;
        FAILED)
            # failed
            error=$(restcurl -u "$CREDS" $rpmInstallUrl/$install | jq .errorMessage)
            echo "failed $filename task: $install error: $error"
            break
            ;;
        *)
            # other
            debug=$(restcurl -u "$CREDS" $rpmInstallUrl/$install | jq . )
            echo "failed $filename task: $install error: $debug"
            ;;
        esac
    sleep 2
    done
done

function checkDO() {
    # Check DO Ready
    # Check DO Ready
    count=0
    while [ $count -le 4 ]
    do
    doStatusType=$(restcurl -u "$CREDS" -X GET $doCheckUrl | jq -r type )
    if [ "$doStatusType" == "object" ]; then
        doStatus=$(restcurl -u "$CREDS" -X GET $doCheckUrl | jq -r .code)
        if [ $? == 1 ]; then
            doStatus=$(restcurl -u "$CREDS" -X GET $doCheckUrl | jq -r .result.code)
        fi
    elif [ "$doStatusType" == "array" ]; then
        doStatus=$(restcurl -u "$CREDS" -X GET $doCheckUrl | jq -r .[].result.code)
    else
        echo "unknown type:$doStatusType"
    fi
    echo "status $doStatus"
    if [[ $doStatus == "200" ]]; then
        version=$(restcurl -u "$CREDS" -X GET $doCheckUrl | jq -r .[].version)
        echo "Declarative Onboarding $version online "
        break
    elif [[ $doStatus == "404" ]]; then
        echo "DO Status: $doStatus"
        bigstart restart restnoded
        sleep 60
        bigstart status restnoded | grep running
        status=$?
        echo "restnoded:$status"
    else
        echo "DO Status $doStatus"
        count=$[$count+1]
    fi
    sleep 10
    done
}
function checkAS3() {
    # Check AS3 Ready
    # Check AS3 Ready
    count=0
    while [ $count -le 4 ]
    do
    as3Status=$(restcurl -u "$CREDS" -X GET $as3CheckUrl | jq -r .code)
    if  [ "$as3Status" == "null" ] || [ -z "$as3Status" ]; then
        type=$(restcurl -u "$CREDS" -X GET $as3CheckUrl | jq -r type )
        if [ "$type" == "object" ]; then
            as3Status="200"
        fi
    fi
    if [[ $as3Status == "200" ]]; then
        version=$(restcurl -u "$CREDS" -X GET $as3CheckUrl | jq -r .version)
        echo "As3 $version online "
        break
    elif [[ $as3Status == "404" ]]; then
        echo "AS3 Status $as3Status"
        bigstart restart restnoded
        sleep 60
        bigstart status restnoded | grep running
        status=$?
        echo "restnoded:$status"
    else
        echo "AS3 Status $as3Status"
        count=$[$count+1]
    fi
    sleep 10
    done
}
function checkTS() {
    # Check TS Ready
    # Check TS Ready
    count=0
    while [ $count -le 4 ]
    do
    tsStatus=$(curl -si -u "$CREDS" $local_host$tsCheckUrl | grep HTTP | awk '{print $2}')
    if [[ $tsStatus == "200" ]]; then
        version=$(restcurl -u "$CREDS" -X GET $tsCheckUrl | jq -r .version)
        echo "Telemetry Streaming $version online "
        break
    else
        echo "TS Status $tsStatus"
        count=$[$count+1]
    fi
    sleep 10
    done
}
function checkCF() {
    # Check CF Ready
    # Check CF Ready
    count=0
    while [ $count -le 4 ]
    do
    cfStatus=$(curl -si -u "$CREDS" $local_host$cfCheckUrl | grep HTTP | awk '{print $2}')
    if [[ $cfStatus == "200" ]]; then
        version=$(restcurl -u "$CREDS" -X GET $cfCheckUrl | jq -r .version)
        echo "Cloud failover $version online "
        break
    else
        echo "Cloud Failover Status $cfStatus"
        count=$[$count+1]
    fi
    sleep 10
    done
}
function checkFAST() {
    # Check FAST Ready
    # Check FAST Ready
    count=0
    while [ $count -le 4 ]
    do
    fastStatus=$(curl -si -u "$CREDS" $local_host$fastCheckUrl | grep HTTP | awk '{print $2}')
    if [[ $fastStatus == "200" ]]; then
        version=$(restcurl -u "$CREDS" -X GET $fastCheckUrl | jq -r .version)
        echo "FAST $version online "
        break
    else
        echo "FAST Status $fastStatus"
        count=$[$count+1]
    fi
    sleep 10
    done
}
### check for apis online 
function checkATC() {
    doStatus=$(checkDO)
    as3Status=$(checkAS3)
    tsStatus=$(checkTS)
    cfStatus=$(checkCF)
    fastStatus=$(checkFAST)
    if [[ $doStatus == *"online"* ]] && [[ "$as3Status" = *"online"* ]] && [[ $tsStatus == *"online"* ]] && [[ $cfStatus == *"online"* ]] && [[ $fastStatus == *"online"* ]] ; then 
        echo "ATC is ready to accept API calls"
    else
        echo "ATC install failed or ATC is not ready to accept API calls"
        break
    fi   
}
checkATC
#
# start network
# start network
MGMTADDRESS=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/ip' -H 'Metadata-Flavor: Google')
MGMTMASK=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/subnetmask' -H 'Metadata-Flavor: Google')
MGMTGATEWAY=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/gateway' -H 'Metadata-Flavor: Google')

INT2ADDRESS=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip' -H 'Metadata-Flavor: Google')
INT2MASK=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/subnetmask' -H 'Metadata-Flavor: Google')
INT2GATEWAY=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/gateway' -H 'Metadata-Flavor: Google')

INT3ADDRESS=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/2/ip' -H 'Metadata-Flavor: Google')
INT3MASK=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/2/subnetmask' -H 'Metadata-Flavor: Google')
INT3GATEWAY=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/2/gateway' -H 'Metadata-Flavor: Google')

MGMTNETWORK=$(/bin/ipcalc -n $MGMTADDRESS $MGMTMASK | cut -d= -f2)
INT2NETWORK=$(/bin/ipcalc -n $INT2ADDRESS $INT2MASK | cut -d= -f2)
INT3NETWORK=$(/bin/ipcalc -n $INT3ADDRESS $INT3MASK | cut -d= -f2)

# network data
echo " mgmt:$MGMTADDRESS,$MGMTMASK,$MGMTGATEWAY"
echo "external:$INT2ADDRESS,$INT2MASK,$INT2GATEWAY"
echo "internal: $INT3ADDRESS,$INT3MASK,$INT3GATEWAY"
echo "cidr: $MGMTNETWORK,$INT2NETWORK,$INT3NETWORK"

# mgmt reboot workaround
#https://support.f5.com/csp/article/K11948
#https://support.f5.com/csp/article/K47835034
chmod +w /config/startup
echo "/config/startup_script_sol11948.sh &" >> /config/startup
echo "/config/startup_script_atc.sh &" >> /config/startup
# cat  <<EOF > /config/startup_script_sol11948.sh
# #!/bin/bash
# exec &>>/var/log/mgmt-startup-script.log
# . /config/startup_script_sol11948.sh
# done
# EOF
#chmod +x /config/startup_script_sol11948.sh
cat  <<EOF > /config/startup_script_sol11948.sh
#!/bin/bash
exec &>>/var/log/mgmt-startup-script.log
echo  "wait for mcpd"
sleep 120
echo  "first try"
tmsh delete sys management-route default
tmsh create sys management-route default gateway $MGMTGATEWAY mtu 1460
sleep 120
echo  "2nd try"
tmsh delete sys management-route default
tmsh create sys management-route default gateway $MGMTGATEWAY mtu 1460
tmsh save sys config
echo "done"
EOF
chmod +x /config/startup_script_sol11948.sh
# end management reboot workaround
#
# reboot and run the rest of the setup
#
cat  <<EOF > /config/startup_script_atc.sh
# logging
LOG_FILE="/var/log/startup-atc-script.log"
if [ ! -e \$LOG_FILE ]
then
     touch \$LOG_FILE
     exec &>>\$LOG_FILE
else
    #if file exists, exit as only want to run once
    echo "already run exiting"
    exit
fi

exec 1>\$LOG_FILE 2>&1
checks=0
while [[ "\$checks" -lt 120 ]]; do 
    tmsh -a show sys mcp-state field-fmt | grep -q running
   if [ \$? == 0 ]; then
       echo "mcpd ready"
       break
   fi
   echo "mcpd not ready yet"
   let checks=checks+1
   sleep 10
done
# functions
# wait for mcpd to be ready
waitMcpd () {
checks=0
while [[ "\$checks" -lt 120 ]]; do 
    tmsh -a show sys mcp-state field-fmt | grep -q running
   if [ \$? == 0 ]; then
       echo "mcpd ready"
       break
   fi
   echo "mcpd not ready yet count: \$checks"
   let checks=checks+1
   sleep 10
done
}
waitMcpd

echo "disable gui setup"
tmsh modify sys global-settings gui-setup disabled

echo "set tmm networks"
echo  -e "create cli transaction;
create net vlan external interfaces add { 1.0 } mtu 1460;
create net self external-self address $INT2ADDRESS/32 vlan external;
create net route ext_gw_interface network $INT2GATEWAY/32 interface external;
create net route ext_rt network $INT2NETWORK/$INT2MASK gw $INT2GATEWAY;
create net route default gw $INT2GATEWAY;
submit cli transaction" | tmsh -q
tmsh save sys config
echo "timestamp end: \$(date)"
echo "====setup complete===="

# Delete RPM packages
echo "removing temporary RPM install packages"
rm -rf /var/config/rest/downloads/*.rpm

exit
EOF
chmod +x /config/startup_script_atc.sh
echo "rebooting for nic swap to complete"
reboot
