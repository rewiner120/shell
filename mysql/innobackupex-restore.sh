#************************************************************************************************
#!/bin/sh
#
# 使用方法：
# ./restore.sh /增量备份父目录
#ocpyang@126.com

#NOTE:恢复开始前请确保mysql服务停止以及数据和日志目录清空,如
# rm -rf /usr/local/mysql/innodb_data/*
# rm -rf /usr/local/mysql/data/*
# rm -rf /usr/local/mysql/mysql_logs/innodb_log/*


#INNOBACKUPEX=innobackupex
INNOBACKUPEX_PATH=/usr/bin/innobackupex
TMP_LOG="/tmp/restore.log"
MY_CNF=/etc/my.cnf
BACKUP_DIR=/tmp # 你的备份主目录
FULLBACKUP_DIR=$BACKUP_DIR/full # 全库备份的目录
INCRBACKUP_DIR=$BACKUP_DIR/incre # 增量备份的目录
MEMORY=512M # 还原的时候使用的内存限制数
ERRORLOG=`grep -i "^log-error" $MY_CNF |cut -d = -f 2`
MYSQLD_SAFE=/usr/local/mysql/bin/mysqld_safe
MYSQL_PORT=3306
FULL=`ls -t $FULLBACKUP_DIR |head -1`
FULLBACKUP=$FULLBACKUP_DIR/$FULL
mysqldatadir=/usr/local/mysql/data
#############################################################################

#显示错误

#############################################################################

error()
{
    echo "$1" 1>&2
    exit 1
}

  

#############################################################################

# 检查innobackupex错误输出

#############################################################################

check_innobackupex_fail()
{
    if [ -z "`tail -2 $TMP_LOG | grep 'completed OK!'`" ] ; then
    echo "$INNOBACKUPEX命令执行失败:"; echo
    echo "---------- $INNOBACKUPEX的错误输出 ----------"
    cat $TMP_LOG
    #保留一份备份的详细日志
    logfiledate=restore.`date +%Y%m%d%H%M`.txt
    cat $TMP_LOG>/tmp/$logfiledate  
    rm -f $TMP_LOG
    exit 1
  fi
}

 



# 选项检测
if [ ! -x $INNOBACKUPEX_PATH ]; then
  error "$INNOBACKUPEX_PATH在指定路径不存在,请确认是否安装或核实链接是否正确."
fi

  

if [ ! -d $BACKUP_DIR ]; then
  error "备份目录$BACKUP_DIR不存在."
fi

  

