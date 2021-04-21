#!/bin/bash
repo="$IBM_REPO_URL"
tag="$IBM_TAG"
name=""
watch_tower_image="$IBM_WATCH_TOWER_IMAGE"

which docker
if [ $? -eq 0 ]
then
    docker --version | grep "Docker version"
    if [ $? -eq 0 ]
    then
        echo "Docker installed, proceed."
    else
        echo "Required to install docker"; exit 1
    fi
else
    echo "Required to install docker" >&2
fi
which docker-compose
if [ $? -eq 0 ]
then
    docker-compose --version | grep "docker-compose version"
    if [ $? -eq 0 ]
    then
        echo "Docker-Compose installed, proceed."
    else
        echo "Required to install docker-compose"; exit 1
    fi
else
    echo "Required to install docker-compose" >&2
fi

ServiceVolume="/opt/data"
WatchVolume="/var/run/docker.sock"
SELINUXSTATUS=$(getenforce 2> /dev/null)

WHITEBG=$(tput setab 7)
BLUEFONT=$(tput setaf 4)
NC=

if [ -z $SELINUXSTATUS ];
then
    true
elif [ "$SELINUXSTATUS" == "Permissive" ] || [ "$SELINUXSTATUS" == "Enforcing" ]; then
    ServiceVolume=${ServiceVolume}:Z
    WatchVolume=${WatchVolume}:Z
fi


abspath() {
    cd "$(dirname "$1")"
    printf "%s/%s\n" "$(pwd)" "$(basename "$1")"
    cd "$OLDPWD"
}

dockerstopandremove() {
    cname=$(docker ps -a -q --filter "name=$1")
    if [  ${cname}"" != "" ]; then
        docker stop ${cname}
        docker rm ${cname}
    fi
}

updatecollector() {
   if [ -z "$regcode" ]; then
      printf "${BLUEFONT}${WHITEBG} Enter Collector Registration Key${NC}:"
      read regcode
      echo
   fi
   if [ -e ${confdir}/uuid ]; then
      uuid=$(cat ${confdir}/uuid)
      checkregistered ${uuid}
   else
      register
      echo ${name} > ${confdir}/name
   fi
   echo ${regcode} > ${confdir}/tenant.key
   echo ${volume} > ${confdir}/installpath
   hostname > ${confdir}/hostname
   proxy_register
   crontab -l | grep ${host_address_list} || (crontab -l 2>/dev/null; echo "@reboot bash -c \"ip route get 1 | awk '{print \\\$NF;exit}' > $host_address_list\"") | crontab -
}

register() {
   #Regex based on Docker-Compose standards
   if [ -e ${confdir}/name ]; then
      name=$(cat ${confdir}/name)
   else
      collector_path="internal/v1.0/collector/name"

	  URL=$controller/$collector_path
	  response=$(curl -s -w "%{http_code}" -H "Authorization: ${regcode}" $URL)
	  http_code=$(tail -n1 <<< "$response")  # get the last line
	  status=${http_code: -3}
	  json=${http_code%???}

	  if [[ $status == 200 ]]
      then
         name=`echo $json | sed 's/{.*name":"*\([0-9a-zA-Z_.-]*\)"*,*.*}/\1/'`
	  else
	     msg=`echo $json | sed 's/{.*message":"*\([0-9a-zA-Z ]*\)"*,*.*}/\1/'`
	     echo $msg
         exit 1
	  fi
   fi
}


proxy_register() {
  if [ "$proxy_required" == "y" ]; then
    if [[ -z "$proxy_username" &&  -z "$proxy_password" ]] ; then
       echo "https://${proxy_ip}:${proxy_port}" > ${confdir}/proxy
    else
       echo "https://${proxy_username}:${proxy_password}@${proxy_ip}:${proxy_port}" > ${confdir}/proxy
    fi
  fi
}


checkregistered() {
   regstatusurl="internal/v1.0/collector/details"
   regresponse=`curl -s -X GET -H "Authorization: ${regcode}" $controller/$regstatusurl/$1`
   regstatus=`echo $regresponse | sed 's/{.*status":"*\([0-9a-zA-Z]*\)"*,*.*}/\1/'`
   errorstatus=`echo $regresponse | grep '{.*error":'`
   if [ "$errorstatus" ];then
       echo "Got Error With RegCode !! Aborting !!"
       exit 1
   fi
   if [ "$regstatus" != "ACTIVE" ]; then
      register
   fi
}

dockercomposecreate() {

yamlconf=${confdir}/collector.yaml

# always stop existing collector & restart
if [ -f ${yamlconf} ]; then
    docker-compose -f ${yamlconf} down || true
    rm -f ${yamlconf} || true
fi
dockerstopandremove ${name}
dockerstopandremove watch-${name}

echo "Adding yaml conf: ${yamlconf}"
cat <<EOF >>${yamlconf}
version: '3.3'
services:
  ${name}:
    container_name: ${name}
    image: ${image}
    stdin_open: true
    tty: true
    restart: always
    volumes:
      - ${volume}:${ServiceVolume}
    labels:
      - com.centurylinklabs.watchtower.enable=true
  watch_collectors:
    container_name: watch-collectors
    image: ${watch_tower_image}
    command: --cleanup --label-enable --include-stopped
    restart: always
    volumes:
      - /var/run/docker.sock:${WatchVolume}
EOF


docker-compose -f ${yamlconf} up -d

}

