#!/bin/bash

PATH=/bin:/usr/sbin:/usr/bin:/sbin;export PATH
export LANG=C

#get IP
server_num=`ifconfig | grep 'inet addr:192' | awk '{print $2}' | cut -f 2 -d ":"`
#mysql
mysql_conn="/usr/local/mysql/bin/mysql -umonitor_rep -pmll881216 -h127.0.0.1 -P3308"
exc_sql="show slave status\G"

#get info
io_info=$($mysql_conn -e "$exc_sql" | grep 'Slave_IO_Running')

sql_info=$($mysql_conn -e "$exc_sql" | grep 'Slave_SQL_Running')

#get status
io_status=${io_info/             Slave_IO_Running: /}

sql_status=${sql_info/            Slave_SQL_Running: /}


# send mail

if [ "$io_status" = "Yes" -a "$sql_status" = "Yes" ];
then
echo "replication is normal" | /usr/local/bin/sendEmail -t zhengjing@meilele.com,zhangbaodan@meilele.com -f nagios@meilele.com -s mail.meilele.com:25 -xu nagios -xp mll123456 -u "$server_num server replication is normal"
else
echo "Slave_IO_Running is $io_status and Slave_SQL_Running is $sql_status" | /usr/local/bin/sendEmail -t zhengjing@meilele.com,zhangbaodan@meilele.com -f nagios@meilele.com -s mail.meilele.com:25 -xu nagios -xp mll123456 -u "$server_num server replication error"
fi
