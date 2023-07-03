#!/bin/bash

# visual text settings
RED="\e[31m"
GREEN="\e[32m"
GRAY="\e[37m"
YELLOW="\e[93m"

REDB="\e[41m"
GREENB="\e[42m"
GRAYB="\e[47m"
ENDCOLOR="\e[0m"

clear
echo -e " ${GRAYB}##################################################################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}Docker config for Debian 12, Ubuntu 22.04, Fedora 38, Rocky Linux 9, CentOS Stream 9, AlmaLinux 9              ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}This script configure / install docker                                                                         ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}Infos @ https://github.com/zzzkeil/base_setups                                                                 ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##################################################################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR}            Version 2023.07.02 -  not a finished script                                                         ${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##################################################################################################################${ENDCOLOR}"
echo ""
echo ""
echo ""
echo  -e "                    ${RED}To EXIT this script press any key${ENDCOLOR}"
echo ""
echo  -e "                            ${GREEN}Press [Y] to begin${ENDCOLOR}"
read -p "" -n 1 -r
echo ""
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

#
#root check
#
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${RED}Sorry, you need to run this as root${ENDCOLOR}"
	exit 1
fi

#
# OS check
#
echo -e "${GREEN}OS check ${ENDCOLOR}"

. /etc/os-release

if [[ "$ID" = 'debian' ]]; then
 if [[ "$VERSION_ID" = '12' ]]; then
   echo -e "${GREEN}OS = Debian ${ENDCOLOR}"
   systemos=debian
   fi
fi

if [[ "$ID" = 'ubuntu' ]]; then
 if [[ "$VERSION_ID" = '22.04' ]]; then
   echo -e "${GREEN}OS = Ubuntu ${ENDCOLOR}"
   systemos=ubuntu
   fi
fi

if [[ "$ID" = 'fedora' ]]; then
 if [[ "$VERSION_ID" = '38' ]]; then
   echo -e "${GREEN}OS = Fedora ${ENDCOLOR}"
   systemos=fedora
   fi
fi


if [[ "$ID" = 'rocky' ]]; then
 if [[ "$ROCKY_SUPPORT_PRODUCT" = 'Rocky-Linux-9' ]]; then
   echo -e "${GREEN}OS = Rocky Linux ${ENDCOLOR}"
   systemos=rocky
 fi
fi


if [[ "$ID" = 'almalinux' ]]; then
 if [[ "$ALMALINUX_MANTISBT_PROJECT" = 'AlmaLinux-9' ]]; then
   echo -e "${GREEN}OS = AlmaLinux ${ENDCOLOR}"
   systemos=almalinux
 fi
fi


if [[ "$ID" = 'centos' ]]; then
 if [[ "$VERSION_ID" = '9' ]]; then
   echo -e "${GREEN}OS = CentOS Stream ${ENDCOLOR}"
   systemos=centos
 fi
fi



if [[ "$systemos" = '' ]]; then
   echo ""
   echo ""
   echo -e "${RED}This script is only for Debian 12, Fedora 38, Rocky Linux 9, CentOS Stream 9 !${ENDCOLOR}"
   exit 1
fi


#
# OS updates
#
echo -e "${GREEN}OS add docker and update upgrade and install ${ENDCOLOR}"

if [[ "$systemos" = 'debian' ]]; then
apt remove ddocker.io docker-doc docker-compose podman-docker containerd runc -y
apt update
apt install lsb-release gnupg2 apt-transport-https ca-certificates curl software-properties-common -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
fi

if [[ "$systemos" = 'ubuntu' ]]; then
apt remove docker.io docker-doc docker-compose podman-docker containerd runc -y
apt update
apt install lsb-release gnupg2 apt-transport-https ca-certificates curl software-properties-common -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
fi



if [[ "$systemos" = 'fedora' ]]; then
dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine -y
dnf install dnf-plugins-core -y
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
systemctl enable docker.service
systemctl enable containerd.service
systemctl start docker.service
systemctl start containerd.service

fi

##maybe the same as fedora ??......
if [[ "$systemos" = 'rocky' ]] || [[ "$systemos" = 'centos' ]] || [[ "$systemos" = 'almalinux' ]]; then
dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine -y
dnf install dnf-plugins-core -y
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
systemctl enable docker.service
systemctl enable containerd.service
systemctl start docker.service
systemctl start containerd.service

fi

################## docker and firewallrules ...... so many ways .....
inet=$(ip route show default | awk '/default/ {print $5}')


#firewalld below from : https://dev.to/soerenmetje/how-to-secure-a-docker-host-using-firewalld-2joo
#systemctl stop docker
#echo '
#{
#"iptables": false
#}
#' >> /etc/docker/daemon.json
#firewall-cmd --zone=public --add-masquerade --permanent
#firewall-cmd --permanent --zone=trusted --add-interface=docker0
#firewall-cmd --permanent --zone=public --add-interface=$inet
#firewall-cmd --reload
#systemctl restart docker
#echo " 
#You have to allow your firewalld ports for docker manual, like...
#firewall-cmd --permanent --zone=public --add-port=0000/tcp
#"


#firewalld below from : captainhook
# 1. Stop Docker
#systemctl stop docker.socket
#systemctl stop docker.service

# 2. Recreate DOCKER-USER iptables chain with firewalld. Ignore warnings, do not ignore errors
#firewall-cmd --permanent --direct --remove-chain ipv4 filter DOCKER-USER
#firewall-cmd --permanent --direct --remove-rules ipv4 filter DOCKER-USER
#firewall-cmd --permanent --direct --add-chain ipv4 filter DOCKER-USER

# 3. Add iptables rules to DOCKER-USER chain - unrestricted outbound, restricted inbound to private IPs
#firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT -m comment --comment 'Allow containers to connect to the outside world'
#firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 -j RETURN -s 127.0.0.0/8 -m comment --comment 'allow internal docker communication, loopback addresses'
#firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 -j RETURN -s 172.16.0.0/12 -m comment --comment 'allow internal docker communication, private range'

# 3.1 optional: for wider internal networks
#firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 -j RETURN -s 10.0.0.0/8 -m comment --comment 'allow internal docker communication, private range'
#firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 -j RETURN -s 192.168.0.0/16 -m comment --comment 'allow internal docker communication, private range'

# 4. Block all other IPs. This rule has lowest precedence, so you can add rules before this one later.
#firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 10 -j REJECT -m comment --comment 'reject all other traffic to DOCKER-USER'

# 5. Activate rules
#firewall-cmd --reload

# 6. Start Docker
#systemctl start docker.socket
#systemctl start docker.service


############################################################## more to come :)
