#!/bin/bash
mysqlc=( mysql -h127.0.0.1 -uroot -p"$1" )
"${mysqlc[@]}" <<-EOSQL
	GRANT  REPLICATION  client,reload,process,lock tables ON *.* TO "galera"@"%" IDENTIFIED WITH mysql_native_password BY "$4";
	FLUSH PRIVILEGES;
EOSQL
exit 0
