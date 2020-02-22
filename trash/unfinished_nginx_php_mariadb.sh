#!/bin/bash
clear
echo " #############################################"
echo " # Setup server config Netcup Ubuntu 18.04   #"
echo " # !!!! Run base_server_setup.sh first !!!!  #"
echo " #############################################"
echo ""
echo ""
echo "To EXIT this script press  [ENTER]"
echo 
echo " # !!!! Run base_server_setup.sh first !!!!  #"
read -p "To RUN this script press  [Y]" -n 1 -r
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

if [[ -e /etc/debian_version ]]; then
      echo "Debian Distribution"
      else
      echo "This is not a Debian Distribution."
      exit 1
fi
#
#ufw for nginx
#
ufw allow 80
ufw allow 443
ufw reload
#
# APT
#
echo "apt update and install"
apt update && apt upgrade -y && apt autoremove -y

#
#nginx
#
mv /etc/apt/sources.list /root/script_backupfiles/sources.list.bak && touch /etc/apt/sources.list
cat <<EOF >>/etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu bionic main multiverse restricted universe
deb http://archive.ubuntu.com/ubuntu bionic-security main multiverse restricted universe
deb http://archive.ubuntu.com/ubuntu bionic-updates main multiverse restricted universe
deb http://ppa.launchpad.net/ondrej/php/ubuntu bionic main
deb http://ppa.launchpad.net/ondrej/nginx-mainline/ubuntu bionic main
EOF

apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 4F4EA0AAE5267A6C
apt update
apt install nginx nginx-extras -y
systemctl enable nginx.service
clear

#
#nginx configs
#
read -p "sitename: " -e -i exsample.domain sitename
mkdir /var/www/$sitename
echo " <html><body><center>nginx test html</center></body></html> " >> /var/www/$sitename/index.html
echo "server {
	listen 80 default_server;
	listen [::]:80 default_server;

	server_name $sitename;
	root /var/www/$sitename;

	index index.html;
	location / {
		try_files $uri $uri/ =404;
	}
}
" >> /etc/nginx/sites-available/$sitename.conf
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/$sitename.conf /etc/nginx/sites-enabled/$sitename.conf
systemctl restart nginx.service

#
#Certbot
#
apt install software-properties-common
add-apt-repository universe -y
add-apt-repository ppa:certbot/certbot -y
apt update
apt install certbot python-certbot-nginx -y
#
echo "
rsa-key-size = 4096
" | tee --append /etc/letsencrypt/cli.ini > /dev/null
# make your own decision for certbot --nginx
certbot --nginx
sed -i 's/listen [::]:443 ssl ipv6only=on;/listen [::]:443 ssl http2;/g' /etc/nginx/sites-available/$sitename.conf
sed -i 's/listen 443 ssl;/listen 443 ssl http2;/g' /etc/nginx/sites-available/$sitename.conf
sed '/listen 443 ssl http2;/a gzip off;' /etc/nginx/sites-available/$sitename.conf
sed '/ssl_certificate_key /etc/letsencrypt/live/'$sitename'/privkey.pem;/a ssl_trusted_certificate /etc/letsencrypt/live/'$sitename'/chain.pem;' /etc/nginx/sites-available/$sitename.conf

cp /etc/letsencrypt/options-ssl-nginx.conf /etc/letsencrypt/options-ssl-nginx.conf.bak
rm /etc/letsencrypt/options-ssl-nginx.conf
echo 'ssl_session_cache shared:le_nginx_SSL:1m;
ssl_session_timeout 1d;
ssl_session_tickets off;

ssl_protocols TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers "TLS-CHACHA20-POLY1305-SHA256:TLS-AES-256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384";
ssl_ecdh_curve X448:secp521r1:secp384r1:prime256v1;

ssl_stapling on;
ssl_stapling_verify on;

add_header Strict-Transport-Security "max-age=15768000; includeSubdomains; preload;";
add_header Content-Security-Policy "default-src 'none'; frame-ancestors 'none'; script-src 'self'; img-src 'self'; style-src 'self'; base-uri 'self'; form-action 'self';";
add_header Referrer-Policy "no-referrer, strict-origin-when-cross-origin";
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
' | tee --append /etc/letsencrypt/options-ssl-nginx.conf > /dev/null
systemctl restart nginx.service
#####
#nginx tls1.3 with lets encrypt ready
#####










































