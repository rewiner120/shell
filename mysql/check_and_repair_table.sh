#!/bin/bash
# Using for checking table and repair it
# version 1.0
# author: lijianjun
PATH=/bin:/usr/sbin:/usr/bin:/sbin;export PATH
export LANG=C

username="root"
password="d*2501)^Dp2p*K"
host="127.0.0.1"
port="3306"
#mysql
mysql_conn="/usr/local/mysql/bin/mysql -u${username} -p${password} -h${host} -P${port}"
exec_get_db="select table_schema,table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema','mysql');"
#exec_get_db="select table_schema,table_name FROM information_schema.tables WHERE table_schema IN ('zx_new1023');"
#$(mysql_conn -e "$exec_get_db") >/tmp/check_and_repair_mysql
/usr/local/mysql/bin/mysql -u${username} -p${password} -h${host} -P${port} -e "$exec_get_db" >/tmp/check_and_repair_mysql
sed -i 's/\t/./g' /tmp/check_and_repair_mysql
for db_tb in `cat /tmp/check_and_repair_mysql`
do
	exc_sql="check table $db_tb\G"

	#get info
	status_info=$($mysql_conn -e "$exc_sql" | grep 'Msg_text')


	#get status
	status=${status_info/Msg_text: /}

	# repair table
	if [ "$status" != "OK" ];then
		/usr/local/mysql/bin/mysql -u${username} -p${password} -h${host} -P${port} -e "repair table $db_tb"
		if [ $? -ne 0 ];then
		echo "repair $db_tb failure" >> /opt/shell/check_result.log
		fi
	fi
done
echo "check and repair finish!" >>/opt/shell/check_result.log
