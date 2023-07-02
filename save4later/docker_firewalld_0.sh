systemctl stop docker.socket
systemctl stop docker.service

firewall-cmd --permanent --direct --remove-chain ipv4 filter DOCKER-USER
firewall-cmd --permanent --direct --remove-rules ipv4 filter DOCKER-USER
firewall-cmd --permanent --direct --add-chain ipv4 filter DOCKER-USER
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT -m comment --comment 'Allow containers to connect to the outside world'
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 -j RETURN -s 127.0.0.0/8 -m comment --comment 'allow internal docker communication, loopback addresses'
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 -j RETURN -s 10.0.0.0/8 -m comment --comment 'allow internal docker communication, private range'
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 -j RETURN -s 172.16.0.0/12 -m comment --comment 'allow internal docker communication, private range'
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 -j RETURN -s 192.168.0.0/16 -m comment --comment 'allow internal docker communication, private range'
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 10 -j REJECT -m comment --comment 'reject all other traffic to DOCKER-USER'
firewall-cmd --reload
firewall-cmd --direct --get-all-rules

systemctl start docker.socket
systemctl start docker.service
