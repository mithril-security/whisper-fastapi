#!/bin/bash
echo "Configuration:"
echo "PROXY_SERVER=$PROXY_SERVER"
echo "PROXY_PORT=$PROXY_PORT"
echo "Setting config variables"
sed -i "s/vPROXY-SERVER/$PROXY_SERVER/g" /etc/redsocks.conf
sed -i "s/vPROXY-PORT/$PROXY_PORT/g" /etc/redsocks.conf
echo "Restarting redsocks and redirecting traffic via iptables"
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
/etc/init.d/redsocks restart
