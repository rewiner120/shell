#!/bin/bash
#using for monitor mysql server error log and send mail
#larry@meilele
#2018-12-18

if [ $# -eq 0 ] ;then
    echo -e "usage:\n\t$0 [single] [hostname]\n\t$0 [multi] [filename] [tmp_filename] [hostname]"
	exit 1
elif [[ $1 == "single" ]];then      #single instance
	error_log_file=$(ps -ef |grep mysql |sed 's/log-error=/\nlog-error=/g' |grep log-error |awk '{print $1 }' |awk -F '=' '{print $2}')

    hostname="SZ_$(hostname)"

    #ps -ef |grep mysql
    tmplog=/tmp/mysql_tmp.log
    echo ${error_log_file} ${hostname}

    pre_md5=`/usr/bin/md5sum ${error_log_file}|awk '{print $1}'`
    pre_lines=`/usr/bin/wc -l ${error_log_file}|awk '{print $1}'`
    while true
    do
        cur_md5=`/usr/bin/md5sum ${error_log_file}|awk '{print $1}'`
        cur_lines=`/usr/bin/wc -l ${error_log_file}|awk '{print $1}'`
        if [[ ${cur_md5} != ${pre_md5} ]];then
            sed -n "${pre_lines},$p" ${error_log_file}>${tmplog}
            error_count=`grep "\[ERROR\]" ${tmplog} |wc -l`
            if [[ ${error_count} != "0" ]];then
                #echo -e "$2 MySQL Exist Error.\n Monitor Time: `date +%F_%H-%M-%S` \n  `cat /tmp/mysql_tmp.log` " | ${sendEmailPath} -t lijianjun@meilele.com,hechao1@meilele.com -f nagios@meilele.com -s smtp.meilele.com:25 -xu nagios@meilele.com -xp 'B)q].sGPfT6i_1Ux' -u "$2 MySQL Error!"
                
                 
                python  /opt/shell/sendmail.py 'hechao1@meilele.com,lijianjun@meilele.com' "${hostname} MySQL Error!" "Monitor Time: `date +%F_%H-%M-%S` \n pre_lines:${pre_lines}--${cur_lines} \n `grep -n '\[ERROR\]' ${tmplog}`"
                echo "sendmail `date "+%F %T"`"
            fi


        fi
        sleep 3600
        pre_md5=${cur_md5}
        pre_lines=${cur_lines}
    done
elif [[ $1 == "multi" && $# == "4" ]];then
    error_log_file=$2
    hostname=$4
    tmplog="/tmp/$3"
    pre_md5=`/usr/bin/md5sum ${error_log_file}|awk '{print $1}'`
    pre_lines=`/usr/bin/wc -l ${error_log_file}|awk '{print $1}'`
    echo ${error_log_file} ${hostname} ${tmplog}
    while true
    do
        cur_md5=`/usr/bin/md5sum ${error_log_file}|awk '{print $1}'`
        cur_lines=`/usr/bin/wc -l ${error_log_file}|awk '{print $1}'`
        if [[ ${cur_md5} != ${pre_md5} ]];then
            sed -n "${pre_lines},$p" ${error_log_file}>${tmplog}
            error_count=`grep "\[ERROR\]" ${tmplog} |wc -l`
            if [[ ${error_count} != "0" ]];then
                #echo -e "$2 MySQL Exist Error.\n Monitor Time: `date +%F_%H-%M-%S` \n  `cat /tmp/mysql_tmp.log` " | ${sendEmailPath} -t lijianjun@meilele.com,hechao1@meilele.com -f nagios@meilele.com -s smtp.meilele.com:25 -xu nagios@meilele.com -xp 'B)q].sGPfT6i_1Ux' -u "$2 MySQL Error!"
                
                 
                python  /opt/shell/sendmail.py 'hechao1@meilele.com,lijianjun@meilele.com' "${hostname} MySQL Error!" "Monitor Time: `date +%F_%H-%M-%S` \n pre_lines:${pre_lines}--${cur_lines} \n `grep -n '\[ERROR\]' ${tmplog}`"
                echo "sendmail `date "+%F %T"`"
            fi


        fi
        sleep 3600
        pre_md5=${cur_md5}
        pre_lines=${cur_lines}
    done
else
    echo -e "usage:\n\t$0 [single] [hostname]\n\t$0 [multi] [filename] [tmp_filename] [hostname]"
	exit 1    
fi
