#! /bin/sh

DBUSER=root
DBPASSWORD=WJ@RealDb01
BackDir=/backup/databackup
LogFile=/backup/databackup/fullbak.log
FailLogFile=/backup/databackup/fullbak_fail.log
MysqlBaseDir=/usr/local/mysql
MysqlDataDir=${MysqlBaseDir}/data
MysqlDump=$MysqlBaseDir/bin/mysqldump
Date=`date +%F-%H-%M`
Begin=`date +"%Y年%m月%d日 %H:%M:%S"`
DumpFile=$Date.sql
GZDumpFile=$Date.tar.gz
cd ${MysqlDataDir}
echo "#########       Database Backup Start ${Date}    ##########" >>${LogFile}
DBLIST=`ls -p | grep /|tr -d /`
for DBNAME in $DBLIST
  do 
    if [[ `date +%w` == 1 || `date +%w` == 4 ]];then
	if [[ ${DBNAME} == "ecmall" ]];then
		${MysqlDump} --user=${DBUSER} --password=${DBPASSWORD} --routines --events --flush-logs --triggers --single-transaction --master-data=2 --databases ${DBNAME} > ${BackDir}/${DBNAME}.sql
        	[ $? -eq 0 ] && echo "${DBNAME} has been backuped successful" >>${LogFile} || echo "${DBNAME} has been backuped failed	##${Begin}	#####" >>${FailLogFile}
	else
		${MysqlDump} --user=${DBUSER} --password=${DBPASSWORD} --routines --events --triggers --single-transaction --master-data=2 --databases ${DBNAME} > ${BackDir}/${DBNAME}.sql
        	[ $? -eq 0 ] && echo "${DBNAME} has been backuped successful" >>${LogFile} || echo "${DBNAME} has been backuped failed	##${Begin}	#####" >>${FailLogFile}
	fi	
    else
		${MysqlDump} --user=${DBUSER} --password=${DBPASSWORD} --routines --events --triggers --single-transaction --master-data=2 --databases ${DBNAME} > ${BackDir}/${DBNAME}.sql
        	[ $? -eq 0 ] && echo "${DBNAME} has been backuped successful" >>${LogFile} || echo "${DBNAME} has been backuped failed	##${Begin}	#####" >>${FailLogFile}
    fi
  /bin/sleep 5
done
#done
cd ${BackDir}

/bin/tar czvf $GZDumpFile *.sql >/dev/null 2>&1
/bin/rm -f *.sql
Last=`date +"%Y年%m月%d日 %H:%M:%S"`

echo "###########     Database Backup End ${Last}       ##########" >> $LogFile
















