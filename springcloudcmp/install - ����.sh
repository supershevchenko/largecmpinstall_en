#!/bin/bash
#set -x
#set -eo pipefail
shopt -s nullglob
source ./colorecho
source ./im_installinit.conf
nodetyper=1
nodeplanr=1
nodenor=1
eurekaipr=localhost
dcnamer="DC1"
eurekaiprepr=localhost
hanoder="main"
JDK_DIR="/usr/java"
MONGDO_DIR="/usr/local/mongodb"
MONGDO_ARBITER_DIR="/usr/local/mongodb_arbiter"
REDIS_DIR="/usr/local/redis"
KEEPALIVED_DIR="/usr/local/keepalived"
SSH_H=$(cat haiplist)
#from im_installinit.conf
item=$install

#---------------settings------------------
CURRENT_DIR="/springcloudcmp"
cmpuser="cmpimuser"
cmppass="Pbu4@123"
REDIS_H="10.143.132.181 10.143.132.182 10.143.132.183"
MONGO_H="10.143.132.181 10.143.132.182 10.143.132.183"
MONGO_USER="evuser"
MONGO_PASSWORD="Pbu4@123"
#MONGO_ARBITER_NODES(0,1,2)
MONGO_ARBITER_NODES=0
VIP="10.143.132.212"
NTPIP="10.143.132.188"
#-----------------------------------------------
declare -a SSH_HOST=()
declare -a REDIS_HOST=($REDIS_H)
declare -a MONGO_HOST=($MONGO_H)
declare -a nodes=()
declare -a GF_HOST=($GF_H_ALL)
declare -a IM_HOST=($SSH_H $GF_H_ALL)
declare -a DC_NAMES=($DC_NAME_ALL)

allnodes_get(){
	cat haiplist > .allnodes
	echo $REDIS_H >> .allnodes
	echo $MONGO_H >> .allnodes
	cat dciplist >> .allnodes
	ip_regex="[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}"
	cat .allnodes | egrep -o "$ip_regex" | sort | uniq > allnodes
	rm -rf .allnodes
}

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

