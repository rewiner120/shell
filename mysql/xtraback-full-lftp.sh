#!/bin/bash
#currTime=`date +%Y%m%d%H`
#date_w=`date +%w`
# Xtrabackup for mysql full backup and put the backup to a remote hosts by lftp


back_date=`date +%F_%H-%M-%S`

FILE_PATH="/data/backup"
FULL_PATH="/data/backup/fullback"
BBS_PATH="/data/backup/bbs"

cd ${FILE_PATH}
/usr/bin/innobackupex --defaults-file=/etc/my.cnf --user=250_db_dump --host=127.0.0.1 --password=250_db_dump ${FULL_PATH}

sleep 6

#put the backup to ftp server
#备份文件到远程FTP服务器
/usr/bin/lftp -u mysqlbackup250,111111 192.168.0.20/mysqlbackup250 <<EOF
mirror -R /data/backup/fullback
exit
EOF

# rm local backup file
#删除备份文件
cd ${FILE_PATH}
rm -fr /data/backup/fullback/*

