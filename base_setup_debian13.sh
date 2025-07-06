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
echo -e " ${GRAYB}###${ENDCOLOR}"
echo -e " ${GRAYB}##${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN} Test Version 2025.07.05 - ------   ${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}Base server config for Debian 13 ${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}This script configure / install ${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}password/pubkey , ssh, fail2ban, rsyslog, firawalld, unattended-upgrades ${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}Infos @ https://github.com/zzzkeil/base_setups  ${ENDCOLOR}"
echo -e " ${GRAYB}##${ENDCOLOR}"
echo -e " ${GRAYB}###${ENDCOLOR}"
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
 if [[ "$VERSION_ID" = '13' ]]; then
   echo -e "${GREEN}OS = Debian ${ENDCOLOR}"
   systemos=debian
   fi
fi

if [[ "$ID" = 'ubuntu' ]]; then
 if [[ "$VERSION_ID" = '24.04' ]]; then
   echo -e "${GREEN}OS = Ubuntu ${ENDCOLOR}"
   systemos=ubuntu
   fi
fi


if [[ "$systemos" = '' ]]; then
   clear
   echo ""
   echo ""
   echo -e "${RED}This script is only for Debian 13 and Ubuntu 24.04 !${ENDCOLOR}"
   exit 1
fi


#
# OS updates
#
echo -e "${GREEN}update upgrade and install ${ENDCOLOR}"

if [[ "$systemos" = 'debian' ]]; then
apt-get update && apt-get upgrade -y && apt-get autoremove -y
if [ -f /var/run/reboot-required ]; then
echo "--------------------------------------------------------------------------------------------------------"
echo "--------------------------------------------------------------------------------------------------------"
echo -e " ${RED}Oh dammit :) - System upgrade required a reboot${ENDCOLOR}"
echo -e " ${YELLOW}reboot, and run this script again ${ENDCOLOR}"
echo "--------------------------------------------------------------------------------------------------------"
echo "--------------------------------------------------------------------------------------------------------"
   exit 1
fi
apt-get remove ufw -y
apt-get install firewalld fail2ban rsyslog unattended-upgrades apt-listchanges -y
fi

if [[ "$systemos" = 'ubuntu' ]]; then
apt-get update && apt-get upgrade -y && apt-get autoremove -y
if [ -f /var/run/reboot-required ]; then
echo "--------------------------------------------------------------------------------------------------------"
echo "--------------------------------------------------------------------------------------------------------"
echo -e " ${RED}Oh dammit :) - System upgrade required a reboot${ENDCOLOR}"
echo -e " ${YELLOW}reboot, and run this script again ${ENDCOLOR}"
echo "--------------------------------------------------------------------------------------------------------"
echo "--------------------------------------------------------------------------------------------------------"
   exit 1
fi
apt-get remove ufw needrestart -y
apt-get install firewalld fail2ban rsyslog unattended-upgrades apt-listchanges -y
fi

mkdir /root/script_backupfiles/
clear



##Testing
#
#root Authentication check if Password or Pubkey used in this session and make changes#
#
rootsessioncheck="$(grep root /etc/shadow | cut -c 1-6)"
if [[ "$rootsessioncheck" = 'root:!' ]] || [[ "$rootsessioncheck" = 'root:*' ]]; then
   echo ""
   echo " No root password set, probably you using PubkeyAuthentication in this session !? "
   echo " This sript now set this settings in your sshd_config : "
   echo " AuthenticationMethods publickey"
   echo " PubkeyAuthentication yes"
   echo " PermitRootLogin prohibit-password"
   echo " PasswordAuthentication no"
   echo "" 
   echo -e "${GREEN}Press enter to continue${ENDCOLOR} or ${RED} CTRL + C to abort${ENDCOLOR}"
   echo ""
 
   read -p ""
   
echo -e "${GREEN}Set ssh config  ${ENDCOLOR}"

read -p "Choose your SSH Port: (default 22) " -e -i 2299 sshport
ssh-keygen -f /etc/ssh/key1ecdsa -t ecdsa -b 521 -N ""
ssh-keygen -f /etc/ssh/key2ed25519 -t ed25519 -N ""

