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
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${RED} TEST script -- not finished -- just for testing -- high risk to suck        ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${YELLOW}This script will block all traffic from ip´s in the following blocklist   ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${YELLOW}Blocklist URL = https://iplists.firehol.org/files/firehol_level1.netset   ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${YELLOW}Autoupdate list and blocks every 6 hours                                  ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR}                 Version 2022.01.02 - changelog on github                   ${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
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

### root check
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${RED}Sorry, you need to run this as root${ENDCOLOR}"
	exit 1
fi




### create crontabs

(crontab -l ; echo "33 0,6,12,18 * * * cat /root/firehol_level1.netset  | awk '/^[^#]/ { print $1 }' | sudo xargs -I {} ufw delete deny from {}") | sort - | uniq - | crontab -
(crontab -l ; echo "37 0,6,12,18 * * * curl -o /root/firehol_level1.netset https://iplists.firehol.org/files/firehol_level1.netset") | sort - | uniq - | crontab -
(crontab -l ; echo "40 0,6,12,18 * * * cat /root/firehol_level1.netset  | awk '/^[^#]/ { print $1 }' | sudo xargs -I {} ufw deny from {} to any") | sort - | uniq - | crontab -



curl -o /root/firehol_level1.netset https://iplists.firehol.org/files/firehol_level1.netset

cat /root/firehol_level1.netset  | awk '/^[^#]/ { print $1 }' | sudo xargs -I {} ufw deny from {} to any

cat /root/firehol_level1.netset  | awk '/^[^#]/ { print $1 }' | sudo xargs -I {} ufw delete deny from {}


