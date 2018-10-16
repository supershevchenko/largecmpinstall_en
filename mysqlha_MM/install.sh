#!/bin/bash
#set -x
set -eo pipefail
shopt -s nullglob
source ./colorecho
source ./mysql_installinit.conf
MYSQL_DIR="/usr/local/mysql"
KEEPALIVED_DIR="/usr/local/keepalived"

#from mysql_installinit.conf
item=$install

#---------------settings------------------
#Mysql cluster ip address:
cluster_ip="10.143.132.189 10.143.132.79"
#Front galera load balancing ip address(HA):
glb_haip="10.143.132.75 10.143.132.76"
keepalived_vip="10.143.132.234"
#MYSQL account password:
MYSQL_ROOT_PASSWORD="Pbu4@123"
MYSQL_EVUSER_PASSWORD="Pbu4@123"
MYSQL_IM_PASSWORD="Pbu4@123"
MYSQL_REPL_PASSWORD="Pbu4@123"
NTPIP="10.143.132.5"
#-----------------------------------------------
declare -a MSYQLHA_HOST=($cluster_ip)
declare -a MYSQL_PORT="3306"
declare -a GLB_HOST=($glb_haip)
declare -a mysql_first_ip

for i in "${MSYQLHA_HOST[@]}"
do
        mysql_first_ip=$i
        break
done



check_ostype(){
	#local ostype=`ssh -n $1 head -n 1 /etc/issue | awk '{print $1}'`
	local ostype=`hostnamectl | grep 'Operating System' | awk -F : '{print $2}' | awk '{print $1}'`
	if [ "$ostype" == "Ubuntu" ]; then
		local version=`ssh -n $1 head -n 1 /etc/issue | awk  '{print $2}'| awk -F . '{print $1}'`
		echo ubuntu_$version
	else
		local centos=`ssh -n $1 rpm -qa | grep sed | awk -F . '{print $4}'`
		if [ "$centos" == "el6" ]; then
			echo centos_6
		elif [ "$centos" == "el7" ]; then
			echo centos_7
		fi
	fi
}


ssh-mysqlconnect(){
	echo_green "Create ssh password trusting relationship..."
	local ssh_init_path=./ssh-init.sh

	$ssh_init_path $cluster_ip
	if [ $? -ne 0 ]; then
		echo_red "Fail,please check..."
		exit 1
	fi

	$ssh_init_path $glb_haip
	if [ $? -ne 0 ]; then
		echo_red "Fail,please check..."
		exit 1
	fi
        echo "end ssh..."
        sleep 1
}