mv /etc/ssh/sshd_config /root/script_backupfiles/sshd_config.orig
echo "Port $sshport
HostKey /etc/ssh/key1ecdsa
HostKey /etc/ssh/key2ed25519
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519  
KexAlgorithms curve25519-sha256                                 
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com    
MACs hmac-sha2-512-etm@openssh.com
HostbasedAcceptedKeyTypes ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,ssh-ed25519

PermitRootLogin prohibit-password
PasswordAuthentication no
AuthenticationMethods publickey
PubkeyAuthentication yes
#AuthorizedKeysFile     .ssh/authorized_keys

MaxAuthTries 2
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitEmptyPasswords no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp  internal-sftp 
UseDNS no
Compression no
LoginGraceTime 45
ClientAliveCountMax 1
ClientAliveInterval 1800
IgnoreRhosts yes">> /etc/ssh/sshd_config
   
 else

echo " root password is set - Password login is used in this session "


echo -e " ${GREEN}Set a secure root password ${ENDCOLOR}"

echo ""
echo " This script can create a random secure root password."
echo " If you want to use PubkeyAuthentication, setup this later by yourself"
echo ""
echo ""
echo  -e " ${GRAY}Press any key  -  to ${RED}NOT${ENDCOLOR} change root password ${ENDCOLOR}"
echo ""
echo  -e " ${GRAY}Press [C]  -  to create a secure random root password ${ENDCOLOR}"
read -p "" -n 1 -r
echo ""
echo ""
if [[ ! $REPLY =~ ^[Cc]$ ]]
then
newpass=0
echo " Ok no password change"
echo " Get sure you use a secure password or use PubkeyAuthentication !"
echo ""
echo ""
read -p "Press enter to continue"
else
newpass=1
randompasswd=$(</dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 72  ; echo)
echo "root:$randompasswd" | chpasswd
echo ""
echo ""
echo " Your new root password is : "
echo ""
echo -e "${GREEN}$randompasswd${ENDCOLOR}  <<< copy your new green password "
echo ""
echo -e "${YELLOW} !!! Save this password now !!! ${ENDCOLOR}"
echo " Use your mouse to mark the green password (copy), and paste it on your secure location (other computer/passwordmanager/...) !"
echo ""
echo " if you not save this password, you can never loggin again, be carefull"
echo ""
echo ""
read -p "Press enter to continue"
echo ""
echo " just one more time. "
echo " if you not save this password, you can never loggin again, be carefull"
echo ""
echo ""
read -p "Press enter to continue"
fi

clear

echo -e "${GREEN}Set ssh config  ${ENDCOLOR}"

read -p "Choose your SSH Port: (default 22) " -e -i 2299 sshport
ssh-keygen -f /etc/ssh/key1ecdsa -t ecdsa -b 521 -N ""
ssh-keygen -f /etc/ssh/key2ed25519 -t ed25519 -N ""

mv /etc/ssh/sshd_config /root/script_backupfiles/sshd_config.orig
echo "Port $sshport
HostKey /etc/ssh/key1ecdsa
HostKey /etc/ssh/key2ed25519
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519  
KexAlgorithms curve25519-sha256                                 
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com    
MACs hmac-sha2-512-etm@openssh.com
HostbasedAcceptedKeyTypes ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,ssh-ed25519

PermitRootLogin yes
PasswordAuthentication yes
#PubkeyAuthentication yes

MaxAuthTries 2
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitEmptyPasswords no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp  internal-sftp 
UseDNS no
Compression no
LoginGraceTime 45
ClientAliveCountMax 1
ClientAliveInterval 1800
IgnoreRhosts yes">> /etc/ssh/sshd_config
   
fi

clear

#
# Network
#
echo -e "${GREEN}Set network config  ${ENDCOLOR}"

read -p "Your hostname :" -e -i remotehost hostnamex
hostnamectl set-hostname $hostnamex

#if [ -f "/etc/network/interfaces.d/50-cloud-init.cfg" ]; then
#   nano /etc/network/interfaces.d/50-cloud-init.cfg
#fi

