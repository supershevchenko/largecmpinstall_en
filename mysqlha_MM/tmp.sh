sed -i "s/gcomm:\/\//&^/g" /etc/my.cnf.d/server.cnf
sed -i "s/\^/10.143.132.189,&/g" /etc/my.cnf.d/server.cnf
sed -i "s/\^/10.143.132.79,&/g" /etc/my.cnf.d/server.cnf
sed -i 's/,^//g' /etc/my.cnf.d/server.cnf
