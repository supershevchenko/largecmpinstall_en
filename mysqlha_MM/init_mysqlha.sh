#!/bin/bash
		source ~/.bashrc
		mysqlc=( mysql -h127.0.0.1 -uroot  --connect-expired-password )
		"${mysqlc[@]}" <<-EOSQL 
		ALTER USER 'root'@'localhost' IDENTIFIED WITH sha256_password BY "$1";
		ALTER USER 'root'@'localhost' REQUIRE SSL;
		FLUSH PRIVILEGES;
EOSQL