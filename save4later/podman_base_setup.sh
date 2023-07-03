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
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}This script configure / install podman                                                                         ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
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
apt install podman libapparmor-dev -y
fi

if [[ "$systemos" = 'ubuntu' ]]; then
apt install podman libapparmor-dev -y
fi

if [[ "$systemos" = 'fedora' ]]; then
dnf install podman -y
fi
##maybe the same as fedora ??......
if [[ "$systemos" = 'rocky' ]] || [[ "$systemos" = 'centos' ]] || [[ "$systemos" = 'almalinux' ]]; then
dnf install podman -y
fi

##################  and firewallrules
#inet=$(ip route show default | awk '/default/ {print $5}')




############################################################## more to come :)