setnetwork() {

if  [ "$iface" != "null" ]; then
   scandir=${volume}/scan
   logsdir=${volume}/logs
   scriptsdir=${volume}/scripts
   mkdir -p ${scandir}
   mkdir -p ${logsdir}
   mkdir -p ${scriptsdir}
   ipaddr=`ip addr show dev "$iface" | grep "inet " | awk '{print \$2}' | cut -d'/' -f 1`
   currentdir=`pwd`
   subnet_info=`ip route | grep "src $ipaddr" | grep "kernel" | awk '{print \$1}'`
   case $scriptsdir in
   /*) scriptpath="${scriptsdir}"
       logdirpath="${logsdir}" ;;
   *)  scriptpath="${currentdir}"/"${scriptsdir}"
       logdirpath="${currentdir}"/"${logsdir}" ;;
   esac
   echo "Retrieved Interface info - IP ${ipaddr} - Subnet $subnet_info"
   echo $subnet_info > ${confdir}/subnet_info
   crontab -l | grep ${scriptpath} || (crontab -l 2>/dev/null; echo "*/5 * * * * sh ${scriptpath}/network_discover.sh -n $subnet_info > ${logdirpath}/current_discovery.log") | crontab -
fi

}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -k|--regcode)
        regcode="$2"
        shift # past argument
        shift # past value
        ;;
    -m|--mount-volume)
        volume="$2"
        shift # past argument
        shift # past value
        ;;
    -e|--interface)
        iface="$2"
        shift # past argument
        shift # past value
        ;;
    -p|--proxy)
        proxy_required="$2"
        shift # past argument
        shift # past value
        ;;
    -h|-?|--help)
        echo "Usage: "
        echo "./start_collector.sh -n <collector name> "
        echo "-k <Registration Code> "
        echo "-m <persistent-volume to mount for config> "
        echo "(optional)"
        echo "-e <interface-name-to-discover>"
        exit 0
        ;;
    *)   # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters
if [ -z "$controller" ]; then
    echo "ERROR: Script does not contain API host URL. If deprecated initiate_collector.sh file used for installation, download latest initiate_collector.sh file and install the collector."
    exit 0
fi
if [ -z "$volume" ]; then
    printf "${BLUEFONT}${WHITEBG} Enter persistent data path from host machine${NC}:"
    read volume
    echo
fi
if [ -z "$iface" ]; then
printf "${BLUEFONT}${WHITEBG} Do you wish to do nmap Validation (y/n)${NC}? "
read yn
case $yn in
   y ) printf "${BLUEFONT}${WHITEBG} Enter Interface to be used for discovery${NC}:"; read iface ;;
   n ) iface="null";;
esac
fi

if [[ "$controller" == *"private"* ]]; then
  if [[ -z "$proxy_required" ]]; then
    printf "${BLUEFONT}${WHITEBG} Do you wish to add proxy (y/n)${NC}? "
    read yn
    proxy_required=$yn
    case $yn in
      y ) printf "${BLUEFONT}${WHITEBG} Enter proxy ipaddress to be used${NC}:"; read proxy_ip ;
          printf "${BLUEFONT}${WHITEBG} Enter the port of proxy server${NC}:"; read proxy_port ;
          printf "${BLUEFONT}${WHITEBG} Enter the proxy username${NC}:"; read proxy_username ;
          printf "${BLUEFONT}${WHITEBG} Enter the proxy password${NC}:"; read -s proxy_password ;
          printf "${BLUEFONT}${WHITEBG}\n";;
      n ) proxy_required="n";;
    esac
  fi
fi

# see if name and regcode are already present in the Volume.
confdir=${volume}/config
mkdir -p ${confdir}
if [ -e ${confdir}/name ]; then
    if [ -z "$name" ]; then
        name=$(cat ${confdir}/name)
    else
        oldname=$(cat ${confdir}/name)
        if [ ${oldname} != ${name} ]; then
            echo "ERROR! the persistent directory ${volume} was already used by container ${oldname}"
            exit 1
        fi
    fi
fi
echo "Using host path: ${volume}"
volume=$(abspath ${volume})
host_address_list=${volume}/config/host_address_list.cfg
if [ ! -f $host_address_list ]; then
  ip route get 1 | awk '{print $NF;exit}' > $host_address_list
fi

echo ${controller} > ${confdir}/controller

image=${repo}:${tag}
echo ${image} > ${confdir}/image

updatecollector
dockercomposecreate
setnetwork
