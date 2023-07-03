systemctl stop docker

echo '
{
"iptables": false
}
' > /etc/docker/daemon.json


firewall-cmd --zone=public --add-masquerade --permanent
firewall-cmd --permanent --zone=trusted --add-interface=docker0
firewall-cmd --permanent --zone=public --add-interface=eth0



firewall-cmd --reload
systemctl restart docker
