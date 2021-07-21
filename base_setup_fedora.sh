#!/bin/bash
clear
echo " ###############################################################"
echo " #     Try to convert this script from debian based to ferora  #"
echo " #            passwd,ssh,fail2ban,ufw,network,updates          #"
echo " #            !!!!!!!!!!   not finished  !!!!!!!!!!!          #"
echo " ###############################################################"
echo ""
echo ""
echo "              To EXIT this script press  [ENTER]"
echo 
read -p "" -n 1 -r
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

### OS version check
if [[ -e /etc/fedora-release ]]; then
      echo "fedora distribution"
      else
      echo "This is not a fedora distribution."
      exit 1
fi

#
# APT
#
echo "system update and install"
#apt update && apt upgrade -y && apt autoremove -y
#apt install ufw fail2ban  unattended-upgrades apt-listchanges -y 
dnf check-update && dnf -y update 

dnf -y install nano ufw fail2ban dnf-automatic

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
#if [ -f "/etc/netplan/50-cloud-init.yaml" ]; then
#    nano /etc/netplan/50-cloud-init.yaml
#fi
#if [ -f "/etc/network/interfaces.d/50-cloud-init.cfg" ]; then
#   nano /etc/network/interfaces.d/50-cloud-init.cfg
#fi


# Baustelle

#interfacewww=
#nano /etc/sysconfig/network-scripts/ifcfg-$interfacewww

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
#
# Updates
#
#echo "unattended-upgrades"
#mv /etc/dnf/automatic.conf /root/script_backupfiles/automatic.conf.orig
#echo '

# Baustelle

#' >> /etc/dnf/automatic.conf

#nano /etc/dnf/automatic.conf


#sed -i "s@6,18:00@9,23:00@" /lib/systemd/system/apt-daily.timer
#sed -i "s@12h@1h@" /lib/systemd/system/apt-daily.timer
#sed -i "s@6:00@1:00@" /lib/systemd/system/apt-daily-upgrade.timer
clear
#
#misc
#
#echo "Clear/Change some stuff"
#chmod -x /etc/update-motd.d/10-help-text
#chmod -x /etc/update-motd.d/50-motd-news
#chmod -x /etc/update-motd.d/80-livepatch

#echo '#!/bin/sh
#runtime1=$(uptime -s)
#runtime2=$(uptime -p)
#totalban1=$(zgrep 'Ban' /var/log/fail2ban.log* | wc -l)
#echo "System uptime : $runtime1  / $runtime2 "
#echo ""
#echo "Total banned IPs from fail2ban : $totalban1 "
#' >> /etc/update-motd.d/99-base01
#chmod +x /etc/update-motd.d/99-base01

echo "base_server script installed from :
https://github.com/zzzkeil/base_setups/blob/master/base_setup_fedora.sh
" > /root/base_setup.README
clear
#
# END
#
systemctl enable --now fail2ban.service
systemctl enable --now ufw.service
ufw reload
echo ""
read -p "Press enter to reboot"
reboot
