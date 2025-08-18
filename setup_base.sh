#!/bin/bash

msghi="This 'basescript' configure/prepare your server to use my other setupscripts,\n
like wireguard with pihole and dnscrypt, nextcloud behind wireguard, ...\n
Base serverconfig for Debian 13 and Ubuntu 24.04 only\n
This script installs and configure\n
root password/pubkey, ssh, fail2ban, rsyslog, firawalld, unattended-upgrades\n
Infos @ https://github.com/zzzkeil/base_setups\n
Version 2025.08.18\n\n
Run script now ?"

if whiptail --title "Hi, lets start" --yesno "$msghi" 20 90; then
echo ""
else
whiptail --title "Aborted" --msgbox "Ok, no install right now. Have a nice day." 15 80
exit 1
fi   

### root check
if [[ "$EUID" -ne 0 ]]; then
whiptail --title "Aborted" --msgbox "Sorry, you need to run this as root!" 15 80
exit 1
fi


### OS check
. /etc/os-release
if [[ "$ID" = 'debian' ]]; then
 if [[ "$VERSION_ID" = '13' ]]; then
 systemos=debian
 fi
fi

if [[ "$ID" = 'ubuntu' ]]; then
 if [[ "$VERSION_ID" = '24.04' ]]; then
 systemos=ubuntu
 fi
fi

if [[ "$systemos" = '' ]]; then
whiptail --title "Aborted" --msgbox "This script is only for Debian 13 and Ubuntu 24.04 !" 15 80
exit 1
fi

### Architecture check for dnsscrpt 
ARCH=$(uname -m)
if [[ "$ARCH" == x86_64* ]]; then
  dnsscrpt_arch=x86_64
elif [[ "$ARCH" == aarch64* ]]; then
  dnsscrpt_arch=arm64
else
whiptail --title "Aborted" --msgbox "This script is only for x86_64 or ARM64  Architecture !" 15 80
exit 1
fi

#
# OS updates
#
echo 'Dpkg::Progress-Fancy "1";' | sudo tee /etc/apt/apt.conf.d/99progressbar

if [[ "$systemos" = 'ubuntu' ]]; then
systemctl stop snapd
systemctl disable snapd
systemctl disable snapd.socket
systemctl disable snapd.seeded.service
apt-get remove --purge --assume-yes snapd
rm -rf /var/cache/snapd/
rm -rf ~/snap/
fi

##
apt-get remove ufw needrestart -y
##

update_upgrade_with_gauge() {
    {
        echo 10
        echo "Starting apt-get update..."
        apt-get update -y &> /dev/null
        if [ $? -ne 0 ]; then
            echo 100
            echo "Error: apt-get update failed."
            exit 1
        fi

        echo 50
        echo "Starting apt-get upgrade..."
        apt-get upgrade -y &> /dev/null
        if [ $? -ne 0 ]; then
            echo 100
            echo "Error: apt-get upgrade failed."
            exit 1
        fi

        echo 100
        echo "Update and Upgrade completed successfully."
    } | whiptail --title "System Update and Upgrade" --gauge "Please wait while updating and upgrading the system..." 15 80 0

    if [ $? -eq 0 ]; then
       echo ""
    else
        whiptail --title "Error" --msgbox "The update/upgrade process was interrupted." 15 80
    fi
}

update_upgrade_with_gauge

if [ -f /var/run/reboot-required ]; then
whiptail --title "reboot-required" --msgbox "Oh dammit :) - System upgrade required a reboot!\nreboot, and run this script again" 15 80
exit 1
fi


packages1=("firewalld" "fail2ban" "rsyslog" "unattended-upgrades" "apt-listchanges")

