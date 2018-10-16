#!/bin/bash
#set -x
set -eo pipefail
shopt -s nullglob
source ./colorecho


#--------------settings------------------
CURRENT_DIR="/springcloudcmp"
cmpuser="cmpimuser"
#-----------------------------------------------
declare -a SSH_HOST=()

allnodes_get(){
        cat haiplist > .allnodes
        cat dciplist >> .allnodes
        ip_regex="[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}"
        cat .allnodes | egrep -o "$ip_regex" | sort | uniq > allnodes
        rm -rf .allnodes
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


stop_internode(){
	echo_green "shutdown im on nodes..."
	allnodes_get
	for i in $(cat allnodes)
	do
		echo "shutdown on node "$i
		local user=`ssh -n $i cat /etc/passwd | sed -n /$cmpuser/p |wc -l`
		if [ "$user" -eq 1 ]; then
			local jars=`ssh -n $i ps -u $cmpuser | grep -v PID | wc -l`
			if [ "$jars" -gt 0 ]; then
				ssh -Tq $i <<EOF
			#	killall -9 -u $cmpuser
				pkill -9 -u $cmpuser
				exit
EOF
				echo "complete"
			else
				echo "CMP closed"
			fi
		else
			echo_yellow "not exists user $cmpuser,please shutdown in manual!"
		#	exit
		fi
	done
	rm -rf allnodes
	echo_green "im on all nodes shutdown success..."
}

ssh-interconnect
stop_internode
