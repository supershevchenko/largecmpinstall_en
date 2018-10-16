#!/bin/bash
source ./colorecho
#passwd="Pbu4@123"
wd=.__tmp__sfsfas
mkdir -p $wd

generate_key(){
    if [[ ! -e "$HOME/.ssh/id_rsa.pub"  ]]; then
        ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa > /dev/null && echo_green "$HOSTNAME succeed in generating ssh key." || echo_red "$HOSTNAME fail to generate ssh key."
    fi
}

generate_key


for i in "$@"
do
echo =======$i=======
ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $i
if [ $? -eq 1 ]; then
	echo_red "error，exit now！"
	exit 1
fi
#expect <<-EOF
#set timeout -1
#spawn  ssh-copy-id -i /root/.ssh/id_rsa.pub $i
#expect {
#"*yes/no" { send "yes\n"; exp_continue }
#"*exist" { send "login ok\n" }
#"*password" { send "${passwd}\n" }
#}
#expect eof
#EOF
done



rm -rf $wd
exit 0
