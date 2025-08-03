# My linux base setup for ARM64 and X86
![Debian](https://img.shields.io/badge/Debian-D70A53?style=for-the-badge&logo=debian&logoColor=white) ![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white) ![Fedora](https://img.shields.io/badge/Fedora-294172?style=for-the-badge&logo=fedora&logoColor=white) ![Rocky Linux](https://img.shields.io/badge/-Rocky%20Linux-%2310B981?style=for-the-badge&logo=rockylinux&logoColor=white) ![Cent OS](https://img.shields.io/badge/cent%20os-002260?style=for-the-badge&logo=centos&logoColor=F0F0F0) ![Alma Linux](https://img.shields.io/badge/alma%20linux-294172?style=for-the-badge&logo=almalinux&logoColor=F0F0F0)

[![https://hetzner.cloud/?ref=iP0i3O1wRcHu](https://img.shields.io/badge/maybe_you_can_support_me_-_my_VPS_hoster_hetzner_(referral_link)_thanks-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://hetzner.cloud/?ref=iP0i3O1wRcHu) 


## This script configure / install :
### password, ssh, fail2ban, rsyslog, firawalld, unattended-upgrades / dnf-automatic 

changelog :
one script for 
- x86 and arm64 
- Debian 12, Ubuntu 22.04, Fedora 38, Rocky Linux 9, CentOS Stream 9, AlmaLinux 9

### Setup :

###### Server x86 and arm64  -  Debian 12, Ubuntu 22.04, Fedora 38, Rocky Linux 9, CentOS Stream 9, AlmaLinux 9
```
wget -O  base_setup.sh https://raw.githubusercontent.com/zzzkeil/base_setups/master/base_setup.sh
chmod +x base_setup.sh
./base_setup.sh


```




Test

```
wget -O  base_setup_debian13.sh https://raw.githubusercontent.com/zzzkeil/base_setups/refs/heads/master/base_setup_debian13.sh
chmod +x base_setup_debian13.sh
./base_setup_debian13.sh


```
