#!/bin/bash
#set -x
#set -eo pipefail
shopt -s nullglob
source ./colorecho
MONGDO_DIR="/usr/local/mongodb"
MONGO_IP="10.143.132.185"
MONGO_USER="evuser"
MONGO_PASSWORD="Pbu4@123"

ssh-interconnect(){
        echo_green "create ssh..."
        local ssh_init_path=./ssh-init.sh 
        $ssh_init_path $MONGO_IP
}

mongo_install(){
        echo_green "install mongodb"
                ssh -n $MONGO_IP mkdir -p "$MONGDO_DIR"
                scp -r ../packages/mongo/* "$MONGO_IP":"$MONGDO_DIR"
                ssh -Tq $MONGO_IP <<EOF
		iptables -P INPUT ACCEPT
		iptables-save > /etc/sysconfig/iptables
		sed -i /31001/d /etc/sysconfig/iptables
		sed -i /"-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT"/d /etc/iptables
		iptables-restore < /etc/sysconfig/iptables
                iptables -A INPUT -p tcp --dport 31001 -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
                echo "create mongodb user"
                groupadd mongo
                useradd -r -m -g  mongo mongo
                echo "flush privileges"
                chown -R mongo.mongo $MONGDO_DIR
                chmod 700 $MONGDO_DIR/bin/*
                chmod 600 $MONGDO_DIR/mongo.key
                sed -i /"replSet=dbReplSet"/d $MONGDO_DIR/mongodb.conf
                sed -i /mongo/d ~/.bashrc
                echo export PATH=$MONGDO_DIR/bin:'\$PATH' >> ~/.bashrc
                source ~/.bashrc
                su - mongo
                cd $MONGDO_DIR
                umask 077
                mkdir -p data/logs
                mkdir -p data/db
                echo "start mongodb"
                nohup ./bin/mongod --port=31001 --dbpath=$MONGDO_DIR/data/db --logpath=$MONGDO_DIR/data/logs/mongodb.log  &>/dev/null &
                echo "configure env"
                sed -i /mongo/d ~/.bashrc
                echo export PATH=$MONGDO_DIR/bin:'\$PATH' >> ~/.bashrc
                source ~/.bashrc
                exit
EOF
        sleep 10
        echo "configure monogo"
        declare -a MONGOS=($MONGO_IP $MONGO_USER $MONGO_PASSWORD)
        scp ./init_mongo3.sh "$MONGO_IP":/root/
        ssh -n $MONGO_IP /root/init_mongo3.sh "${MONGOS[@]}"
        echo "auth"
        ssh -Tq $MONGO_IP <<EOF
                echo "configure on bootstrap"
                sed -i /mongo/d /etc/rc.d/rc.local
                echo "su - mongo -c '$MONGDO_DIR/bin/mongod --config $MONGDO_DIR/mongodb.conf'" >> /etc/rc.d/rc.local
                chmod u+x /etc/rc.d/rc.local
                
                pkill mongod
                sleep 10
                su - mongo
                cd $MONGDO_DIR
                echo "restart mongodb"
                nohup ./bin/mongod --config mongodb.conf  &>/dev/null &
EOF
        echo_green "install success"
}

uninstall_mongodb(){
	echo_green "unstall mongodb"
	ssh -Tq $MONGO_IP <<EOF
	pkill mongo
	sleep 2
	userdel -f mongo
	rm -rf /home/mongo
	rm -rf $MONGDO_DIR
	iptables -P INPUT ACCEPT
        iptables-save > /etc/sysconfig/iptables
        sed -i /31001/d /etc/sysconfig/iptables
        sed -i /"-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT"/d /etc/iptables
        iptables-restore < /etc/sysconfig/iptables
EOF
	echo_green "uninstall success"
}

echo "1-----install mongodb"
echo "2-----uninstall mongodb" 

while read item
do
  case $item in
    [1])
	ssh-interconnect
	mongo_install
        break
        ;;
    [2])
	ssh-interconnect
	uninstall_mongodb
        break
        ;;
     0)
        echo "exit"
        exit 0
        ;;
     *)
        echo_red "error,please input again！"
        ;;
  esac
done

