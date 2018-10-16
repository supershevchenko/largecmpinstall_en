#!/bin/bash
source ./colorecho
hosts="$@"
for i in $hosts
do
echo "configure node "$i 
ostype=`ssh $i head -n 1 /etc/issue | awk '{print $1}'`

#
ssh -Tq $i <<EOF

		iptables -P INPUT ACCEPT
                iptables-save >/etc/iptables
                sed -i /"-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT"/d /etc/iptables
		sed -i /"-A INPUT -p tcp -m tcp --dport 8849 -j ACCEPT"/d /etc/iptables
		sed -i /"-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT"/d /etc/iptables
		sed -i /glbservices/d /etc/iptables
                iptables-restore </etc/iptables
		iptables --new glbservices
		iptables -A INPUT -p tcp --dport 22 -j ACCEPT
		iptables -A INPUT -p tcp --dport 8849 -j ACCEPT
		iptables -A glbservices -p tcp --dport 8081 -j ACCEPT
		iptables -A glbservices -p udp --dport 8081 -j ACCEPT
		iptables -A glbservices -p tcp --dport 8012 -j ACCEPT
		iptables -A glbservices -p udp --dport 8012 -j ACCEPT
		iptables -A glbservices -m state --state ESTABLISHED,RELATED -j ACCEPT
		iptables -A glbservices -p icmp --icmp-type any -j ACCEPT
		iptables -A glbservices -p 112 -j ACCEPT
		iptables -A glbservices -d 224.0.0.0/8 -j ACCEPT
		iptables -A glbservices -d 10.143.132.0/24 -j ACCEPT
		iptables -A glbservices -d 192.0.0.0/8 -j ACCEPT
		iptables -A INPUT -j glbservices
		exit
EOF


if [ "$ostype" == "Ubuntu" ]; then
	ssh  $i -Tq <<EOF
		iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
		iptables -P INPUT DROP
		iptables-save > /etc/iptables
		sed -i /iptables/d /etc/rc.local
		sed -i /exit/d /etc/rc.local
		echo "iptables-restore < /etc/iptables" >>/etc/rc.local
		chmod u+x /etc/rc.local
		exit
EOF
else
	ssh  $i -Tq <<EOF
		iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
		iptables -P INPUT DROP
                iptables-save > /etc/sysconfig/iptables
                sed -i /iptables/d /etc/rc.d/rc.local
		sed -i /reject-with/d /etc/sysconfig/iptables
		iptables-restore < /etc/sysconfig/iptables
                echo "iptables-restore < /etc/sysconfig/iptables" >>/etc/rc.d/rc.local
                chmod u+x /etc/rc.d/rc.local
		exit
EOF
fi
echo "complete..."
done

exit 0