if [ $# != 1 ] ; then
  error "使用方法: $0 使用还原目录的绝对路径"
fi

  

if [ ! -d $1 ]; then
  error "指定的备份目录:$1不存在."
fi



PORTNUM00=`netstat -lnt|grep ${MYSQL_PORT}|wc -l`
if [ $PORTNUM00 = 1  ];
then
echo -e '\e[31m NOTE:------------------------------------------.\e[m' #红色
echo -e '\e[31m mysql处于运行状态,请关闭mysql. \e[m' #红色
echo -e '\e[31m NOTE:------------------------------------------.\e[m' #红色
exit 0
fi	



input_value=$1
intpu_res=`echo ${input_value}` 


# Some info output
echo "----------------------------"
echo
echo "$0: MySQL还原脚本"
START_RESTORE_TIME=`date +%F' '%T' '%w`
echo "数据库还原开始于: $START_RESTORE_TIME"
echo





#PARENT_DIR=`dirname ${intpu_res}`
PARENT_DIR=${intpu_res}
if [ "$PARENT_DIR/full"x = "$FULLBACKUP_DIR"x ]; then
	#FULLBACKUP=${intpu_res}
	echo "全备备份目录为:$PARENT_DIR/full"
	echo

else
	if [ "$PARENT_DIR/incre"x = "$INCRBACKUP_DIR"x ]; then
		FULL=`ls -t $FULLBACKUP_DIR |head -1`
		FULLBACKUP=$FULLBACKUP_DIR/$FULL
			if [ ! -d $FULLBACKUP ]; then
			error "全备:$FULLBACKUP不存在."
			fi
		INCR=`ls -t $INCRBACKUP_DIR/ | head -1`
		echo "还原将从全备$FULL开始,到增量$INCR结束."
		echo
		sleep 3
		echo "Prepare:完整备份集..........."
		echo "*****************************"
		$INNOBACKUPEX_PATH --defaults-file=$MY_CNF --apply-log --redo-only --use-memory=$MEMORY $FULLBACKUP > $TMP_LOG 2>&1
		check_innobackupex_fail
    		#获取最新增量备份文件夹名称
		lastest_file = `find $INCRBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -n |tail -1`		
		for i in `find $INCRBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -n `;
		do

			#判断最新全备的lsn
			#check_full_file=`find $FULLBACKUP/ -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head  -1`
		    
			check_full_lastlsn=$FULLBACKUP/xtrabackup_checkpoints
			
			fetch_full_lastlsn=`grep -i "^last_lsn" ${check_full_lastlsn} |cut -d = -f 2`

			######判断增量备份中第一个增量备份的LSN
			check_incre_file=`find $INCRBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -n |  head -1`
		      
			check_incre_lastlsn=$INCRBACKUP_DIR/$i/xtrabackup_checkpoints
		      
			fetch_incre_lastlsn=`grep -i "^last_lsn" ${check_incre_lastlsn} |cut -d = -f 2`
			echo "完全备份的LSN:${fetch_full_lastlsn} "
			echo "增量备份的LSN:${fetch_incre_lastlsn} "
			
				if [ "${fetch_incre_lastlsn}" -eq "${fetch_full_lastlsn}" ];then
					echo "*****************************************"
					echo "LSN不需要prepare!"
					echo "*****************************************"
					echo
					break
				
				
			
				else
					echo "Prepare:增量备份集$i........"
					echo "*****************************"
					if [ "$i"x != "$lastest_file"x ];then
					$INNOBACKUPEX_PATH --defaults-file=$MY_CNF --apply-log --redo-only --use-memory=$MEMORY $FULLBACKUP --incremental-dir=$INCRBACKUP_DIR/$i > $TMP_LOG 2>&1
					check_innobackupex_fail
			  		echo "Finished:增量备份集$i........"
					else
						echo "Prepare:最后一个增量备份集$i......"
						echo "*****************************"
						$INNOBACKUPEX_PATH --defaults-file=$MY_CNF --apply-log --use-memory=$MEMORY $FULLBACKUP --incremental-dir=$INCRBACKUP_DIR/$i > $TMP_LOG 2>&1
                                         	check_innobackupex_fail
						echo "Finished:准备所有增量备份集完成........"
						sleep 3

					fi
		     
				fi 
			######判断LSN
		done
	
	else
		error "未知的备份类型"
	fi
fi


echo "prepare:全备集回滚那些未提交的事务..........."
sleep 3
$INNOBACKUPEX_PATH --defaults-file=$MY_CNF --apply-log --use-memory=$MEMORY $FULLBACKUP > $TMP_LOG 2>&1
check_innobackupex_fail

echo "*****************************"
echo "数据库还原中 ...请稍等"
echo "*****************************"

$INNOBACKUPEX_PATH --defaults-file=$MY_CNF --copy-back $FULLBACKUP > $TMP_LOG 2>&1
check_innobackupex_fail

  
rm -f $TMP_LOG
echo "1.恭喜,还原成功!."
echo "*****************************"


#修改目录权限
echo "修改mysql目录的权限."
#mysqldatadir=`grep -i "^datadir" $MY_CNF |cut -d = -f 2`
chown -R mysql ${mysqldatadir}
echo "2.权限修改成功!"
echo "*****************************"


#自动启动mysql

INIT_NUM=1
if [ ! -x $MYSQLD_SAFE ]; then
  echo "mysql安装时启动文件未安装到$MYSQLD_SAFE或无执行权限"
  exit 1  #0是执行成功,1是执行不成功
else
	echo "启动本机mysql端口为:$MYSQL_PORT的服务"
	$MYSQLD_SAFE --defaults-file=$MY_CNF  > /dev/null &
	while  [ $INIT_NUM  -le 6 ]
     	do
        	PORTNUM=`netstat -lnt|grep ${MYSQL_PORT}|wc -l`
        	echo "mysql启动中....请稍等..."
        	sleep 5
        		if [ $PORTNUM = 1  ];
        		then
         		echo "mysql                                      ****启动成功****"
        		exit 0
        		fi	
        	INIT_NUM=$(($INIT_NUM +1))
     	done
  	echo -e "mysql启动失败或启动时间过长,请检查错误日志 `echo 'cat ' ${ERRORLOG}`"
	echo "*****************************************"
	exit 0
fi




END_RESTORE_TIME=`date +%F' '%T' '%w`
echo "数据库还原完成于: $END_RESTORE_TIME"
exit 0