install_multiple_packages_with_gauge1() {
    total=${#packages1[@]}
    step=0

    {
        for pkg in "${packages1[@]}"; do
            percent=$(( (step * 100) / total ))
            echo $percent
            echo "Installing package: $pkg..."
            sudo apt-get install -y "$pkg" &> /dev/null
            if [ $? -ne 0 ]; then
                echo 100
                echo "Error: Installation of package $pkg failed."
                exit 1
            fi
            step=$((step + 1))
        done
        echo 100
        echo "All packages installed successfully."
    } | whiptail --title "Installing needed OS Packages" --gauge "Please wait while installing packages...\nfirewalld, fail2ban, rsyslog, unattended-upgrades, apt-listchanges" 15 90 0

    if [ $? -eq 0 ]; then
        echo ""
    else
        whiptail --title "Error" --msgbox "Installation process interrupted or failed." 15 80
		exit 1
    fi
}

install_multiple_packages_with_gauge1


mkdir /root/script_backupfiles/
mv /etc/ssh/sshd_config /root/script_backupfiles/sshd_config.orig
clear

is_valid_port() {
    local ssh0port="$1"
    if [[ "$ssh0port" =~ ^[0-9]+$ ]] && [ "$ssh0port" -ge 0 ] && [ "$ssh0port" -le 65535 ] && [ "$ssh0port" -ne 5335 ]; then
        return 0
    else
        return 1
    fi
}

while true; do
    sshport=$(whiptail --title "SSH Port Settings" --inputbox "It can be usefull to change the default SSH Port\nIf you like to use the default, take 22\nor use a free port from 1-65535\n- Do not use port 5335\n- Do not use a used port!\n- To list all currently activ ports, cancel now and you see a list\nThen start this script again" 15 80 "22" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then
        if is_valid_port "$sshport"; then
            break
        else
            whiptail --title "Invalid Port" --msgbox "Invalid port number. Please enter a port number between 1 and 65535. Do not use port 5335" 15 80
        fi
    else
	whiptail --title "Aborted" --msgbox "Ok, cancel. No changes to system was made.\n" 15 80
    clear
	echo "Here is your list of currently open ports:"
	ss -tuln | awk '{print $5}' | cut -d':' -f2 | sort -n | uniq
    echo ""
    echo "Now run the script again, and aviod useing a port from above"
	echo ""
    echo ""
    exit 1
    fi
done

ssh-keygen -f /etc/ssh/key1ecdsa -t ecdsa -b 521 -N ""
ssh-keygen -f /etc/ssh/key2ed25519 -t ed25519 -N ""
clear
#
#root Authentication check if Password or Pubkey used in this session and make changes#
#
rootsessioncheck="$(grep root /etc/shadow | cut -c 1-6)"
if [[ "$rootsessioncheck" = 'root:!' ]] || [[ "$rootsessioncheck" = 'root:*' ]]; then
msgroot1="No root password set in /etc/shadow\n
You probably using PubkeyAuthentication already !?\n
Add some settings to your sshd_config like :\n
Port $sshport\n
AuthenticationMethods publickey\n
PubkeyAuthentication yes\n
PermitRootLogin prohibit-password\n
PasswordAuthentication no\n
and more....\n
Is this right ?"
 if whiptail --title "Pubkey Authentication" --yesno "$msgroot1" 25 80; then
 echo ""
 else
 whiptail --title "Aborted" --msgbox "Ok, no install right now. cu have a nice day." 15 80
 exit 1
 fi   

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

msgroot2="Secure root password\n
Yes, to create a new secure random root password,\n
No,  DO NOT change your current root password.\n\n
If you want to use PubkeyAuthentication, setup this later by yourself\n
"
if whiptail --title "Set a secure root password" --yesno "$msgroot2" 15 80; then
newpass=1
randompasswd=$(</dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 72  ; echo)
echo "root:$randompasswd" | chpasswd
whiptail --title "root password change" --msgbox "Your new root password is :\n\n$randompasswd\n\nCopy and save your new root password now!!! (other computer/passwordmanager/...)\n" 15 99
whiptail --title "Just one more time" --msgbox "Saved your new password ???\n\n$randompasswd\n\nIf you not saved this password, you can never loggin again, be carefull!!!\n" 15 99
else
whiptail --title "no password change" --msgbox "Ok, no password change\nLets hope it is secure :)" 15 80
newpass=0
fi

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

#
# Network
#
#echo -e "${GREEN}Set network config  ${ENDCOLOR}"

#read -p "Your hostname :" -e -i remotehost hostnamex
#hostnamectl set-hostname $hostnamex

#if [ -f "/etc/network/interfaces.d/50-cloud-init.cfg" ]; then
#   nano /etc/network/interfaces.d/50-cloud-init.cfg
#fi

#if [ -f "/etc/NetworkManager/system-connections/cloud-init-eth0.nmconnection" ]; then
#   nano /etc/NetworkManager/system-connections/cloud-init-eth0.nmconnection
#fi


#
# firewalld
#
whiptail --title "INFO: firewalld" --msgbox "Next step, set firewalld config\n" 15 80
systemctl start firewalld
sleep 1
firewalldstatus="$(systemctl is-active firewalld)"
if [ "${firewalldstatus}" = "active" ]; then
echo ""
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
whiptail --title "INFO: fail2ban" --msgbox "Next step, set fail2ban config " 15 80
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

#
# Updates
#
whiptail --title "INFO: upgrades" --msgbox "Next step, set unattended-upgrades config\nYou will see 2 nano screens now\n- Press ctrl - x  for defaults\nor\n- Change things and press ctrl - x and ctrl - y and enter" 15 80

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


clear


#
#misc
#
echo '#!/bin/sh
runtime1=$(uptime -s)
runtime2=$(uptime -p)
totalban1=$(fail2ban-client status sshd | grep "Currently banned" | sed -e "s/^\s*//" -e "/^$/d")
echo ""
echo "System uptime : $runtime1  / $runtime2 "
echo ""
echo "$totalban1 ip adresses with fail2ban from jail sshd"
echo ""
echo ""
fi 
' >> /etc/update-motd.d/99-base01
chmod +x /etc/update-motd.d/99-base01
dpkg-reconfigure tzdata

echo "base_server script installed from :
https://github.com/zzzkeil/base_setups
" > /root/base_setup.README

runfile="/root/reminderfile.tmp"
bashhrc_check=$(cat <<EOF

# check reminderfile.tmp
if [ -f "$runfile" ]; then
    echo "File exists: "
else
    echo ""
fi
EOF
)

if ! grep -q "check reminderfile.tmp" ~/.bashrc; then
    if whiptail --title "Wellcome back" --yesno "Continue with latest installation?" 15 80; then
	./setup_wg_adblock.sh
    else
    whiptail --title "Aborted" --msgbox "Manual run ./setup_wg_adblock.sh if you ready" 15 80
    exit 1
    fi   
else
    echo ""
fi

#
# END
#
if [[ "$newpass" -ne 0 ]]; then
whiptail --title "REMEMBER - you set a new root password" --msgbox "You set a new root password :\n\n$randompasswd\n\nIf you not saved this password, you can never loggin again, be carefull\n\nNew ssh port = $sshport / open in firewalld" 15 99
fi
if [[ "$newpass" = '0' ]]; then
whiptail --title "Info" --msgbox "Your root password or PubkeyAuthentication has not changed\n\nNew ssh port = $sshport / open in firewalld" 15 80
fi
if whiptail --title "Lets restart" --yesno "Reboot now\nIt's highly recommended\nNew ssh port = $sshport / open in firewalld" 15 80; then
systemctl enable fail2ban.service
systemctl enable firewalld
reboot
else
whiptail --title "Aborted" --msgbox "Be carefull, a reboot is recommended" 15 80
systemctl enable fail2ban.service
systemctl enable firewalld
exit 1
fi   