#if [ -f "/etc/NetworkManager/system-connections/cloud-init-eth0.nmconnection" ]; then
#   nano /etc/NetworkManager/system-connections/cloud-init-eth0.nmconnection
#fi

clear

#
# firewalld
#

echo -e "${GREEN}Set firewalld config  ${ENDCOLOR}"

systemctl start firewalld
sleep 1
firewalldstatus="$(systemctl is-active firewalld)"
if [ "${firewalldstatus}" = "active" ]; then
echo "ok firewalld is running"
else 
systemctl restart firewalld  
fi
firewall-cmd --zone=public --remove-service=ssh
firewall-cmd --zone=public --add-port=$sshport/tcp
firewall-cmd --runtime-to-permanent
clear


#
# fail2ban
#
echo -e "${GREEN}Set fail2ban for ssh ${ENDCOLOR}"

echo "
[sshd]
enabled = true
port = $sshport
filter = sshd
logpath = /var/log/auth.log
backend = %(sshd_backend)s
maxretry = 3
banaction = firewallcmd-allports
findtime = 1d
bantime = 18w
" >> /etc/fail2ban/jail.d/ssh.conf


clear

#
# Updates
#
echo -e "${GREEN}unattended-upgrades  ${ENDCOLOR}"

if [[ "$systemos" = 'debian' ]] || [[ "$systemos" = 'ubuntu' ]]; then
mv /etc/apt/apt.conf.d/50unattended-upgrades /root/script_backupfiles/50unattended-upgrades.orig
echo 'Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}";
	"${distro_id}:${distro_codename}-security";
	"${distro_id}ESM:${distro_codename}";
//	"${distro_id}:${distro_codename}-updates";
//	"${distro_id}:${distro_codename}-proposed";
//	"${distro_id}:${distro_codename}-backports";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "01:30";
' >> /etc/apt/apt.conf.d/50unattended-upgrades

echo '
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
' >> /etc/apt/apt.conf.d/20auto-upgrades

nano /etc/apt/apt.conf.d/50unattended-upgrades
nano /etc/apt/apt.conf.d/20auto-upgrades

sed -i "s@6,18:00@9,23:00@" /lib/systemd/system/apt-daily.timer
sed -i "s@12h@1h@" /lib/systemd/system/apt-daily.timer
sed -i "s@6:00@1:00@" /lib/systemd/system/apt-daily-upgrade.timer
fi

clear


#
#misc
#
echo -e "${GREEN}Clear/Change some stuff ${ENDCOLOR}"

if [[ "$systemos" = 'debian' ]] || [[ "$systemos" = 'ubuntu' ]]; thenif [[ "$systemos" = 'debian' ]]; then
echo '#!/bin/sh
runtime1=$(uptime -s)
runtime2=$(uptime -p)
totalban1=$(fail2ban-client status sshd | grep "Currently banned" | sed -e "s/^\s*//" -e "/^$/d")
echo ""
echo "System uptime : $runtime1  / $runtime2 "
echo ""
echo "$totalban1 ip adresses with fail2ban from jail sshd"
echo ""
' >> /etc/update-motd.d/99-base01
chmod +x /etc/update-motd.d/99-base01
dpkg-reconfigure tzdata
fi


echo "base_server script installed from :
https://github.com/zzzkeil/base_setups
" > /root/base_setup.README

#
# END
#

clear


echo ""
echo ""
if [[ "$newpass" -ne 0 ]]; then
echo -e " ${YELLOW}!!! REMEMBER - you set a new root password :"
echo  ""
echo -e "${GREEN}$randompasswd${ENDCOLOR}  <<< copy your new green password "
echo ""
echo -e " ${RED}if you not save this password, you can never loggin again, be carefull ${ENDCOLOR}"
echo ""
echo ""
fi
echo ""
echo "Your settings:"
if [[ "$newpass" = '0' ]]; then
echo ""
echo "Your root password or PubkeyAuthentication has not changed "
fi
echo ""
echo "New ssh port = $sshport / and open in firewalld"
echo ""
echo ""
echo -e "${GREEN}Press enter to reboot  ${ENDCOLOR}"
echo ""
echo ""
read -p ""
systemctl enable fail2ban.service
systemctl enable firewalld
reboot
