#! /bin/sh
# This is mysql full backup shell
# it work at every Sunday

innobackupex_path="/opt/soft/percona/bin/innobackupex"
cnf_file="/etc/my.cnf"
backup_path="/data/mysql_backup/"
username="backup"
password="Jus*7X62^!sj"
host="127.0.0.1"
filename=`date +%F`
increbase_path=`find ${backup_path} -mindepth 1 -maxdepth 1 -type d -printf "%P\n"|sort -n|tail -1`
# full backup function define
function fullbackup(){
${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --slave-info ${backup_path} > ${backup_path}/full_${filename}.log 2>&1
if [ $? == 0 ];then
	echo "full backup success at ${filename}" >>${backup_path}/backup.log
else
	echo "full backup failure!Please see ${filename}.log for more details!" >>/backup.log
fi
}
# incremental backup function define
function increbackup(){
${innobackupex_path} --defaults-file=${cnf_file} --user=${username} --password=${password} --host=${host} --slave-info  --incremental-basedir=${backup_path}/${increbase_path} --incremental ${backup_path} >${backup_path}/incre_${filename}.log 2>&1
if [ $? == 0 ];then
	echo "incremental backup success at ${filename}" >>${backup_path}/backup.log
else
	echo "incremental backup failure at ${filename}! Please see ${filename}.log for more details!" >>/backup.log
fi
}

if [[ `date +%w` == 6 || `date +%w` == 6 ]];then
	fullbackup
else
	increbackup
fi

