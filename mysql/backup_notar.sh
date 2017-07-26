#!/bin/bash
currTime=`date +%Y%m%d%H`
date_w=`date +%w`
FILE_PATH="/tools/full"
back_date=`date +%F_%H-%M-%S`
/tools/xtrabackup236/bin/innobackupex --defaults-file=/etc/my.cnf --user=backup --host=127.0.0.1 --password=backup ${FILE_PATH}


#测试键入

