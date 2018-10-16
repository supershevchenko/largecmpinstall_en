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
item=1
#---------------settings------------------
CURRENT_DIR="/springcloudcmp"
cmpuser="cmpimuser"
cmppass="Pbu4@123"
NTPIP="10.143.132.188"
#-----------------------------------------------
#from im_installinit.conf
#GF_H
declare -a GF_HOST=($GF_H)
declare -a SSH_HOST=()
declare -a DC_NAMES=($DC_NAME)

check_nodesip(){
        ip_regex="[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}"
        cat $1 | egrep -o "$ip_regex" | grep $2
}


allnodes_get(){
	cat haiplist > .allnodes
	echo $GF_H >> .allnodes
	echo $GF_H_ALL >> .allnodes
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
	
	echo "check additional node"
	for i in "${GF_HOST[@]}"
            do
		#20180420///////check is same ip,else exit////
		check_nodesip haiplist $i
		if [ $? -eq 1 ]; then
			check_nodesip dciplist $i
			if [ $? -eq 1 ]; then
				echo "........"
			else
				echo_red "gatherframe ip exists dciplist!!please check it,exit!!"
                        	exit 1
			fi
		else
			echo_red "gatherframe ip exists haiplist!!please check it,exit!!"
			exit 1
		fi
		#/////////////////////////////////////////////
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
                                             exit
EOF
                        fi
		elif [ "$os" == "ubuntu" ]; then
			if [ "$ostype" == "ubuntu_12" ]; then
				echo_red "$ostype" unsupported
				exit
			elif [ "$ostype" == "ubuntu_14" ]; then
				scp  ../packages/ubuntu14/* "$i":/root/
                                ssh -n $i dpkg -i ~/lsof_4.86+dfsg-1ubuntu2_amd64.deb ~/iptables_1.4.21-1ubuntu1_amd64.deb ~/libnfnetlink0_1.0.1-2_amd64.deb ~/libxtables10_1.4.21-1ubuntu1_amd64.deb ~/psmisc_22.20-1ubuntu2_amd64.deb ntp_4.2.6.p5_dfsg-3ubuntu2.14.04.12_amd64.deb
			elif [ "$ostype" == "ubuntu_16" ]; then
				echo_red "$ostype" unsupported                                
                                exit
			else
				echo_red "$ostype" unsupported
                                exit
			fi
		fi
		
	echo "complete...."
	done
	
	for i in "${GF_HOST[@]}"
	do
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
	#20180419 configure hosts////////////////////////////////////////////
	echo "configure hosts"
        local j=1
        for i in $(cat haiplist)
        do	
		local hname="im_"$j"node"
                ssh -Tq $i <<EOF
                	hostnamectl set-hostname "im_"$j"node"
                	sed -i /$i/d /etc/hosts
EOF
                echo $i" "$hname >> .hosts
	let j=j+1
	done

	allnodes_get
	for i in $(cat allnodes)
        do
                check_nodesip haiplist $i
                if [ $? -eq 1 ]; then
                        local hname="im_"$j"node"
                        ssh -Tq $i <<EOF
                                hostnamectl set-hostname "im_"$j"node"
                                sed -i /$i/d /etc/hosts
EOF
                        echo $i" "$hname >> .hosts
		let j=j+1		
		fi
        done

        for i in $(cat allnodes)
        do
                scp .hosts $i:/etc/hosts
        done
	#................./////////////////////////////////
	echo "configure ntp"
	for i in "${GF_HOST[@]}"
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

	rm -rf .hosts
	rm -rf allnodes

	echo_green "complete..."
}



ssh-interconnect(){
	echo_green "create ssh..."
	local ssh_init_path=./ssh-init.sh
        for line in "${GF_HOST[@]}"
        do
		$ssh_init_path $line
		if [ $? -eq 1 ]; then
			exit 1
		fi
	done
	echo_green "complete..."
}


user-internode(){
	echo_green "create user..."
	local ssh_pass_path=./ssh-pass.sh
		for i in "${GF_HOST[@]}"
		do
			echo =======$i=======
			ssh -Tq $i <<EOF
			groupadd $cmpuser
 			useradd -m -s  /bin/bash -g $cmpuser $cmpuser
 			usermod -G $cmpuser $cmpuser
			echo "$cmpuser:$cmppass" | chpasswd
EOF
		done
	echo_green "complete..."
        
}


copy-internode(){
	echo_green "copping im files..."
	case $nodeplanr in
          [1-4]) #
                for i in "${GF_HOST[@]}"
                do
                        echo "copy files to node "$i 
                        
                        ssh -n $i mkdir -p $CURRENT_DIR
                        scp -r ./background ./im ./config startIM.sh startIM_BX.sh stopIM.sh imstart_chk.sh  "$i":$CURRENT_DIR
                        
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
                        chmod 600 "$CURRENT_DIR"/config/*.yml
			chmod 600 "$CURRENT_DIR"/config/license.lic
                        su $cmpuser
                        umask 077
        #               rm -rf "$CURRENT_DIR"/data
                        mkdir  "$CURRENT_DIR"/data
        #               rm -rf "$CURRENT_DIR"/activemq-data
                        mkdir  "$CURRENT_DIR"/activemq-data
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


env_gfnode(){
                echo_green "configure additional node environment..."
		local k=0
		local DC_HALL="$GF_H_ALL"
		local DC_NALL="$DC_NAME_ALL"
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
			echo "nodeplan="$nodeplanr
			echo "nodetype="$nodetyper
			echo "nodeno="$nodenor	
			echo "eurekaip="$eurekaipr
			echo "eurekaiprep="$eurekaiprepr
			echo "dcname="$dcnamer
			echo "hanode="$hanoder

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
		#20180419,check same ip,important!!!/////////////////////////////////////
		check_nodesip dciplist $j
		if [ $? -eq 1 ]; then
			echo $j >>./dciplist
			if [ "$DC_HALL" == "" ]; then
				DC_HALL=${j}
                                DC_NALL=${dcnamer}
			else
				DC_HALL=${DC_HALL}" "${j}
				DC_NALL=${DC_NALL}" "${dcnamer}
			fi
		fi
		#///////////////////////////////////////////////////////////////////////
		let k=k+1
		done
		
		sed -i /GF_H_ALL/d im_installinit.conf
                sed -i /DC_NAME_ALL/d im_installinit.conf
                echo GF_H_ALL='"'$DC_HALL'"' >>im_installinit.conf
                echo DC_NAME_ALL='"'$DC_NALL'"' >>im_installinit.conf
		echo_green "all nodes configure complete..."
}


iptable_internode(){
        echo_green "configure iptables..."
        local iptable_path=./iptablescmp.sh
	allnodes_get
        $iptable_path "$(cat allnodes)"
	rm -rf allnodes
	echo_green "complete..."
}


start_internode(){
		echo_green "start gatherframe service..."
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
		echo_green "start all gatherframe nodes success..."
}



#echo "1-----4 servers (each 16G memory .3 control nodes, a collection node) + N expansion of the gahterframe node"

#while read item
#do
  case $item in
    [1])
        nodeplanr=3
		ssh-interconnect
		user-internode
		install-interpackage
		copy-internode
		env_gfnode
		iptable_internode
		start_internode
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
