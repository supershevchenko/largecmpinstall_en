#!/bin/bash
#set -x
#set -eo pipefail
shopt -s nullglob
source ./colorecho
nodetyper=1
nodeplanr=1
nodenor=1
eurekaipr=localhost
dcnamer="DC1"
eurekaiprepr=localhost
hanoder="main"
JDK_DIR="/usr/java"
KEEPALIVED_DIR="/usr/local/keepalived"
item=1
#---------------settings------------------
CURRENT_DIR="/springcloudcmp"
cmpuser="cmpimuser"
cmppass="Pbu4@123"
#-----------------------------------------------
declare -a SSH_HOST=()


allnodes_get(){
        cat haiplist > .allnodes
        cat dciplist >> .allnodes
        ip_regex="[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}"
        cat .allnodes | egrep -o "$ip_regex" | sort | uniq > allnodes
        rm -rf .allnodes
}

check_ostype(){
	local ostype=`ssh -n $1 head -n 1 /etc/issue | awk '{print $1}'`
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
	echo_green "configure environment..."
	allnodes_get
	echo "check nodes"
	for i in $(cat allnodes)
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
		elif [ "$os" == "ubuntu" ]; then
			if [ "$ostype" == "ubuntu_12" ]; then
				echo_red "$ostype"unsupported
				exit
			elif [ "$ostype" == "ubuntu_14" ]; then
				scp  ../packages/ubuntu14/* "$i":/root/
                                ssh -n $i dpkg -i ~/lsof_4.86+dfsg-1ubuntu2_amd64.deb ~/iptables_1.4.21-1ubuntu1_amd64.deb ~/libnfnetlink0_1.0.1-2_amd64.deb ~/libxtables10_1.4.21-1ubuntu1_amd64.deb ~/psmisc_22.20-1ubuntu2_amd64.deb
			elif [ "$ostype" == "ubuntu_16" ]; then
				echo_red "$ostype"unsupported                          
                                exit
			else
				echo_red "$ostype"unsupported
                                exit
			fi
		fi
		
                echo "install jdk on node "$i
                ssh -Tq "$i" <<EOF
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
	rm -rf allnodes
	echo_green "check success..."
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
        allnodes_get
        for i in $(cat allnodes)
        do
			echo =======$i=======
			ssh -Tq $i <<EOF
			groupadd $cmpuser
 			useradd -m -s  /bin/bash -g $cmpuser $cmpuser
 			usermod -G $cmpuser $cmpuser
			echo "$cmpuser:$cmppass" | chpasswd
EOF
	done
	rm -rf allnodes
	echo_green "complete..."
        
}


copy-internode(){
     echo_green "copping im files..."
     
     case $nodeplanr in
	  [1-4]) 
            allnodes_get
            for i in $(cat allnodes)
            do
			echo "copy im file to node "$i 
			
			ssh -n $i mkdir -p $CURRENT_DIR
			scp -r ./background ./im ./config startIM.sh startIM_BX.sh stopIM.sh im.config imstart_chk.sh "$i":$CURRENT_DIR
		
			ssh -Tq $i <<EOF
			rm -rf /tmp/spring.log
			rm -rf /tmp/modelTypeName.data
			chown -R $cmpuser.$cmpuser $CURRENT_DIR
			chmod 740 "$CURRENT_DIR"
 	        	chmod 740 "$CURRENT_DIR"/*.sh
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
	   rm -rf allnodes
	    ;;
	  0) 
	    echo "nothing to do...."
	    ;;
	 esac
	echo_green "complete..."
}


env_internode(){
        
		echo_green "configure env on each node..."
		allnodes_get
		for j in $(cat allnodes)
		do
			echo "configure node "$j
			ssh -Tq $j <<EOF			
			source /etc/environment
			su - $cmpuser

			sed -i /"umask 077"/d ~/.bashrc
			sed -i /nodeplan/d ~/.bashrc
         		sed -i /nodetype/d ~/.bashrc
           	 	sed -i /nodeno/d ~/.bashrc
            		sed -i /eurekaip/d ~/.bashrc
            		sed -i /dcname/d ~/.bashrc
			sed -i /eurekaiprep/d ~/.bashrc
                        sed -i /hanode/d ~/.bashrc
			sed -i /CMP_DIR/d ~/.bashrc
			sed -i /IM_IP/d ~/.bashrc
			sed -i /zuulvip/d ~/.bashrc
			
			echo "umask 077" >> ~/.bashrc
			echo "CMP_DIR=$CURRENT_DIR" >> ~/.bashrc
			echo "export CMP_DIR">>~/.bashrc
			sed -n /"nodeplan="/p /etc/environment>>~/.bashrc 
			echo "export nodeplan">>~/.bashrc
			sed -n /"nodetype="/p /etc/environment>>~/.bashrc
			echo "export nodetype">>~/.bashrc
			sed -n /"nodeno="/p /etc/environment>>~/.bashrc
			echo "export nodeno">>~/.bashrc
			sed -n /"eurekaip="/p /etc/environment>>~/.bashrc
			echo "export eurekaip">>~/.bashrc
			sed -n /"dcname="/p /etc/environment>>~/.bashrc 
			echo "export dcname">>~/.bashrc
			sed -n /"eurekaiprep="/p /etc/environment>>~/.bashrc 
			echo "export eurekaiprep">>~/.bashrc
			sed -n /"hanode="/p /etc/environment>>~/.bashrc 
			echo "export hanode">>~/.bashrc
			echo "IM_IP=$j">>~/.bashrc
			echo "export IM_IP">>~/.bashrc
			sed -n /"zuulvip="/p /etc/environment>>~/.bashrc 
                        echo "export zuulvip">>~/.bashrc
                        source ~/.bashrc
			exit
EOF
		
		echo "complete..." 
		done
		rm -rf allnodes
		echo_green "configure success..."
	
}

iptable_imnode(){
        echo_green "configure im--iptables..."
        local iptable_path=./iptablescmp.sh
	local im_iplists=""
        allnodes_get
        for line in $(cat allnodes)
	do
		im_iplists=${im_iplists}" "${line}
	done
	$iptable_path $im_iplists
	rm -rf allnodes
	echo_green "complete..."
}



start_internode(){
	echo_green "start im services..."

	cat haiplist | while read line
        do
		local k=0
                SSH_HOST=($line)
                echo "start im on node groups"
		for i in "${SSH_HOST[@]}"
		do
			echo "start im on node "$i
			ssh -n $i 'su - '$cmpuser' -c '$CURRENT_DIR'/startIM.sh'
			echo "node "$i" start success"
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
		echo "node start success"
		done
	done
	#2018.0418....
	if [ -s dciplist ]; then
		for i in $(cat dciplist)
		do
			echo "start dc node "$i
                	ssh -nf $i 'su - '$cmpuser' -c '$CURRENT_DIR'/startIM_BX.sh > /dev/null'
                	echo "send single command"
		done
        
		for i in $(cat dciplist)
        	do
			echo "check dc node "$i
                 	ssh -Tq $i <<EOF
                 	su - $cmpuser
                 	source /etc/environment
                 	umask 077
                 	cd "$CURRENT_DIR"
                 	./imstart_chk.sh
                 	exit
EOF
                echo "dc node start success"
		done
	fi
	#.............

	echo_green "all nodes start success..."
}

start_keepalived(){
echo_green "start keepalived..."
for i in $(cat haiplist)
        do
	echo "start on node "$i
	local nplan=`ssh -n $i echo \\$nodeplan`
        local ntype=`ssh -n $i echo \\$nodetype`
        local nno=`ssh -n $i echo \\$nodeno`
	if [ "$nplan" = "1" ] || [ "$ntype" = "1" -a "$nplan" = "2" -a "$nno" = "2" ] || [ "$ntype" = "1" -a "$nplan" = "3" -a "$nno" = "2" ] || [ "$ntype" = "1" -a "$nplan" = "4" -a "$nno" = "3" ] || [ "$ntype" = "3" -a "$nplan" = "2" -a "$nno" = "2" ] || [ "$ntype" = "3" -a "$nplan" = "3" -a "$nno" = "2" ] || [ "$ntype" = "3" -a "$nplan" = "4" -a "$nno" = "3" ]; then
	local keepalived=`ssh -n "$i" rpm -qa |grep keepalived |wc -l`
	if [ "$keepalived" -gt 0 ]; then
		scp ./checkZuul.sh "$i":"$KEEPALIVED_DIR"
		ssh -Tq $i <<EOF
                setenforce 0
                sed -i '/enforcing/{s/enforcing/disabled/}' /etc/selinux/config
		chmod 740 /usr/local/keepalived/checkZuul.sh
		/etc/init.d/keepalived restart
		exit
EOF
	fi
	fi
done
echo_green "start success..."
}
#echo "1-----4 servers, each 16G memory .3 control nodes, a collection node"  

#while read item
#do
  case $item in
    [1])
        nodeplanr=3
		ssh-interconnect
		user-internode
		install-interpackage
		copy-internode
		env_internode
		iptable_imnode
		start_internode
		start_keepalived
#        break
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
