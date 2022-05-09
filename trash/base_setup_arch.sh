#!/bin/bash
clear

# visual text settings
RED="\e[31m"
GREEN="\e[32m"
GRAY="\e[37m"
YELLOW="\e[93m"

REDB="\e[41m"
GREENB="\e[42m"
GRAYB="\e[47m"
ENDCOLOR="\e[0m"



echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}This script is not ready to run ----------------------------------------   ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo ""
echo ""
echo "To EXIT this script press  [ENTER]"
echo 
read -p "-" -n 1 -r
echo
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 1
fi

### check if Arch ----
if [[ -e /etc/arch-release ]]; then
      echo -e "/etc/arch-release check = ${GREEN}ok${ENDCOLOR}"
      else
      echo "/etc/arch-release not found! Maybe no ARCH LINUX ?"
      echo -e "${RED}This script is made for ARCH LINUX ${ENDCOLOR}"
      exit 1
fi

#
#--noconfirm later 
#
echo "update and install"
pacman -Syu 
pacman -S ufw fail2ban  unattended-upgrades apt-listchanges

mkdir /root/script_backupfiles/
clear
#
# Password
#
echo "Set root password"
echo "This script creates a random password - use it, or not"
randompasswd=$(</dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 44  ; echo)
echo "Random Password  - mark it once, right mouse klick, enter, and again !"
echo "$randompasswd"
passwd
read -p "Press enter to continue / on fail press CRTL+C"
clear
#
# SSH
#
echo "Set ssh config"
read -p "Choose your SSH Port: (default 22) " -e -i 2222 sshport
ssh-keygen -f /etc/ssh/key1rsa -t rsa -b 4096 -N ""
ssh-keygen -f /etc/ssh/key2ecdsa -t ecdsa -b 521 -N ""
ssh-keygen -f /etc/ssh/key3ed25519 -t ed25519 -N ""

mv /etc/ssh/sshd_config /root/script_backupfiles/sshd_config.orig
echo "Port $sshport
HostKey /etc/ssh/key1rsa
HostKey /etc/ssh/key2ecdsa
HostKey /etc/ssh/key3ed25519
macs hmac-sha2-256,hmac-sha2-512,umac-128@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
PermitRootLogin yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PermitEmptyPasswords no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp  internal-sftp" >> /etc/ssh/sshd_config
clear
#
# Network
#
echo "Set network config"
read -p "Your hostname :" -e -i remotehost hostnamex
hostnamectl set-hostname $hostnamex

#inetiface=
#cp /etc/netctl/examples/ethernet-dhcp /etc/netctl/$inetiface
#nano /etc/netctl/$inetiface

clear
#
# UFW
#
echo "Set ufw config"
ufw default deny incoming
ufw limit $sshport/tcp
clear
#
# fail2ban
#
echo "Set fail2ban for ssh"
echo "
[sshd]
enabled = true
port = $sshport
filter = sshd
logpath = /var/log/auth.log
backend = %(sshd_backend)s
maxretry = 3
banaction = ufw
findtime = 1d
bantime = 18w
" >> /etc/fail2ban/jail.d/ssh.conf
sed -i "/blocktype = reject/c\blocktype = deny" /etc/fail2ban/action.d/ufw.conf
clear


#misc

echo "base_server script installed from :
https://github.com/zzzkeil/base_setups/blob/master/base_setup.sh
" > /root/base_setup.README
clear
#
# END
#
systemctl enable fail2ban.service
read -p "Press enter to reboot"
ufw --force enable
ufw reload
reboot
