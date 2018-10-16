#!/bin/bash
#set -x
#set -eo pipefail
shopt -s nullglob
source ./colorecho


#---------------settings------------------
CURRENT_DIR="/springcloudcmp"
cmpuser="cmpimuser"
#-----------------------------------------------
declare -a SSH_HOST=()

#
allnodes_get(){
        cat haiplist > .allnodes
        cat dciplist >> .allnodes
        ip_regex="[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}"
        cat .allnodes | egrep -o "$ip_regex" | sort | uniq > allnodes
        rm -rf .allnodes
}

#
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

#
start_internode(){
	echo_green "start im..."
	local k=0
	cat haiplist | while read line
        do
                SSH_HOST=($line)
                echo "start im nodes"
		for i in "${SSH_HOST[@]}"
		do
			echo "start im node "$i
			ssh -Tq $i <<EOF
			su - $cmpuser
			sed -i /IM_IP/d ~/.bashrc
			echo "IM_IP=$i">> ~/.bashrc
			echo "export IM_IP">> ~/.bashrc
			source ~/.bashrc
EOF
			ssh -n $i 'su - '$cmpuser' -c '$CURRENT_DIR'/startIM.sh'
			echo "node $i started..."
			break
		done
		
		for i in "${SSH_HOST[@]}"
		do
		if [ "$k" -eq 0 ];then
			let k=k+1
			continue
		fi
		echo "start node "$i
                ssh -Tq $i<<EOF
                        su - $cmpuser
                        sed -i /IM_IP/d ~/.bashrc
                        echo "IM_IP=$i">> ~/.bashrc
                        echo "export IM_IP">> ~/.bashrc
			source ~/.bashrc
EOF
		ssh -nf $i 'su - '$cmpuser' -c '$CURRENT_DIR'/startIM_BX.sh > /dev/null'
		let k=k+1
		echo "send start command"
		done
		
	
		k=0
		for i in "${SSH_HOST[@]}"
		do
		if [ "$k" -eq 0 ];then
			let k=k+1
			continue
		fi
		echo "check node's im program "$i
		 ssh -Tq $i <<EOF
		 su - $cmpuser
		 source /etc/environment
		 umask 077
		 cd "$CURRENT_DIR"
		 ./imstart_chk.sh
		 exit
EOF
		let k=k+1
		echo "check success"
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

	echo_green "all node im started..."
}


ssh-interconnect
start_internode
