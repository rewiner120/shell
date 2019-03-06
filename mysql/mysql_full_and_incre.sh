#! /bin/sh
# This is mysql full backup and incremental backup shell
# it full backup at every Saturday and Incremental backup other days
# version 1.0
# author : lijianjun@meilele.com


#hostname
hostName=`hostname`
#SendEmail
sendEmailPath="/usr/bin/sendEmail"
Week_Day=`date +%w`
Date_Day=`date +%d`
innobackupex_path="/usr/local/percona-xtrabackup-2.4.4/bin/innobackupex"
cnf_file="/data/mysql_3308/my.cnf"
#backup_path="/data/mysql_backup/3307/"
# tmpfile dir
tmpdir="/data/xbstream_backup/tmp"
#full_backup dir
fullBackupDir="/data/xbstream_backup/full_backup"
#incre_backup dir
increBackupDir="/data/xbstream_backup/incre_backup"
username="backup_user"
password="lwIbWXAp@4#tmn52"
host="127.0.0.1"
filename=`date +%F`
port='3308'
extra_lsndir_file_name=`date +%F_%H-%M-%S`
#全备后的第一次增量
first_increbase_path=`find ${fullBackupDir} -mindepth 1 -maxdepth 1 -type d -printf "%P\n"|sort -n|tail -1`
#其他增量
other_increbase_path=`find ${increBackupDir} -mindepth 1 -maxdepth 1 -type d -printf "%P\n"|sort -n|tail -1`

# 3307 full backup function define
function fullbackup(){
#${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --port=${port} --slave-info --safe-slave-backup --stream=xbstream --parallel=4 --compress --compress-threads=8 --tmpdir=${tmpdir} --extra_lsndir=${fullBackupDir}/${extra_lsndir_file_name} ${fullBackupDir} >${fullBackupDir}/${extra_lsndir_file_name}.xbstream 2>${fullBackupDir}/details.log
#lbzip compress
${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --port=${port} --slave-info --safe-slave-backup --stream=xbstream --parallel=4 --tmpdir=${tmpdir} --extra_lsndir=${fullBackupDir}/${extra_lsndir_file_name} ${fullBackupDir} 2>${fullBackupDir}/details.log | /usr/bin/lbzip2 -kv -n 10 >${fullBackupDir}/${extra_lsndir_file_name}.xbstream 2>${fullBackupDir}/compress.log


#find /data/mysql_backup/3307/ -type f . -name "*01.log" . -name "*15.log" -name "*.log" -mtime +13 -exec rm -f {} \;

if [ $? == 0 ];then
	echo "full backup success at ${filename}" >>${fullBackupDir}/backup.log
    echo -e "${hostName} MySQL Fullbackup success.\n Begin: ${extra_lsndir_file_name},complete at `date +%F_%H-%M-%S` \n  `tail -n 10 ${fullBackupDir}/details.log` " | ${sendEmailPath} -t lijianjun@meilele.com,hechao1@meilele.com -f nagios@meilele.com -s mail.meilele.com:25 -xu nagios -xp mll123456 -u "${hostName} MySQL Fullbackup success"
else
	echo "full backup failure.Please see ${fullBackupDir}/details.log for more details" >>${fullBackupDir}/backup.log
    echo -e "${hostName} MySQL Fullbackup failure.\n Begin: ${extra_lsndir_file_name},complete at `date +%F_%H-%M-%S` \n  `tail -n 10 ${fullBackupDir}/details.log` " | ${sendEmailPath} -t lijianjun@meilele.com,hechao1@meilele.com -f nagios@meilele.com -s mail.meilele.com:25 -xu nagios -xp mll123456 -u "${hostName} MySQL Fullbackup Failure"
fi
}
# incremental backup function define
function increbackup(){
if [[ ${other_increbase_path} == '' || ${Week_Day} == "0" ]];then
    ${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --slave-info --incremental --incremental-basedir=${fullBackupDir}/${first_increbase_path} --stream=xbstream --parallel=4 --compress --compress-threads=8 --tmpdir=${tmpdir} --extra_lsndir=${extra_lsndir_file_name} ${increBackupDir} >${increBackupDir}/${extra_lsndir_file_name}.xbstream 2>${fullBackupDir}/details.log
else
    ${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --slave-info --incremental --incremental-basedir=${increBackupDir}/${other_increbase_path} --stream=xbstream --parallel=4 --compress --compress-threads=8 --tmpdir=${tmpdir} --extra_lsndir=${increBackupDir}/${extra_lsndir_file_name} ${increBackupDir} >${increBackupDir}/${extra_lsndir_file_name}.xbstream 2>${fullBackupDir}/details.log
fi

if [ $? == 0 ];then
	echo "Incremental backup success at ${filename}" >>${fullBackupDir}/backup.log
    echo -e "${hostName} MySQL IncrementalBackup success.\n Begin: ${extra_lsndir_file_name},,complete at `date +%F_%H-%M-%S` \n `tail -n 10 ${fullBackupDir}/details.log` " | ${sendEmailPath} -t lijianjun@meilele.com,hechao1@meilele.com -f nagios@meilele.com -s mail.meilele.com:25 -xu nagios -xp mll123456 -u "${hostName} MySQL Incremental Backup success"
else
	echo "Incremental backup failure.Please see ${fullBackupDir}/details.log for more details." >>${fullBackupDir}/backup.log
    echo -e "${hostName} MySQL IncrementalBackup Failure. Begin: ${extra_lsndir_file_name},,complete at `date +%F_%H-%M-%S` \n `tail -n 10 ${fullBackupDir}/details.log`" | ${sendEmailPath} -t lijianjun@meilele.com,hechao1@meilele.com -f nagios@meilele.com -s mail.meilele.com:25 -xu nagios -xp mll123456 -u "${hostName} MySQL Incremental Backup Failure"
fi
}

if [[ ${first_increbase_path} == '' || ${Week_Day} == "6" ]];then
	fullbackup
else
    increbackup
fi

#清理40天前的备份文件
find ${fullBackupDir} -type f -name "*.xbstream" -mtime +40 -exec rm -f {} \;
find ${increBackupDir} -type f -name "*.xbstream" -mtime +40 -exec rm -f {} \;

