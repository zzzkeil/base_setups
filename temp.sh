#!/bin/bash
clear
add-apt-repository ppa:certbot/certbot -y
apt install gnupg gnupg2 lsb-release wget curl ssl-cert letsencrypt -y
cd /etc/apt/sources.list.d
echo "deb [arch=amd64,arm64] http://ppa.launchpad.net/ondrej/php/ubuntu $(lsb_release -cs) main" | tee php.list
echo "deb [arch=amd64,arm64] http://nginx.org/packages/mainline/ubuntu $(lsb_release -cs) nginx" | tee nginx.list
echo "deb [arch=amd64,arm64] http://ftp.hosteurope.de/mirror/mariadb.org/repo/10.4/ubuntu $(lsb_release -cs) main" | tee mariadb.list
curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
apt-key adv --recv-keys --keyserver hkps://keyserver.ubuntu.com:443 4F4EA0AAE5267A6C
apt-key adv --recv-keys --keyserver hkps://keyserver.ubuntu.com:443 0xF1656F24C74CD1D8
apt install software-properties-common zip unzip screen git wget ffmpeg libfile-fcntllock-perl locate ghostscript tree htop -y
apt remove nginx nginx-common nginx-full -y --allow-change-held-packages
apt install nginx -y
apt install php7.4-fpm php7.4-gd php7.4-mysql php7.4-curl php7.4-xml php7.4-zip php7.4-intl php7.4-mbstring php7.4-json php7.4-bz2 php7.4-ldap php-apcu imagemagick php-imagick -y
apt install mariadb-server -y
