#!/bin/bash
#本机数据备份，并上传到ftp备份
#2015.06.01

LOCAL_IP="34"
#当前日期
CURRENT_TIME=`date +%Y%m%d`
#本地保存期限，默读为3天
LOCAL_EXPIRATION_TIME=`date +%Y%m%d -d "-3 day"`
#FTP上保存期限，默读为30天
FTP_EXPIRATION_TIME=`date +%Y%m%d -d "-30 day"`
#本地备份路径
LOCAL_BACK_PATH="/mysql_data/backup/local_data_back/"
#ftp服务器上备份路径
FTP_BACK_PATH="/neiwang_server_back/"
USER="lftp"
PASSWD="2865248"
FTP_IP="192.168.0.2"

#备份文件
function bak()
{
LOCAL_ITEM=$1
FILE="${LOCAL_BACK_PATH}${LOCAL_IP}_${LOCAL_ITEM}_${CURRENT_TIME}.tar.gz"
LOCAL_EXPIRATION_FILE="${LOCAL_BACK_PATH}${LOCAL_IP}_${LOCAL_ITEM}_${LOCAL_EXPIRATION_TIME}.tar.gz"
FTP_EXPIRATION_FILE="${LOCAL_IP}_${LOCAL_ITEM}_${FTP_EXPIRATION_TIME}.tar.gz"
tar zcvf ${FILE} ${LOCAL_ITEM}
/usr/bin/lftp ftp://${USER}:${PASSWD}@${FTP_IP}<<END
cd ${FTP_BACK_PATH}${LOCAL_IP}
put ${FILE}
rm -f ${FTP_EXPIRATION_FILE}
by
END
rm -f ${LOCAL_EXPIRATION_FILE}	
}


#任务计划备份
crontab -l>/opt/shell/crontab_bak

#备份shell脚本
cd /opt
ITEM="shell"
if [ -d ${ITEM} ];then
	bak ${ITEM}
fi

#备份hosts文件
cd /etc
ITEM="hosts"
if [ -f ${ITEM} ];then
	bak ${ITEM}
fi

#备份防火墙配置
cd /etc/sysconfig
ITEM="iptables"
if [ -f ${ITEM} ];then
	bak ${ITEM}
fi

#备份nagios配置文件
cd /usr/local
ITEM="nagios"
if [ -d ${ITEM} ];then
	bak ${ITEM}
fi

#备份nginx_conf脚本
cd /usr/local/nginx
ITEM="conf"
if [ -d ${ITEM} ];then
	bak ${ITEM}
fi

#备份mantis配置文件
cd /var/www
ITEM="mantis"
if [ -d ${ITEM} ];then
	bak ${ITEM}
fi

#备份考试系统文件
cd /opt
ITEM="tomcat7_exam"
if [ -d ${ITEM} ];then
        bak ${ITEM}
fi