mysql_install(){
	echo "install mysql"
	local k=1
	for i in "${MSYQLHA_HOST[@]}"
	do
		echo "install mysql database to node "$i
		local ostype=`check_ostype $i`
		local os=`echo $ostype | awk -F _ '{print $1}'`
		if [ "$os" == "centos" ]; then
			local result=`ssh -n $i ps -ef | grep mysql | wc -l`
			if [ "$result" -gt 1 ]; then
				local mysql_v=`ssh -n $i rpm -qa |grep ^mysql-wsrep-server | wc -l`
				if [ "$mysql_v" -eq 1 ]; then
					echo_yellow "mysql 5.7 have been installed"
					exit
				else
					ssh -Tq $i <<EOF
						rpm -qa | grep mysql && rpm -qa | grep ^mysql | xargs rpm -e --nodeps || echo 'clear'
						rpm -qa | grep mariadb && rpm -qa | grep mariadb | xargs rpm -e --nodeps || echo 'clear'
						exit
EOF
					echo_red "Remove the low version of the backup data, and then perform the latest version of mysql installation"
					exit
				fi
			fi
			echo_yellow "install packages"
			local libaio=`ssh -n "$i" rpm -qa |grep libaio |wc -l`
			if [ "$libaio" -gt 0 ]; then
				echo "libaio installed"
			else
				if [ "$ostype" == "centos_6" ]; then
					scp  ../packages/centos6_libaio/* "$i":/root/
					ssh -n $i rpm -Uvh --oldpackage ~/libaio-0.3.107-10.el6.x86_64.rpm
				elif [ "$ostype" == "centos_7" ]; then
					scp ../packages/centos7_libaio/* "$i":/root/
					ssh -n $i rpm -Uvh --oldpackage ~/libaio-0.3.109-13.el7.x86_64.rpm
				fi
			fi
			local numactl=`ssh -n "$i" rpm -qa |grep numactl |wc -l`
			if [ "$numactl" -gt 0 ]; then
				echo "numactl installed"
			else
				if [ "$ostype" == "centos_6" ]; then
					scp ../packages/centos6_numactl/* "$i":/root/
					ssh -n $i rpm -Uvh --oldpackage ~/numactl-2.0.9-2.el6.x86_64.rpm
				elif [ "$ostype" == "centos_7" ]; then
					scp ../packages/centos7_numactl/* "$i":/root/
					ssh -n $i rpm -Uvh --oldpackage ~/numactl-2.0.9-6.el7_2.x86_64.rpm ~/numactl-libs-2.0.9-6.el7_2.x86_64.rpm
				fi
			fi
			local openssl=`ssh -n "$i" rpm -qa |grep openssl |wc -l`
			if [ "$openssl" -gt 0 ]; then
				echo "openssl installed"
			else
				if [ "$ostype" == "centos_6" ]; then
					scp ../packages/centos6_openssl/* "$i":/root/
					ssh -n $i rpm -Uvh --oldpackage ~/openssl-1.0.1e-57.el6.x86_64.rpm            
				elif [ "$ostype" == "centos_7" ]; then
					scp ../packages/centos7_openssl/* "$i":/root/
					ssh -n $i rpm -Uvh --oldpackage ~/make-3.82-23.el7.x86_64.rpm  ~/openssl-1.0.1e-60.el7_3.1.x86_64.rpm  ~/openssl-libs-1.0.1e-60.el7_3.1.x86_64.rpm
				fi
			fi
			#2018.5.22//////////////////////////////////////////////
			local ntp=`ssh -n "$i" rpm -qa |grep ntp |wc -l`
                        if [ "$ntp" -gt 100 ]; then
                        	echo "ntp installed"
                        else
                                if [ "${ostype}" == "centos_6" ]; then
                                         scp  ../packages/centos6_ntp/* "$i":/root/
                                         ssh -n $i rpm -Uvh --oldpackage --replacepkgs ~/ntpdate-4.2.6p5-10.el6.centos.2.x86_64.rpm ~/ntp-4.
2.6p5-10.el6.centos.2.x86_64.rpm
                                 elif [ "${ostype}" == "centos_7" ]; then
                                         scp -r ../packages/centos7_ntp "$i":/root/
                                         ssh -Tq $i <<EOF
                                             rpm -Uvh --oldpackage --replacepkgs ~/centos7_ntp/*
                                             rm -rf ~/centos7_ntp
                                             exit
EOF
                                 fi
                         fi
			#/////////////////////////////////////////////////////////
			local iptables=`ssh -n "$i" rpm -qa |grep iptables |wc -l`
			if [ "$iptables" -gt 1 ]; then
				echo "iptables installed"
			else
				if [ "$ostype" == "centos_6" ]; then
					scp  ../packages/centos6_iptables/* "$i":/root/
					ssh -n $i rpm -Uvh --oldpackage ~/iptables-1.4.7-16.el6.x86_64.rpm
				elif [ "$ostype" == "centos_7" ]; then
                                        scp -r ../packages/centos7_iptables "$i":/root/
                                        ssh -Tq $i <<EOF
                                        	rpm -Uvh --oldpackage --replacepkgs ~/centos7_iptables/*
						rm -rf ~/centos7_iptables
                                        	exit
EOF
                                fi
			fi
			
			if [ "$ostype" == "centos_6" ]; then
				echo "Current can not install on Centos_6_version"
			elif [ "$ostype" == "centos_7" ]; then
				scp -r ../packages/mysql-wsrep "$i":/root/
				ssh -Tq $i <<EOF
					rpm -Uvh --oldpackage --replacepkgs ~/mysql-wsrep/*
					rm -rf ~/mysql-wsrep
					exit
EOF
			fi

		elif [ "$os" == "ubuntu" ]; then
			local result=`ssh -n $i ps -ef | grep mysql | wc -l`
			if [ "$result" -gt 1 ]; then
				local mysql_v=`ssh -n $i mysql --version | sed -n '/5.7/p' | wc -l`
				if [ "$mysql_v" -eq 1 ]; then
					echo_yellow "mysql 5.7 installed"
					exit
				else
					echo_red "Remove the low version of the backup data, and then perform the latest version of mysql installation"
					exit
				fi
			fi
			if [ "$ostype" == "ubuntu_12" ]; then
				echo_red "$ostype" unsurpposed
				exit
			elif [ "$ostype" == "ubuntu_14" ]; then
				scp  ../packages/ubuntu14/* "$i":/root/
				ssh -n $i dpkg -i ~/libaio1_0.3.109-4_amd64.deb  ~/libnuma1_2.0.9~rc5-1ubuntu3.14.04.2_amd64.deb  ~/openssl_1.0.1f-1ubuntu2.22_amd64.deb ~/iptables_1.4.21-1ubuntu1_amd64.deb ~/libnfnetlink0_1.0.1-2_amd64.deb ~/libxtables10_1.4.21-1ubuntu1_amd64.deb ~/keepalived_1.a1.2.7-1ubuntu1_amd64.deb ~/libsnmp30_5.7.2~dfsg-8.1ubuntu3.2_amd64.deb ~/ipvsadm_1.a1.26-2ubuntu1_amd64.deb ~/libperl5.18_5.18.2-2ubuntu1.1_amd64.deb ~/libsnmp-base_5.7.2~dfsg-8.1ubuntu3.2_all.deb ~/libnl-3-200_3.2.21-1ubuntu4.1_amd64.deb ~/libnl-genl-3-200_3.2.21-1ubuntu4.1_amd64.deb ~/libsensors4_1%3a3.3.4-2ubuntu1_amd64.deb ~/iproute_1.3.12.0-2ubuntu1_all.deb
			elif [ "$ostype" == "ubuntu_16" ]; then
				echo_red "$ostype" unsurpposed
				exit
			else
				echo_red "$ostype" unsurpposed
				exit
			fi
		fi

		scp ./ntp.conf $i:/etc/ntp.conf
                local ostype=`check_ostype $i`
                if [ "$ostype" == "centos_7" ]; then
			scp ./ntpd "$i":/etc/init.d/
			ssh -n "$i" systemctl daemon-reload
                fi
                ssh -Tq $i <<EOF
                        sed -i "/ntpip/{s/ntpip/$NTPIP/}" /etc/ntp.conf
                        chmod u+x /etc/init.d/ntpd
                        /etc/init.d/ntpd stop
                        echo "first nysnc ntp server..."
                        ntpdate $NTPIP &>/dev/null && echo " sync ntp success!" || echo "sync ntp failed,please check it!"
                        /etc/init.d/ntpd restart
                        exit
EOF

		echo "Change mysql config...."
		ssh -n "$i" rm -rf /opt/tmp
		ssh -n "$i" mkdir /opt/tmp
		scp ./*.sh "$i":/opt/tmp/
		scp -r ../packages/support-files/* "$i":/opt/tmp/
		#total mem:70%
		local MEMTOTAL=$(ssh $i free -b | sed -n '2p' | awk '{print $2}')
		local memgbyte=`expr $MEMTOTAL \* 70 / 100 / 1024 / 1024 / 1024`
		ssh -Tq $i <<EOF
			setenforce 0
                	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
                	sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
			mkdir -p $MYSQL_DIR/data
        		chown -R mysql:mysql $MYSQL_DIR
        		rm -fr /etc/my.cnf.d/*
			mv /opt/tmp/server.cnf /etc/my.cnf.d/
                        sed -i "s/server_id = 1/server_id = $k/g" /etc/my.cnf.d/server.cnf
                        sed -i "s/port = 3306/port = $MYSQL_PORT/g" /etc/my.cnf.d/server.cnf
			sed -i "s/innodb_buffer_pool_size = 1/innodb_buffer_pool_size = $memgbyte/g" /etc/my.cnf.d/server.cnf
                        #sed -i "s/mysqldatadir/$MYSQL_DIR\/data/g" /etc/my.cnf.d/server.cnf
                	sed -i "s/nodename/node$k/g" /etc/my.cnf.d/server.cnf
                	sed -i "s/127.0.0.1/$i/g" /etc/my.cnf.d/server.cnf
			exit
EOF
		if [ "$k" -eq 1 ]; then
			echo "cp /etc/my.cnf.d/server.cnf /opt/tmp/server-tmp.cnf" > ./tmp.sh
			echo 'sed -i "s/gcomm:\/\//&^/g" /opt/tmp/server-tmp.cnf' >> ./tmp.sh
			chmod +x ./tmp.sh
			for ii in "${MSYQLHA_HOST[@]}"
			do
				echo "sed -i \"s/\^/$ii,&/g\" /opt/tmp/server-tmp.cnf" >> ./tmp.sh
			done
			echo "sed -i 's/,^//g' /opt/tmp/server-tmp.cnf" >> ./tmp.sh
			scp ./tmp.sh "$i":/opt/tmp/
			ssh -n "$i" /opt/tmp/tmp.sh
			ssh -Tq $i <<EOF
				echo '!includedir /etc/my.cnf.d' > /etc/my.cnf
				echo "initilaze MYSQL...."
				mysqld --initialize-insecure --user=mysql --datadir=$MYSQL_DIR/data
				echo "Mysql_ssl_rsa_install...."
				mysql_ssl_rsa_setup --user=mysql --datadir=$MYSQL_DIR/data
				chmod 644 $MYSQL_DIR/data/server-key.pem
				mysqld --wsrep-new-cluster &
				sleep 10
				mv /etc/my.cnf.d/server.cnf /opt/tmp/server.cnf.bak
				mv /opt/tmp/server-tmp.cnf /etc/my.cnf.d/server.cnf
				exit
EOF
			MYSQL_PASS=("$MYSQL_ROOT_PASSWORD" "$MYSQL_EVUSER_PASSWORD" "$MYSQL_IM_PASSWORD" "$MYSQL_REPL_PASSWORD")
			#Change root password:
			ssh -n $i /opt/tmp/init_mysqlha.sh "${MYSQL_PASS[@]}"
			ssh -n $i /opt/tmp/create-repl-account.sh "${MYSQL_PASS[@]}"
			ssh -n $i /opt/tmp/create_db.sh "${MYSQL_PASS[@]}"
		else
			echo 'sed -i "s/gcomm:\/\//&^/g" /etc/my.cnf.d/server.cnf' > ./tmp.sh
			for ii in "${MSYQLHA_HOST[@]}"
			do
				echo "sed -i \"s/\^/$ii,&/g\" /etc/my.cnf.d/server.cnf" >> ./tmp.sh
			done
			echo "sed -i 's/,^//g' /etc/my.cnf.d/server.cnf" >> ./tmp.sh
			scp ./tmp.sh "$i":/opt/tmp/
			ssh -n "$i" /opt/tmp/tmp.sh
			mkdir ./ca-tmp
			scp "$mysql_first_ip":"$MYSQL_DIR"/data/\*.pem ./ca-tmp/
			scp ./ca-tmp/* "$i":"$MYSQL_DIR"/data/
			rm -fr ./ca-tmp
			MYSQL_PASS=("$MYSQL_ROOT_PASSWORD" "$MYSQL_EVUSER_PASSWORD" "$MYSQL_IM_PASSWORD" "$MYSQL_REPL_PASSWORD")
			ssh -Tq $i <<EOF
				echo '!includedir /etc/my.cnf.d' > /etc/my.cnf
                                echo '...Mysql config complete...' > /usr/local/mysql/mysql.log
                                chown -R mysql:mysql /usr/local/mysql/mysql.log
                                chmod 666 /usr/local/mysql/mysql.log
				systemctl start mysqld
				sleep 10
				/opt/tmp/create-repl-account.sh "${MYSQL_PASS[@]}"
				/opt/tmp/create_db.sh "${MYSQL_PASS[@]}"
				exit
EOF
		fi
		let k=k+1
	done 
	echo "all mysql nodes config_set complete"
}

mysqlha_settings(){
	for i in "${MSYQLHA_HOST[@]}"
	do
		echo "confiure repletion account. Node is : "$i 
		MYSQL_PASS=("$MYSQL_ROOT_PASSWORD" "$MYSQL_EVUSER_PASSWORD" "$MYSQL_IM_PASSWORD" "$MYSQL_REPL_PASSWORD")
		ssh -n "$i" /opt/tmp/create-repl-account.sh "${MYSQL_PASS[@]}"
		echo "confiure compelte..."
	done
	
}

mysqlha_createdb(){
	for i in "${MSYQLHA_HOST[@]}"
	do
		echo "Create database in Node : "$i
		MYSQL_PASS=("$MYSQL_ROOT_PASSWORD" "$MYSQL_EVUSER_PASSWORD" "$MYSQL_IM_PASSWORD" "$MYSQL_REPL_PASSWORD")
		ssh -n "$i" /opt/tmp/create_db.sh "${MYSQL_PASS[@]}"
		break
		echo "confiure compelte..."
	done
}

iptables-mysql(){
  	echo "configure iptables..."
        local iptable_path=./iptablesmysql.sh
        $iptable_path $cluster_ip
	echo "confiure compelte..."
}


uninstall_mysql(){
	echo "uninstall mysql..."
        for i in "${MSYQLHA_HOST[@]}"
        do
                echo "service down"$i
                local user=`ssh -n $i cat /etc/passwd | awk -F : '{print \$1}' | grep -w mysql |wc -l`
                if [ "$user" -eq 1 ]; then
			ssh -n $i pkill mysql 2>/dev/null
                        echo "MYSQL down"
			sleep 2
			ssh -n $i userdel -f mysql
                else
                        echo_yellow "Mysql user is not created, please manually shut down the service!"
                fi
		
		#echo "close keepalived"$i
		#local keepaliveds=`ssh -n $i rpm -qa | grep keepalived`
		#if [ "$keepaliveds" != "" ]; then
                #	ssh -Tq $i <<EOF
		#		/etc/init.d/keepalived stop
                #               rpm -e $keepaliveds
                #               exit
		#	EOF
		#fi

		#ssh -n $i rm -rf "$MYSQL_DIR"
		rpm -qa |grep ^mysql |xargs rpm -e --nodeps
		
		echo "clear mysql iptables"$i
                local iptables=`ssh -n $i iptables -L INPUT | sed -n /mysqldb/p |wc -l`
                if [ "$iptables" -gt 0 ]; then
                	ssh -Tq $i <<EOF
                		iptables -P INPUT ACCEPT
                		iptables -D INPUT -j mysqldb
                		iptables -F mysqldb
                		iptables -X mysqldb
                		iptables-save > /etc/iptables
                		iptables-save > /etc/sysconfig/iptables
                		exit
EOF
                fi
		echo "complete..."
        done
	echo "clear complete..."
}

keepalived_install(){
	host_ip=$1
        local os_type=""
        os_type=`ssh -n $host_ip hostnamectl |grep Operating|awk -F: '{print $2}'|awk -F'(' '{print $1}' |awk -F' ' '{print $1_$3}'`

        if [ "$os_type" == "CentOS Linux 6" ]
        then
                scp -r ../packages/centos6_keepalived "$host_ip":/tmp/
                ssh -Tq $host_ip <<EOF
                        rpm -qa | grep keepalived && rpm -qa | grep keepalived | xargs rpm -e
                        rpm -qa | grep net-snmp && rpm -qa | grep net-snmp | xargs rpm -e
                        rpm -qa | grep perl-core && rpm -qa | grep perl-core | xargs rpm -e
                        rpm -Uvh --oldpackage --replacepkgs /tmp/centos6_keepalived/*
                        rm -rf /tmp/centos6_keepalived
                        exit
EOF
	fi

	echo $os_type
	if  [ "$os_type" == "CentOS7" ]
	then
                scp -r ../packages/centos7_keepalived "$host_ip":/tmp/
                ssh -Tq $host_ip <<EOF
                        rpm -qa | grep keepalived && rpm -qa | grep keepalived | xargs rpm -e
                        rpm -qa | grep net-snmp && rpm -qa | grep net-snmp | xargs rpm -e
                        rpm -qa | grep perl-core && rpm -qa | grep perl-core | xargs rpm -e
                        rpm -Uvh --oldpackage --replacepkgs --nodeps /tmp/centos7_keepalived/*
                        rm -rf /tmp/centos7_keepalived
                        exit
EOF
	fi
:<<!
        elseif  [ "$os_type" == "Ubuntu" ]
	then
                scp  ../packages/ubuntu14/keepalived_1.a1.2.7-1ubuntu1_amd64.deb "$host_ip":/tmp/
                scp  ../packages/ubuntu14/libnfnetlink0_1.0.1-2_amd64.deb "$host_ip":/tmp/
                scp  ../packages/ubuntu14/libxtables10_1.4.21-1ubuntu1_amd64.deb "$host_ip":/tmp/
                ssh -n $host_ip dpkg -i /tmp/libnfnetlink0_1.0.1-2_amd64.deb /tmp/libxtables10_1.4.21-1ubuntu1_amd64.deb /tmp/keepalived_1.a1.2.7-1ubuntu1_amd64.deb
	else
                echo_red "Current $ostype unsurpposed.please use Centos_6,Centos_7,Ubuntu_14..."
                exit 1
        fi
!
} 

#glb install and settings
glb_install(){
	echo_green "Start Install and Settings GLB HA Nodes..."
	local k=1
	local preip=""
	for i in "${GLB_HOST[@]}"
	do
		scp -r ../packages/glb "$i":/opt/
               	ssh -Tq $i <<EOF
			cd /opt/glb
			./bootstrap.sh
			./configure
			make
			make install
			setenforce 0
                	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
                	sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
			exit
EOF
		ssh -n $i rm -rf /etc/init.d/glbd
		scp ../packages/support-files/glbd "$i":/etc/init.d/glbd

		rm -rf /tmp/glbd.cfg
		cp ../packages/support-files/glbd.cfg /tmp/glbd.cfg
		k=1
		for ii in "${MSYQLHA_HOST[@]}"
		do
			if [ $k -eq 1 ]
			then
				sed -i "s/DEFAULT_TARGETS=\"\"/DEFAULT_TARGETS=\"$ii:$MYSQL_PORT\"/g" /tmp/glbd.cfg
			else
				sed -i "s/$preip/& $ii:$MYSQL_PORT/g" /tmp/glbd.cfg
			fi
			preip=$ii":"$MYSQL_PORT
			let k=k+1
		done
	
		scp /tmp/glbd.cfg $i:/etc/
		rm -rf /tmp/glbd.cfg
		ssh -n $i echo "/etc/init.d/glbd start" >> /etc/rc.local
		ssh -n $i /etc/init.d/glbd restart
	done

	echo_green "Install and Settings GLB HA Nodes Complete..."

  	echo_green "Configure GLB_HOSTS iptables rule..."
        local iptable_path=./iptables_glbservers.sh
        $iptable_path $glb_haip
	echo_green "GLB_HOSTS iptables rule confiure compelte..."

	cp -f ../packages/support-files/keepalived.conf /tmp/
	sed -i "s/vip/$keepalived_vip/g" /tmp/keepalived.conf
	
	k=100
	for ii in "${GLB_HOST[@]}"
	do
		keepalived_install $ii
		ssh -n $ii rm -f /etc/keepalived.conf
		scp /tmp/keepalived.conf $ii:/etc/keepalived/
		scp ./checkglb_down.sh $ii:/usr/bin/
		ethname=`ssh -n $ii ip addr |grep $ii|awk '{print $NF}' `
		ssh -Tq $ii <<EOF
			sed -i "s/rip/$ii/g" /etc/keepalived/keepalived.conf
			sed -i "s/eth0/$ethname/g" /etc/keepalived/keepalived.conf
			sed -i "s/priority 100/priority $k/g" /etc/keepalived/keepalived.conf
			echo 'local0.*       /var/log/keepalived.log' >> /etc/rsyslog.conf
			systemctl  restart rsyslog
			cp -f /etc/sysconfig/keepalived /etc/sysconfig/keepalived.bak
			echo 'KEEPALIVED_OPTIONS="-D -d -S 0"' > /etc/sysconfig/keepalived
			systemctl restart keepalived
			sleep 1
			exit
EOF
		let k=k-10
	done
}


#echo "1----install mysql-wsrep-server-5.7"
#echo "100--uninstall mysql-wsrep-server-5.7"
#while read item
#do
  case $item in
    1)
	ssh-mysqlconnect
	mysql_install
	glb_install
	iptables-mysql
        #break
    ;;
    100)	
	ssh-mysqlconnect
	uninstall_mysql
	#break
     ;;
     0)
        echo "exit"
        exit 0
     ;;
     *)
        echo_red "error,input again！"
     ;;
  esac
#done
