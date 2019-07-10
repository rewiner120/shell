#! /bin/sh
# This is mysql full backup and incremental backup shell
# it full backup at every Saturday and Incremental backup other days,You must set Fullbackup dir name and Total Increment dir name.The current IncrementBackup dir based on lastest Fullbackup dir name.
# version 1.0
# author : lijianjun@meilele.com



export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
#hostname
hostName="`ifconfig |grep inet|egrep -v "inet6"|awk 'NR==1{print $2}'`"
#SendEmail
sendEmailPath="/usr/bin/sendEmail"
Week_Day=`date +%w`
Date_Day=`date +%d`
innobackupex_path="/usr/local/percona-xtrabackup-2.4.4/bin/innobackupex"
cnf_file="/etc/my.cnf"
# tmpfile dir
tmpdir="/data/backup/tmp"
#full_backup dir
fullBackupDir="/data/backup/"
#incre_backup dir
#increBackupDir="/data/xbstream_backup/incre_backup"
#logDir
logDir="/data/backup/"
username="backup_user"
password="lwIbWXAp@4#tmn52"
host="127.0.0.1"
filename=`date +%F`
port='3306'
extra_lsndir_file_name=`date +%F_%H-%M-%S`
#全备后的第一次增量
#是否执行成功的标志
increback_success="0"
fullback_success="0"
rsync_file_success="0"

