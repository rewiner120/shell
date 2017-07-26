#!/bin/bash
currTime=`date +%Y%m%d%H`
date_w=`date +%w`
FILE_PATH="/usr/local/mysql"
back_date=`date +%F_%H-%M-%S`
/usr/bin/innobackupex --defaults-file=/etc/my.cnf --user=backup --host=127.0.0.1 --password=backup --stream=tar ${FILE_PATH} |gzip >${FILE_PATH}/${back_date}.tar.gz


#测试键入