install-interpackage(){
	echo_green "check environment..."
	
	allnodes_get
	for line in $(cat allnodes)
	do
	SSH_HOST=($line)
	echo "check nodes"
	for i in "${SSH_HOST[@]}"
            do
		echo "install packages on node "$i
		local ostype=`check_ostype $i`
		local os=`echo $ostype | awk -F _ '{print $1}'`
		if [ "$os" == "centos" ]; then
        		local iptables=`ssh -n "$i" rpm -qa |grep iptables |wc -l`
       			 if [ "$iptables" -gt 1 ]; then
                		echo "iptables installed"
        		else
                		if [ "${ostype}" == "centos_6" ]; then
                        		 scp  ../packages/centos6_iptables/* "$i":/root/
                         		 ssh -n $i rpm -Uvh --oldpackage  ~/iptables-1.4.7-16.el6.x86_64.rpm
				elif [ "$ostype" == "centos_7" ]; then
                                        scp -r ../packages/centos7_iptables "$i":/root/
                                        ssh -Tq $i <<EOF
                                        rpm -Uvh --oldpackage --replacepkgs ~/centos7_iptables/*
					rm -rf ~/centos7_iptables
                                        exit
EOF
                                fi
        		fi
	        	local lsof=`ssh -n "$i" rpm -qa |grep lsof |wc -l`
                	 if [ "$lsof" -gt 0 ]; then
                        	echo "lsof installed"
               		 else
                		if [ "${ostype}" == "centos_6" ]; then
                        		 scp  ../packages/centos6_lsof/* "$i":/root/
                         		 ssh -n $i rpm -Uvh --oldpackage ~/lsof-4.82-5.el6.x86_64.rpm
               			 elif [ "${ostype}" == "centos_7" ]; then
                        		 scp ../packages/centos7_lsof/* "$i":/root/
                         		 ssh -n $i rpm -Uvh --oldpackage ~/lsof-4.87-4.el7.x86_64.rpm
               			 fi
               		 fi
			 local psmisc=`ssh -n "$i" rpm -qa |grep psmisc |wc -l`
                         if [ "$psmisc" -gt 0 ]; then
                                echo "psmisc installed"
                         else
                                if [ "${ostype}" == "centos_6" ]; then
                                         scp  ../packages/centos6_psmisc/* "$i":/root/
                                         ssh -n $i rpm -Uvh --oldpackage ~/psmisc-22.6-24.el6.x86_64.rpm
                                 elif [ "${ostype}" == "centos_7" ]; then
                                         scp ../packages/centos7_psmisc/* "$i":/root/
                                         ssh -n $i rpm -Uvh --oldpackage ~/psmisc-22.20-11.el7.x86_64.rpm
                                 fi
                         fi
			 local gcc=`ssh -n "$i" rpm -qa |grep gcc |wc -l`
                         if [ "$gcc" -gt 1 ]; then
                                echo "gcc installed"
                         else
                                if [ "${ostype}" == "centos_6" ]; then
                                         scp -r  ../packages/centos6_gcc "$i":/root/
					 ssh -Tq $i <<EOF
                                             rpm -Uvh --oldpackage --replacepkgs ~/centos6_gcc/*
					     rm -rf ~/centos6_gcc
                                             exit
EOF
                                 elif [ "${ostype}" == "centos_7" ]; then
                                         scp -r ../packages/centos7_gcc "$i":/root/
					 ssh -Tq $i <<EOF
                                             rpm -Uvh --oldpackage --replacepkgs ~/centos7_gcc/*
					     rm -rf ~/centos7_gcc
                                             exit
EOF
                                 fi
                         fi
                         local tcl=`ssh -n "$i" rpm -qa |grep tcl |wc -l`
                         if [ "$tcl" -gt 0 ]; then
                                echo "tcl installed"
                         else
                                if [ "${ostype}" == "centos_6" ]; then
                                         scp  ../packages/centos6_tcl/* "$i":/root/
                                         ssh -n $i rpm -Uvh --oldpackage --replacepkgs ~/tcl-8.5.7-6.el6.x86_64.rpm
                                 elif [ "${ostype}" == "centos_7" ]; then
                                         scp ../packages/centos7_tcl/* "$i":/root/
                                         ssh -n $i rpm -Uvh --oldpackage --replacepkgs  ~/tcl-8.5.13-8.el7.x86_64.rpm
                                 fi
                         fi
			local ntp=`ssh -n "$i" rpm -qa |grep ntp |wc -l`
                         if [ "$ntp" -gt 100 ]; then
                                echo "ntp installed"
                         else
                                if [ "${ostype}" == "centos_6" ]; then
                                         scp  ../packages/centos6_ntp/* "$i":/root/
                                         ssh -n $i rpm -Uvh --oldpackage --replacepkgs ~/ntpdate-4.2.6p5-10.el6.centos.2.x86_64.rpm ~/ntp-4.2.6p5-10.el6.centos.2.x86_64.rpm
                                 elif [ "${ostype}" == "centos_7" ]; then
                                         scp -r ../packages/centos7_ntp "$i":/root/
                                         ssh -Tq $i <<EOF
                                             rpm -Uvh --oldpackage --replacepkgs ~/centos7_ntp/*
                                             rm -rf ~/centos7_ntp
                                             exit
EOF
                                 fi
                         fi
			if [ "$ostype"=="centos_7" ];  then
				ssh -Tq $i <<EOF
					     systemctl disable firewalld.service &>/dev/null
					     systemctl stop firewalld.service &>/dev/null
                                             setenforce 0
					     sed -i '/^SELINUX=/cSELINUX=disabled' /etc/sysconfig/selinux
                                             exit
EOF
			fi
		elif [ "$os" == "ubuntu" ]; then
			if [ "$ostype" == "ubuntu_12" ]; then
				echo_red "$ostype" unsurpposed
				exit
			elif [ "$ostype" == "ubuntu_14" ]; then
				scp  ../packages/ubuntu14/* "$i":/root/
                                ssh -n $i dpkg -i ~/lsof_4.86+dfsg-1ubuntu2_amd64.deb ~/iptables_1.4.21-1ubuntu1_amd64.deb ~/libnfnetlink0_1.0.1-2_amd64.deb ~/libxtables10_1.4.21-1ubuntu1_amd64.deb ~/psmisc_22.20-1ubuntu2_amd64.deb ntp_4.2.6.p5_dfsg-3ubuntu2.14.04.12_amd64.deb
			elif [ "$ostype" == "ubuntu_16" ]; then
				echo_red "$ostype" unsurpposed                                
                                exit
			else
				echo_red "$ostype" unsurpposed
                                exit
			fi
		fi
		done
		
	echo "complete...."
	done
	
	for i in "${IM_HOST[@]}"
	do
                echo "install jdk on node "$i
                ssh -Tq "$i" <<EOF
		mkdir -p /tmp
		sed -i /'umask 077'/d ~/.bashrc
		source ~/.bashrc
		rm -rf "$JDK_DIR"
		mkdir -p "$JDK_DIR"
		chmod 755 "$JDK_DIR"
EOF
                scp -r ../packages/jdk/* "$i":"$JDK_DIR"
                scp ../packages/jce/* "$i":"$JDK_DIR"/jre/lib/security/
                ssh -Tq "$i"  <<EOF
                    chmod 755 "$JDK_DIR"/bin/*
                    sed -i /JAVA_HOME/d /etc/profile
                    echo JAVA_HOME="$JDK_DIR" >> /etc/profile
                    echo PATH='\$JAVA_HOME'/bin:'\$PATH' >> /etc/profile
                    echo CLASSPATH='\$JAVA_HOME'/jre/lib/ext:'\$JAVA_HOME'/lib/tools.jar >> /etc/profile
                    echo export JAVA_HOME CLASSPATH PATH>> /etc/profile
                    source /etc/profile
                    su - $cmpuser
                    sed -i /JAVA_HOME/d ~/.bashrc
                    echo JAVA_HOME="$JDK_DIR" >> ~/.bashrc
                    echo PATH='\$JAVA_HOME'/bin:'\$PATH' >> ~/.bashrc
                    echo CLASSPATH='\$JAVA_HOME'/jre/lib/ext:'\$JAVA_HOME'/lib/tools.jar >> ~/.bashrc
                    echo export JAVA_HOME CLASSPATH PATH>> ~/.bashrc
                    exit
                
EOF
                echo "configure system kernel on node "$i
                ssh -Tq "$i" <<EOF
                    sed -i /$cmpuser/d /etc/security/limits.conf
                    echo $cmpuser soft nproc unlimited >>/etc/security/limits.conf
                    echo $cmpuser hard nproc unlimited >>/etc/security/limits.conf
                    sed -i /limits/d /etc/security/limits.conf
                    echo session required pam_limits.so >>/etc/pam.d/login
                    exit
EOF
		
                echo "complete..." 
	done
	
	
	echo "configure hosts"
	local j=1
	for i in "${IM_HOST[@]}"
	do
		local hname="im_"$j"node"
		ssh -Tq $i <<EOF
		hostnamectl set-hostname "im_"$j"node"
		sed -i /$i/d /etc/hosts
EOF
		echo $i" "$hname >> .hosts
		let j=j+1
	done
	for i in "${IM_HOST[@]}"
	do
		scp .hosts $i:/etc/hosts
		#ssh -Tq $i <<EOF
		#cat ~/.hosts /etc/hosts
		#rm -rf ~/.hosts
		#exit
#EOF
	done
		
	echo "configure ntp"
	#2018.5.22////////////////////////////////////////////////
	for line in $(cat allnodes)
        do
        	SSH_HOST=($line)
        	echo "check nodes"
        	for i in "${SSH_HOST[@]}"
		do
			scp ./ntp.conf $i:/etc/ntp.conf
	
			local ostype=`check_ostype $i`
			if [ "$ostype" == "centos_7" ]; then
				scp ./ntpd "$i":/etc/init.d/
                		ssh -n "$i" systemctl daemon-reload
			fi
		ssh -Tq $i <<EOF
			sed -i '/ntpip/{s/ntpip/$NTPIP/}' /etc/ntp.conf
			chmod u+x /etc/init.d/ntpd
			/etc/init.d/ntpd stop
                	echo "first nysnc ntp server..."
                	ntpdate $NTPIP &>/dev/null && echo " sync ntp success!" || echo "sync ntp failed,please check it!"
			/etc/init.d/ntpd restart
			exit
EOF
		done
	done
	#//////////////////////////////////////////////////////////
	rm -rf .hosts
	rm -rf allnodes

	echo_green "check env success..."
}


install_redis(){
	echo_green "install redis..."
	local k=1
	local mip="${REDIS_HOST[0]}"
	local mport=7000
	local rport=7000
	local sport=7001
	for i in "${REDIS_HOST[@]}"
                do
                echo "install redis on node "$i
		ssh -n "$i" mkdir -p "$REDIS_DIR"
		chmod -R 744 ../packages/redis/*
                scp -r ../packages/redis/* "$i":"$REDIS_DIR"
                
		ssh -Tq $i <<EOF
		cd $REDIS_DIR
		make
		make install
EOF
		
		if [ "$k" -eq 1 ]; then
                        scp ./redismaster.conf "$i":"$REDIS_DIR"/redismaster.conf
			ssh -Tq $i <<EOF
			sed -i 's/redismport/$mport/g' "$REDIS_DIR"/redismaster.conf
			sed -i 's/redismip/$i/g' "$REDIS_DIR"/redismaster.conf
			redis-server "$REDIS_DIR"/redismaster.conf
			sed -i /redismaster/d /etc/rc.d/rc.local
			echo redis-server "$REDIS_DIR"/redismaster.conf >>/etc/rc.d/rc.local
                        chmod u+x /etc/rc.d/rc.local
EOF
                elif [ "$k" -gt 1 ]; then
			scp ./redisslave.conf "$i":"$REDIS_DIR"/redisslave.conf
			ssh -Tq $i <<EOF
                        sed -i 's/redisrport/$rport/g' "$REDIS_DIR"/redisslave.conf
			sed -i 's/redismport/$mport/g' "$REDIS_DIR"/redisslave.conf
                        sed -i 's/redisrip/$i/g' "$REDIS_DIR"/redisslave.conf
			sed -i 's/redismip/$mip/g' "$REDIS_DIR"/redisslave.conf
                        redis-server "$REDIS_DIR"/redisslave.conf
			sed -i /redisslave/d /etc/rc.d/rc.local
			echo redis-server "$REDIS_DIR"/redisslave.conf >>/etc/rc.d/rc.local
                	chmod u+x /etc/rc.d/rc.local
EOF
                fi
			scp ./redissentinel.conf "$i":"$REDIS_DIR"/redissentinel.conf
                        ssh -Tq $i <<EOF
                        sed -i 's/redismport/$mport/g' "$REDIS_DIR"/redissentinel.conf
			sed -i 's/redissport/$sport/g' "$REDIS_DIR"/redissentinel.conf
                        sed -i 's/redissip/$i/g' "$REDIS_DIR"/redissentinel.conf
			sed -i 's/redismip/$mip/g' "$REDIS_DIR"/redissentinel.conf
                        redis-sentinel "$REDIS_DIR"/redissentinel.conf
			sed -i /redis-sentinel/d /etc/rc.d/rc.local
			echo redis-sentinel "$REDIS_DIR"/redissentinel.conf >>/etc/rc.d/rc.local
                	chmod u+x /etc/rc.d/rc.local
EOF
		echo "complete..."
	let k=k+1
	done
	echo_green "install redis on all nodes success..."
}


ssh-interconnect(){
	echo_green "create ssh..."
	local ssh_init_path=./ssh-init.sh
        
	allnodes_get
        for line in $(cat allnodes)
        do
		$ssh_init_path $line
		if [ $? -eq 1 ]; then
			exit 1
		fi
	done
	rm -rf allnodes
	echo_green "complete..."
}


user-internode(){
	echo_green "create user..."
	local ssh_pass_path=./ssh-pass.sh
       
        for i in "${IM_HOST[@]}"
        do
			echo =======$i=======
			ssh -Tq $i <<EOF
			groupadd $cmpuser
 			useradd -m -s  /bin/bash -g $cmpuser $cmpuser
 			usermod -G $cmpuser $cmpuser
			echo "$cmpuser:$cmppass" | chpasswd
			exit
EOF
	done
	echo_green "complete..."
        
}


copy-internode(){
     echo_green "copping IM packages..."
     
     case $nodeplanr in
	  [1-4]) 
            
            for i in "${IM_HOST[@]}"
            do
			echo "copping im files to node "$i 
			
			ssh -n $i mkdir -p $CURRENT_DIR
			scp -r ./background ./im ./config startIM.sh startIM_BX.sh stopIM.sh im.config imstart_chk.sh startkeepalived.sh "$i":$CURRENT_DIR
			
			ssh -Tq $i <<EOF
			rm -rf /tmp/spring.log
			rm -rf /tmp/modelTypeName.data
			chown -R $cmpuser.$cmpuser $CURRENT_DIR
			chmod 740 "$CURRENT_DIR"
 	        	chmod 740 "$CURRENT_DIR"/*.sh
			chmod 755 "$CURRENT_DIR"/startkeepalived.sh
			chmod 740 "$CURRENT_DIR"/background
			chmod 640 "$CURRENT_DIR"/background/*.jar
			chmod 740 "$CURRENT_DIR"/config
			chmod 740 "$CURRENT_DIR"/im
			chmod 640 "$CURRENT_DIR"/im/*.jar
			chmod 740 "$CURRENT_DIR"/background/*.sh
			chmod 740 "$CURRENT_DIR"/im/*.sh
			chmod 640 "$CURRENT_DIR"/im/*.war
			chmod 600 "$CURRENT_DIR"/im.config
			chmod 600 "$CURRENT_DIR"/config/*.yml
			su $cmpuser
			umask 077
	#		rm -rf "$CURRENT_DIR"/data
			mkdir -p "$CURRENT_DIR"/data
	#		rm -rf "$CURRENT_DIR"/activemq-data
			mkdir -p "$CURRENT_DIR"/activemq-data
			rm -rf "$CURRENT_DIR"/logs
			mkdir  "$CURRENT_DIR"/logs
			rm -rf "$CURRENT_DIR"/temp
			mkdir  "$CURRENT_DIR"/temp
			exit
EOF
		echo "complete..."
	   done
	    ;;
	  0) 
	    echo "nothing to do...."
	    ;;
	 esac
	echo_green "complete..."
}

env_internode(){
        
		echo_green "configure im parameter..."
		
		local k=0
		cat haiplist | while read line
            	do
                echo "nodes configure"
		local t=1
		SSH_HOST=($line)
		for j in "${SSH_HOST[@]}"
			do
			
			echo "configure node "$j
			
			if [ "$k" -eq 0 ]; then
				hanoder="main"
			else 
				hanoder="rep"
				
			fi
			lines=`sed -n "$t"p ./im.config`
                        nodes=($lines)
                        nodeplanr=${nodes[0]}
                        nodetyper=${nodes[1]}
                        nodenor=${nodes[2]}
                        dcnamer=${nodes[3]}
			eurekaipr=${nodes[4]}
                        eurekaiprepr=${nodes[5]}
			
			
			echo_yellow "nodeplan="$nodeplanr
			echo_yellow "nodetype="$nodetyper
			echo_yellow "nodeno="$nodenor	
			echo_yellow "eurekaip="$eurekaipr
			echo_yellow "dcname="$dcnamer
			echo_yellow "eurekaiprep="$eurekaiprepr
			echo_yellow "hanode="$hanoder

			
			ssh -Tq $j <<EOF
            		sed -i /nodeplan/d /etc/environment
			sed -i /nodetype/d /etc/environment
			sed -i /nodeno/d /etc/environment
			sed -i /eurekaip/d /etc/environment
			sed -i /dcname/d /etc/environment
			sed -i /eurekaiprep/d /etc/environment
                        sed -i /hanode/d /etc/environment
			sed -i /CMP_DIR/d /etc/environment
			sed -i /activemqpath/d /etc/environment
			sed -i /zuulvip/d /etc/environment
			
			echo "nodeplan=$nodeplanr">>/etc/environment
			echo "nodetype=$nodetyper">>/etc/environment
			echo "nodeno=$nodenor">>/etc/environment 
			echo "eurekaip=$eurekaipr">>/etc/environment
			echo "dcname=$dcnamer">>/etc/environment
			echo "eurekaiprep=$eurekaiprepr">>/etc/environment
                        echo "hanode=$hanoder">>/etc/environment
			echo "CMP_DIR=$CURRENT_DIR">>/etc/environment
			echo "export CMP_DIR" >> /etc/environment
			echo activemqpath='\$CMP_DIR'/data >> /etc/environment
                        echo "export activemqpath" >> /etc/environment
                        echo "zuulvip=$VIP" >> /etc/environment
                        echo "export zuulvip" >> /etc/environment
			echo "export nodeplan nodetype nodeno eurekaip dcname eurekaiprep hanode">>/etc/environment
			source /etc/environment

			su - $cmpuser
			sed -i /nodeplan/d ~/.bashrc
                        sed -i /nodetype/d ~/.bashrc
                        sed -i /nodeno/d ~/.bashrc
                        sed -i /eurekaip/d ~/.bashrc
                        sed -i /dcname/d ~/.bashrc
			sed -i /umask/d ~/.bashrc
			sed -i /eurekaiprep/d ~/.bashrc
                        sed -i /hanode/d ~/.bashrc
			sed -i /CMP_DIR/d ~/.bashrc
			echo "umask 077" >> ~/.bashrc
			sed -i /IM_IP/d ~/.bashrc
			sed -i /activemqpath/d ~/.bashrc
			sed -i /zuulvip/d ~/.bashrc

			echo "CMP_DIR=$CURRENT_DIR" >> ~/.bashrc
			echo "export CMP_DIR" >> ~/.bashrc
			echo "nodeplan=$nodeplanr">>~/.bashrc
                        echo "nodetype=$nodetyper">>~/.bashrc
                        echo "nodeno=$nodenor">>~/.bashrc 
                        echo "eurekaip=$eurekaipr">>~/.bashrc
                        echo "dcname=$dcnamer">>~/.bashrc
			echo "eurekaiprep=$eurekaiprepr">>~/.bashrc
                        echo "hanode=$hanoder">>~/.bashrc
			echo "IM_IP=$j">>~/.bashrc
			echo "export IM_IP">>~/.bashrc
			echo activemqpath='\$CMP_DIR'/data >> ~/.bashrc
                        echo "export activemqpath" >> ~/.bashrc
			echo "zuulvip=$VIP" >> ~/.bashrc
                        echo "export zuulvip" >> ~/.bashrc
                        echo "export nodeplan nodetype nodeno eurekaip dcname eurekaiprep hanode">>~/.bashrc
                        source ~/.bashrc
			exit
EOF
		echo "complete..." 
		let t=t+1
		done
		echo "nodes group complete..."
		let k=k+1
	done
	#20180418 add gf nodes
	k=0
	if [ -s dciplist ]; then
		for j in "${GF_HOST[@]}"
                do
                	echo "configure on node "$j  
                        nodetyper=2
                        nodeplanr=0
                        nodenor=0
                        b=$(( $k % 2 ))
                        if [ "$b" -eq 0 ]; then
                                hanoder="main"
                        else
                                hanoder="rep"

                        fi
                        lines=`sed -n 1p ./im.config`
                        nodes=($lines)
                        dcnamer=${DC_NAMES[$k]}
                        eurekaipr=${nodes[4]}
                        eurekaiprepr=${nodes[5]}
                        echo_yellow "nodeplan="$nodeplanr
                        echo_yellow "nodetype="$nodetyper
                        echo_yellow "nodeno="$nodenor  
                        echo_yellow "eurekaip="$eurekaipr
                        echo_yellow "eurekaiprep="$eurekaiprepr
                        echo_yellow "dcname="$dcnamer
                        echo_yellow "hanode="$hanoder

                        echo "node："$j

                        ssh -Tq $j <<EOF
                        sed -i /nodeplan/d /etc/environment
                        sed -i /nodetype/d /etc/environment
                        sed -i /nodeno/d /etc/environment
                        sed -i /eurekaip/d /etc/environment
                        sed -i /eurekaiprep/d /etc/environment
                        sed -i /dcname/d /etc/environment
                        sed -i /hanode/d /etc/environment
                        sed -i /CMP_DIR/d /etc/environment
                        sed -i /activemqpath/d /etc/environment
                        
                        echo "nodeplan=$nodeplanr">>/etc/environment
                        echo "nodetype=$nodetyper">>/etc/environment
                        echo "nodeno=$nodenor">>/etc/environment 
                        echo "eurekaip=$eurekaipr">>/etc/environment
                        echo "eurekaiprep=$eurekaiprepr">>/etc/environment
                        echo "dcname=$dcnamer">>/etc/environment
                        echo "hanode=$hanoder">>/etc/environment
                        echo "CMP_DIR=$CURRENT_DIR">>/etc/environment
                        echo "export CMP_DIR" >> /etc/environment
                        echo activemqpath='\$CMP_DIR'/data >> /etc/environment
                        echo "export activemqpath" >> /etc/environment
                        echo "export nodeplan nodetype nodeno eurekaip dcname eurekaiprep hanode">>/etc/environment
                        source /etc/environment
                        su - $cmpuser
                        sed -i /nodeplan/d ~/.bashrc
                        sed -i /nodetype/d ~/.bashrc
                        sed -i /nodeno/d ~/.bashrc
                        sed -i /eurekaip/d ~/.bashrc
                        sed -i /eurekaiprep/d ~/.bashrc
                        sed -i /dcname/d ~/.bashrc
                        sed -i /hanode/d ~/.bashrc
                        sed -i /IM_IP/d ~/.bashrc
                        sed -i /CMP_DIR/d ~/.bashrc
                        sed -i /activemqpath/d ~/.bashrc
                        
                        echo "umask 077" >> ~/.bashrc
                        echo "nodeplan=$nodeplanr">>~/.bashrc
                        echo "nodetype=$nodetyper">>~/.bashrc
                        echo "nodeno=$nodenor">>~/.bashrc 
                        echo "eurekaip=$eurekaipr">>~/.bashrc
                        echo "eurekaiprep=$eurekaiprepr">>~/.bashrc
                        echo "dcname=$dcnamer">>~/.bashrc 
                        echo "hanode=$hanoder">>~/.bashrc
                        echo "IM_IP=$j">>~/.bashrc
                        echo "export IM_IP">>~/.bashrc
                        echo activemqpath='\$CMP_DIR'/data >> ~/.bashrc
                        echo "export activemqpath" >> ~/.bashrc
                        echo "export nodeplan nodetype nodeno eurekaip dcname eurekaiprep hanode CURRENT_DIR">>~/.bashrc
                        source ~/.bashrc
                        exit
EOF

                echo "complete..." 
                let k=k+1
                done
		
	fi 
		echo_green "configure all nodes success..."
	
}


iptable_imnode(){
        echo_green "configure im--iptables..."
	#2018.3.16
        sed -i '/VIP/{s/VIP/'$VIP'/}' ./iptablescmp.sh
        local iptable_path=./iptablescmp.sh
	local im_iplists=""
        
        for line in "${IM_HOST[@]}"
	do
		im_iplists=${im_iplists}" "${line}
	done
	$iptable_path $im_iplists
	echo_green "complete..."
}


iptable_redisnode(){
        echo_green "configure redis--iptables..."
        ./iptablesredis.sh $REDIS_H
        echo_green "complete..."
}


iptable_mongonode(){
        echo_green "configure mongodb--iptables..."
        ./iptablesmongo.sh $MONGO_H
        echo_green "complete..."
}


keeplived_settings(){
	echo_green "configure keeplived..."
	k=100

	for i in $(cat ./haiplist)
        do
	echo "node "$i
	
	local nplan=`ssh -n $i echo \\$nodeplan`
        local ntype=`ssh -n $i echo \\$nodetype`
        local nno=`ssh -n $i echo \\$nodeno`
	if [ "$nplan" = "1" ] || [ "$ntype" = "1" -a "$nplan" = "2" -a "$nno" = "2" ] || [ "$ntype" = "1" -a "$nplan" = "3" -a "$nno" = "2" ] || [ "$ntype" = "1" -a "$nplan" = "4" -a "$nno" = "3" ] || [ "$ntype" = "3" -a "$nplan" = "2" -a "$nno" = "2" ] || [ "$ntype" = "3" -a "$nplan" = "3" -a "$nno" = "2" ] || [ "$ntype" = "3" -a "$nplan" = "4" -a "$nno" = "3" ]; then
	
	local ostype=`check_ostype $i`
	local keepalived=`ssh -n "$i" rpm -qa |grep keepalived |wc -l`
	if [ "$keepalived" -gt 0 ]; then
		echo "keepalived installed"
	else
		if [ "$ostype" == "centos_6" ]; then
			scp -r ../packages/centos6_keepalived "$i":/root/
			ssh -Tq $i <<EOF
			#del net-snmp 
			rpm -qa | grep keepalived && rpm -qa | grep keepalived | xargs rpm -e ||echo 'clear'
			rpm -qa | grep net-snmp && rpm -qa | grep net-snmp | xargs rpm -e || echo 'clear'
			rpm -qa | grep perl-core && rpm -qa | grep perl-core | xargs rpm -e || echo 'clear'
                        rpm -Uvh --oldpackage --replacepkgs ~/centos6_keepalived/*
			rm -rf ~/centos6_keepalived
                        exit
EOF
		elif [ "$ostype" == "centos_7" ]; then
			scp -r ../packages/centos7_keepalived "$i":/root/
			scp ./keepalived "$i":/etc/init.d/
			ssh -Tq $i <<EOF
			rpm -qa | grep keepalived && rpm -qa | grep keepalived | xargs rpm -e ||echo 'clear'
			rpm -qa | grep net-snmp && rpm -qa | grep net-snmp | xargs rpm -e || echo 'clear'
			rpm -qa | grep perl-core && rpm -qa | grep perl-core | xargs rpm -e || echo 'clear'
			rpm -Uvh --oldpackage --replacepkgs --nodeps ~/centos7_keepalived/*
			rm -rf ~/centos7_keepalived
			exit
EOF
					
		fi
	fi
	ssh -n $i mkdir -p "$KEEPALIVED_DIR"
	scp ./keepalived.conf "$i":/etc/keepalived/
	scp ./checkZuul.sh "$i":"$KEEPALIVED_DIR"
#	local netcard=`ssh -n $i ip addr | grep $i | awk -F ' ' '{print \$7}'`
	local netcard=`ssh -n $i ip addr | grep $i |awk '{s=\$1;\$1=\$NF;\$NF=s;print}' | awk -F ' ' '{print \$1}'`
	ssh -Tq $i <<EOF
                setenforce 0
#                sed -i '/enforcing/{s/enforcing/disabled/}' /etc/selinux/config
		sed -i '/^SELINUX=/cSELINUX=disabled' /etc/sysconfig/selinux
		chmod 740 /usr/local/keepalived/checkZuul.sh
		chmod 740 /etc/init.d/keepalived
		sed -i '/prioweight/{s/prioweight/$k/}' /etc/keepalived/keepalived.conf
		sed -i '/vip/{s/vip/$VIP/}' /etc/keepalived/keepalived.conf
		sed -i '/rip/{s/rip/$i/}' /etc/keepalived/keepalived.conf
		sed -i '/eth0/{s/eth0/$netcard/g}' /etc/keepalived/keepalived.conf
		/etc/init.d/keepalived restart
		exit
EOF
	let k=k-10
	echo "complete..."
	fi
	done
	echo_green "keepalived on all nodes install success..."
}


start_internode(){
	echo_green "start IM service..."
	
	
	cat haiplist | while read line
        do
		local k=0
                SSH_HOST=($line)
                echo "start on node groups"
		for i in "${SSH_HOST[@]}"
		do
			echo "start im on node "$i
			ssh -n $i 'su - '$cmpuser' -c '$CURRENT_DIR'/startIM.sh'
			echo "node "$i"start success"
			break
		done
		
		
		for i in "${SSH_HOST[@]}"
		do
		if [ "$k" -eq 0 ];then
			let k=k+1
			continue
		fi
		echo "start other node "$i
		ssh -nf $i 'su - '$cmpuser' -c '$CURRENT_DIR'/startIM_BX.sh > /dev/null'
		let k=k+1
		echo "send single command"
		done
		
		
		for i in "${SSH_HOST[@]}"
		do
		if [ "$k" -eq 0 ];then
			let k=k+1
			continue
		fi
		echo "check node "$i
		 ssh -Tq $i <<EOF
		 su - $cmpuser
		 source /etc/environment
		 umask 077
		 cd "$CURRENT_DIR"
		 ./imstart_chk.sh
		 exit
EOF
		let k=k+1
		echo "complete..."
		done

	
                for i in "${SSH_HOST[@]}"
                do
                 ssh -Tq $i <<EOF
                 source /etc/environment
                 cd "$CURRENT_DIR"
                 ./startkeepalived.sh
                 exit
EOF
                done
	done

	#20180418 add gf node start 
	for i in "${GF_HOST[@]}"
                do
                echo "start node "$i
                ssh -nf $i 'su - '$cmpuser' -c '$CURRENT_DIR'/startIM_BX.sh >/dev/null'
                echo "send single command"
                done

                for i in "${GF_HOST[@]}"
                do
                echo "start other node "$i
                 ssh -Tq $i <<EOF
                 su - $cmpuser
                 source /etc/environment
                 umask 077
                 cd "$CURRENT_DIR"
                 ./imstart_chk.sh
                 exit
EOF
                echo "start success"
        done
	echo_green "all nodes start im success..."
}


stop_internode(){
	echo_green "shutdown im service..."
	for i in "${IM_HOST[@]}"
	do
		echo "stop im service on node "$i
		#local user=`ssh -n $i cat /etc/passwd | sed -n /$cmpuser/p |wc -l`
		local user=`ssh -n $i cat /etc/passwd | awk -F : '{print \$1}' | grep -w $cmpuser |wc -l`
		if [ "$user" -eq 1 ]; then
			local jars=`ssh -n $i ps -u $cmpuser | grep -v PID | wc -l`
			if [ "$jars" -gt 0 ]; then
				ssh -Tq $i <<EOF
				killall -9 -u $cmpuser
				exit
EOF
				echo "complete"
			else
				echo "CMP stopped"
			fi
		else
			echo_yellow "not exists user $cmpuser,please shutdown on manual!"
		#	exit
		fi
		
	done

	
	for i in "${REDIS_HOST[@]}"
        do
		echo "shutdown redis on node "$i
        	local rediss=`ssh -n $i lsof -n | grep redis | wc -l`
		if [ "$rediss" -gt 0 ]; then
                	ssh -Tq $i <<EOF
				pkill redis
EOF
		fi
	done

        
	if [ "$MONGO_H" != "" ]; then
        	for i in "${MONGO_HOST[@]}"
        	do      
                	echo "shutdown mongo on node "$i
                	local mongos=`ssh -n $i lsof -n | grep mongo | wc -l`
                	if [ "$mongos" -gt 0 ]; then
                        	ssh -Tq $i <<EOF
                                	killall -9 -u mongo
EOF
               	 	fi
        	done
	fi
	
	
	 for i in $(cat haiplist)
        do
        
        local nplan=`ssh -n $i echo \\$nodeplan`
        local ntype=`ssh -n $i echo \\$nodetype`
        local nno=`ssh -n $i echo \\$nodeno`
        if [ "$nplan" = "1" ] || [ "$ntype" = "1" -a "$nplan" = "2" -a "$nno" = "2" ] || [ "$ntype" = "1" -a "$nplan" = "3" -a "$nno" = "2" ] || [ "$ntype" = "1" -a "$
nplan" = "4" -a "$nno" = "3" ] || [ "$ntype" = "3" -a "$nplan" = "2" -a "$nno" = "2" ] || [ "$ntype" = "3" -a "$nplan" = "3" -a "$nno" = "2" ] || [ "$ntype" = "3" -a "
$nplan" = "4" -a "$nno" = "3" ]; then
        local keepalived=`ssh -n "$i" lsof -n |grep keepalived |wc -l`
        if [ "$keepalived" -gt 0 ]; then
		echo "shutdown keepalived on node "$i
                ssh -n $i pkill keepalived
	fi
	fi
	done

	echo_green "all nodes shutdown success..."
}

uninstall_internode(){
	echo_green "uninstall (im,redis,mongo,iptables,keepalived)..."

	for i in "${IM_HOST[@]}"
	do
		echo "remove im package on node "$i
		ssh -Tq $i <<EOF
		rm -rf "$CURRENT_DIR"
		rm -rf /home/$cmpuser/
		rm -rf /usr/java/
		rm -rf /tmp/*
		sed -i /'umask 077'/d ~/.bashrc
		source ~/.bashrc
		exit
EOF
		echo "remove keepalived package on node "$i
                local keepaliveds=`ssh -n $i rpm -qa | grep keepalived`
                if [ "$keepaliveds" != "" ]; then
                                ssh -Tq $i <<EOF
				/etc/init.d/keepalived stop
                                rpm -e $keepaliveds
                                exit
EOF
                fi
	done


	
	for i in "${REDIS_HOST[@]}"
        do
                echo "remove redis package on node "$i
                ssh -Tq $i <<EOF
                rm -rf "$REDIS_DIR"
		rm -rf /tmp/*
                exit
EOF
        done
	
	if [ "$MONGO_H" != "" ]; then 
        for i in "${MONGO_HOST[@]}"
        do
                echo "remove mongo package on node "$i
                ssh -Tq $i <<EOF
                rm -rf "$MONGDO_DIR"
		rm -rf "$MONGDO_ARBITER_DIR"1
		rm -rf "$MONGDO_ARBITER_DIR"2
		rm -rf /home/mongo
		rm -rf /tmp/*
                exit
EOF
        done
	fi

        for i in "${IM_HOST[@]}"
        do               
		echo "remove im user on node "$i
		local imuser=`ssh -n $i cat /etc/passwd | sed -n /$cmpuser/p |wc -l`
                if [ "$imuser" -gt 0 ]; then
			ssh -n $i userdel -f $cmpuser
		fi
	done
	
	if [ "$MONGO_H" != "" ]; then
        for i in "${MONGO_HOST[@]}"
        do
                echo "remove mongo user on node "$i
                local mongouser=`ssh -n $i cat /etc/passwd | sed -n /mongo/p |wc -l`
                if [ "$mongouser" -eq 1 ]; then
                        ssh -n $i userdel -f mongo
                fi
        done
	fi

        for i in "${IM_HOST[@]}"
        do
                echo "delete cmpiptables on node "$i
		local iptables=`ssh -n $i iptables -L INPUT | sed -n /cmp/p |wc -l`
		if [ "$iptables" -gt 0 ]; then
		ssh -Tq $i <<EOF
		iptables -P INPUT ACCEPT
		iptables -D INPUT -j cmp
		iptables -F cmp
		iptables -X cmp
		iptables -F -t nat
		iptables-save > /etc/iptables
		iptables-save > /etc/sysconfig/iptables
		exit
EOF
		fi
		echo "complete..."
	done

        for i in "${REDIS_HOST[@]}"
        do
                echo "delete redis's iptables"$i
                local iptables=`ssh -n $i iptables -L INPUT | sed -n /redis/p |wc -l`
                if [ "$iptables" -gt 0 ]; then
                ssh -Tq $i <<EOF
                iptables -P INPUT ACCEPT
                iptables -D INPUT -j redisdb
                iptables -F redisdb
                iptables -X redisdb
                iptables-save > /etc/iptables
                iptables-save > /etc/sysconfig/iptables
                exit
EOF
                fi

		echo "complete..."
	done
	
	if [ "$MONGO_H" != "" ]; then
       		for i in "${MONGO_HOST[@]}"
        		do
                	echo "delete mongodb's iptables"$i
                	local iptables=`ssh -n $i iptables -L INPUT | sed -n /mongodb/p |wc -l`
                	if [ "$iptables" -gt 0 ]; then
                	ssh -Tq $i <<EOF
                	iptables -P INPUT ACCEPT
                	iptables -D INPUT -j mongodb
                	iptables -F mongodb
                	iptables -X mongodb
                	iptables-save > /etc/iptables
                	iptables-save > /etc/sysconfig/iptables
                	exit
EOF
                	fi
                	echo "complete..."
        	done
	fi

	echo_green "uninstall success..."
}



mongo_install(){
	echo_green "install mongodb"
	local k=1
	for i in "${MONGO_HOST[@]}"
        do
                echo "install on node"$i
		ssh -n "$i" mkdir -p "$MONGDO_DIR"
		scp -r ../packages/mongo/* "$i":"$MONGDO_DIR"
		ssh -Tq $i <<EOF
		echo "create mongo user"
		groupadd mongo
		useradd -r -m -g  mongo mongo
		echo "flush privileges"
		chown -R mongo.mongo $MONGDO_DIR
		chmod 700 $MONGDO_DIR/bin/*
		chmod 600 $MONGDO_DIR/mongo.key
		sed -i /mongo/d ~/.bashrc
                echo export PATH=$MONGDO_DIR/bin:'\$PATH' >> ~/.bashrc
                source ~/.bashrc
		su - mongo
		cd $MONGDO_DIR
		umask 077
		mkdir -p data/logs
		mkdir -p data/db
		echo "start mongodb"
		nohup ./bin/mongod --port=31001 --dbpath=$MONGDO_DIR/data/db --logpath=$MONGDO_DIR/data/logs/mongodb.log --replSet dbReplSet --oplogSize 10240  &>/dev/null &
		echo "configure env"
		sed -i /mongo/d ~/.bashrc
		echo export PATH=$MONGDO_DIR/bin:'\$PATH' >> ~/.bashrc
		source ~/.bashrc
		exit
EOF
	echo "complete..."
	done

	local j=1
        for i in "${MONGO_HOST[@]}"
        do
                if [ "$j" -lt 3 ]; then
		local v=1
                while [ $v -le $MONGO_ARBITER_NODES ]
		do
                echo "install Arbitration node..."$i
                ssh -n "$i" mkdir -p "$MONGDO_ARBITER_DIR""$v"
                scp -r ../packages/mongo/* "$i":"$MONGDO_ARBITER_DIR""$v"
		local port=31001
		let port=$port+$v
                ssh -Tq $i <<EOF
                echo "flush privileges"
                chown -R mongo.mongo "$MONGDO_ARBITER_DIR""$v"
                chmod 700 "$MONGDO_ARBITER_DIR""$v"/bin/*
                chmod 600 "$MONGDO_ARBITER_DIR""$v"/mongo.key
                su - mongo
                cd "$MONGDO_ARBITER_DIR""$v"
                umask 077
                mkdir -p data/logs
                mkdir -p data/db
                sed -i '/31001/{s/31001/$port/}' "$MONGDO_ARBITER_DIR""$v"/mongodb.conf
                sed -i '/mongodb/{s/mongodb/mongodb_arbiter$v/}' "$MONGDO_ARBITER_DIR""$v"/mongodb.conf
                echo "start mongodb_arbiter"
                nohup ./bin/mongod --port=$port --dbpath="$MONGDO_ARBITER_DIR""$v"/data/db --logpath="$MONGDO_ARBITER_DIR""$v"/data/logs/mongodb.log --replSet dbReplSet &>/dev/null &
                exit
EOF
	echo "complete..."
	v=$(($v+1))
	done
        fi
        let j=j+1
        done

	sleep 20
	echo "configure monogo"
	for i in "${MONGO_HOST[@]}"
	do
		if [ "$k" -eq 1 ]; then
		
		declare -a MONGOS=($MONGO_H $MONGO_USER $MONGO_PASSWORD) 
		if [ $MONGO_ARBITER_NODES -eq 0 ]; then
		scp ./init_mongo.sh "$i":/root/
		ssh -n $i /root/init_mongo.sh "${MONGOS[@]}"
		elif [ $MONGO_ARBITER_NODES -eq 1 ]; then
		scp ./init_mongo1.sh "$i":/root/
		ssh -n $i /root/init_mongo1.sh "${MONGOS[@]}"
		elif [ $MONGO_ARBITER_NODES -eq 2 ]; then
		scp ./init_mongo2.sh "$i":/root/
		ssh -n $i /root/init_mongo2.sh "${MONGOS[@]}"
		fi
	fi
	echo "configure auth"
	ssh -Tq $i <<EOF
		echo "configure on bootstrap"
		sed -i /mongo/d /etc/rc.d/rc.local
        	echo "su - mongo -c '$MONGDO_DIR/bin/mongod --config $MONGDO_DIR/mongodb.conf'" >> /etc/rc.d/rc.local
		if [ "$k" -lt 3 ]; then
			
			if [ $MONGO_ARBITER_NODES -gt 0 ]; then
                		echo "su - mongo -c '"$MONGDO_ARBITER_DIR"1/bin/mongod --config "$MONGDO_ARBITER_DIR"1/mongodb.conf'" >> /etc/rc.d/rc.local
			fi
                	if [ $MONGO_ARBITER_NODES -gt 1 ]; then
				echo "su - mongo -c '"$MONGDO_ARBITER_DIR"2/bin/mongod --config "$MONGDO_ARBITER_DIR"2/mongodb.conf'" >> /etc/rc.d/rc.local
			fi
		fi
        	chmod u+x /etc/rc.d/rc.local
		
		killall -9 -u mongo
		sleep 20
		su - mongo
		cd $MONGDO_DIR
		echo "restart mongodb"
		nohup ./bin/mongod --config mongodb.conf  &>/dev/null &
		if [ "$k" -lt 3 ]; then
			
                        if [ $MONGO_ARBITER_NODES -gt 0 ]; then
	                	nohup "$MONGDO_ARBITER_DIR"1/bin/mongod --config "$MONGDO_ARBITER_DIR"1/mongodb.conf  &>/dev/null &
			fi
			if [ $MONGO_ARBITER_NODES -gt 1 ]; then
				nohup "$MONGDO_ARBITER_DIR"2/bin/mongod --config "$MONGDO_ARBITER_DIR"2/mongodb.conf  &>/dev/null &
			fi
                fi
EOF
	echo "complete..."
	let k=k+1
	done
	echo_green "all nodes install success"
}


#echo "1-----4 servers, each 16G memory .3 control nodes, a collection node (no mongodb installation)"
#echo "2-----4 servers, each 16G memory .3 control nodes, a collection node (mongodb installation)" 
#echo "100---Clear the deployment (mysql is not affected, but the upgrade environment banned)"

#while read item
#do
  case $item in
    [1])
        nodeplanr=3
		ssh-interconnect
		user-internode
		install-interpackage
		iptable_redisnode
		install_redis
	#	mongo_install
		copy-internode
		env_internode
		iptable_imnode
		keeplived_settings
		start_internode
 #       break
        ;;
    [2])
        nodeplanr=3
		ssh-interconnect
		user-internode
		install-interpackage
		iptable_redisnode
		install_redis
		iptable_mongonode
		mongo_install
		copy-internode
		env_internode
		iptable_imnode
		keeplived_settings
		start_internode
  #      break
        ;;
     100)
		ssh-interconnect
		stop_internode
		uninstall_internode
#	break;
	;;
     0)
        echo "exit"
        exit 0
        ;;
     *)
        echo_red "error,please input again！"
        ;;
  esac
#done

#end
