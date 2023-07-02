#!/bin/bash

DDNS_HOSTNAME="enter.domain.here"
DDNS_IP=$(ping -q -c 1 -t 1 -4 $DDNS_HOSTNAME | grep PING | sed -e "s/).*//" | sed -e "s/.*(//")
OLD_IP=$(firewall-cmd --direct --get-all-rules | grep $DDNS_HOSTNAME | head -n1 | tr -s ' ' | cut -f8 -d ' ')


if [[ "${DDNS_IP}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  if [[ "${OLD_IP}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    if [[ "${DDNS_IP}" != "${OLD_IP}" ]]; then
                firewall-cmd --direct --remove-rule ipv4 filter DOCKER-USER 1 -j RETURN -s ${DDNS_IP} -m comment --comment "${DDNS_HOSTNAME}"
                firewall-cmd --direct --add-rule ipv4 filter DOCKER-USER 1 -j RETURN -s ${DDNS_IP} -m comment --comment "${DDNS_HOSTNAME}"
    else
      echo "$0: Same IP address, nothing to do.... see you later."
    fi
  else
        firewall-cmd --direct --add-rule ipv4 filter DOCKER-USER 1 -j RETURN -s ${DDNS_IP} -m comment --comment "${DDNS_HOSTNAME}"
  fi
else
  echo "$0: No something ist wrong. IP address result for ${DDNS_HOSTNAME} is : ${DDNS_IP}"
  echo "$0: Nothing Changed in firewalld rules !!!"
fi