# 3306 full backup function define
function fullbackup(){
echo ${hostName}
${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --port=${port} --slave-info --stream=xbstream --parallel=4 --compress --compress-threads=8 --tmpdir=${tmpdir} ${fullBackupDir} >${fullBackupDir}/${extra_lsndir_file_name}.xbstream 2>${logDir}/details.log

#lbzip compress
#${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --port=${port} --slave-info --safe-slave-backup --stream=xbstream --parallel=4 --tmpdir=${tmpdir} --extra_lsndir=${fullBackupDir}/${extra_lsndir_file_name} ${fullBackupDir} 2>${logDir}/details.log | /usr/bin/lbzip2 -kv -n 10 >${fullBackupDir}/${extra_lsndir_file_name}.bz2  2>${logDir}/compress.log


if [ $? == 0 ];then
	echo "full backup success at ${filename}" >>${logDir}/backup.log
	fullback_success="111"
else
	echo "full backup failure.Please see ${logDir}/details.log for more details" >>${logDir}/backup.log
	fullback_success="000"
fi
}
# incremental backup function define
function increbackup(){
if [[ ${other_increbase_path} == '' || ${Week_Day} == "0" ]];then
    #默认压缩工具

    #${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --slave-info --safe-slave-backup --incremental --incremental-basedir=${fullBackupDir}/${first_increbase_path} --stream=xbstream --parallel=4 --compress --compress-threads=8 --tmpdir=${tmpdir} --extra_lsndir=${CurrentIncreBackupDir}/${extra_lsndir_file_name} ${CurrentIncreBackupDir} >${CurrentIncreBackupDir}/${extra_lsndir_file_name}.xbstream 2>${logDir}/details.log

    #lbzip compress
    ${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --slave-info --safe-slave-backup --incremental --incremental-basedir=${fullBackupDir}/${first_increbase_path} --stream=xbstream --parallel=4 --tmpdir=${tmpdir} --extra_lsndir=${CurrentIncreBackupDir}/${extra_lsndir_file_name} ${CurrentIncreBackupDir} 2>${logDir}/details.log | /usr/bin/lbzip2 -kv -n 10 >${CurrentIncreBackupDir}/${extra_lsndir_file_name}.bz2 2>${logDir}/compress.log
else
    #Default compress
    
    #${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --slave-info --incremental --incremental-basedir=${CurrentIncreBackupDir}/${other_increbase_path} --stream=xbstream --parallel=4 --compress --compress-threads=8 --tmpdir=${tmpdir} --extra_lsndir=${CurrentIncreBackupDir}/${extra_lsndir_file_name} ${CurrentIncreBackupDir} >${CurrentIncreBackupDir}/${extra_lsndir_file_name}.xbstream 2>${logDir}/details.log
    
    #lbzip2 compress
    ${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --slave-info --safe-slave-backup --incremental --incremental-basedir=${CurrentIncreBackupDir}/${other_increbase_path} --stream=xbstream --parallel=4 --tmpdir=${tmpdir} --extra_lsndir=${CurrentIncreBackupDir}/${extra_lsndir_file_name} ${CurrentIncreBackupDir} 2>${logDir}/details.log | /usr/bin/lbzip2 -kv -n 10 >${CurrentIncreBackupDir}/${extra_lsndir_file_name}.bz2 2>${logDir}/compress.log
fi

if [ $? == 0 ];then
	echo "Incremental backup success at ${filename}" >>${logDir}/backup.log
	increback_success="111"
else
	echo "Incremental backup failure.Please see ${logDir}/details.log for more details." >>${logDir}/backup.log
	increback_success="000"
fi
}

function rsync_backup_file(){
if [[ ${fullback_success} == "111" ]];then
        /usr/bin/rsync -avzP ${fullBackupDir}/${extra_lsndir_file_name}.xbstream rsync@192.168.0.3::0_46_3306 --password-file=/etc/rsync.pass >${fullBackupDir}/rsync.log
        if [ $? == 0 ];then
                echo "====== `date +%F_%H-%M-%S` ======rsync backup file success." >>${fullBackupDir}/rsync.log
                rsync_file_success="111"
        else
                echo "====== `date +%F_%H-%M-%S` ======rsync backup file Failure." >>${fullBackupDir}/rsync.log
                rsync_file_success="000"
        fi
fi
}

function sendmail(){
if [ ${increback_success} == "111" ];then
    echo -e "${hostName}_${port} MySQL IncrementalBackup success.\n Begin: ${extra_lsndir_file_name},,complete at `date +%F_%H-%M-%S` \n `tail -n 10 ${logDir}/details.log` " | ${sendEmailPath} -t lijianjun@meilele.com,hechao1@meilele.com -f nagios@meilele.com -s smtp.meilele.com:25 -xu nagios@meilele.com -xp 'B)q].sGPfT6i_1Ux' -u "Online_${hostName}_${port} MySQL Incremental Backup success"
elif [ ${increback_success} == "000" ];then
    echo -e "${hostName} MySQL IncrementalBackup Failure. Begin: ${extra_lsndir_file_name},,complete at `date +%F_%H-%M-%S` \n `tail -n 10 ${logDir}/details.log`" | ${sendEmailPath} -t lijianjun@meilele.com,hechao1@meilele.com -f nagios@meilele.com -s smtp.meilele.com:25 -xu nagios@meilele.com -xp 'B)q].sGPfT6i_1Ux' -u "Online_${hostName}_${port} MySQL Incremental Backup Failure"
elif [ ${fullback_success} == "111" -a ${rsync_file_success} == "111" ];then
    echo -e "${hostName} MySQL Fullbackup success.\n Begin: ${extra_lsndir_file_name},complete at `date +%F_%H-%M-%S` \n  `tail -n 10 ${logDir}/details.log` \n `tail -n 1 ${fullBackupDir}/rsync.log`" | ${sendEmailPath} -t lijianjun@meilele.com,hechao1@meilele.com -f nagios@meilele.com -s smtp.meilele.com:25 -xu nagios@meilele.com -xp 'B)q].sGPfT6i_1Ux' -u "Online_${hostName}_${port} MySQL Fullbackup success"
elif [ ${fullback_success} == "000" ];then
        echo "full backup failure.Please see ${logDir}/details.log for more details" >>${logDir}/backup.log
    echo -e "${hostName} MySQL Fullbackup failure.\n Begin: ${extra_lsndir_file_name},complete at `date +%F_%H-%M-%S` \n  `tail -n 10 ${logDir}/details.log` " | ${sendEmailPath} -t lijianjun@meilele.com,hechao1@meilele.com -f nagios@meilele.com -s smtp.meilele.com:25 -xu nagios@meilele.com -xp 'B)q].sGPfT6i_1Ux' -u "Online_${hostName}_${port} MySQL Fullbackup Failure"

fi

}

fullbackup
rsync_backup_file
sendmail
#清理10天前的备份文件
find ${fullBackupDir}/ -type f -name "*.xbstream" -mtime +10 -exec rm -f {} \;
#find ${increBackupDir}/ -type f -name "*.xbstream" -mtime +10 -exec rm -f {} \;
#find ${fullBackupDir}/ -type f -name "*.bz2" -mtime +10 -exec rm -f {} \;
#find ${increBackupDir}/ -type f -name "*.bz2" -mtime +10 -exec rm -f {} \;

