#! /bin/sh
# This shell use for getting mysql status per day
# version 1.0
# Author Li JianJun
# @2017-11-13

# Connection Configure
DB_user='hsl#manage'
DB_passwd='*93sl(8E{2D'
DB_host='127.0.0.1'
DB_cmd='/usr/local/mysql/bin/mysqladmin extended-status'


# Function Body
# 打印查询，提交，回滚，连接数，活跃连接数信息
function summary(){
${DB_cmd} -i1 -u${DB_user} -h${DB_host} -p${DB_passwd}|awk 'BEGIN{lswitch=0;
#打印信息表头 
print "|Select |Update |Insert |Delete |Trans_commit |Trans_rollback |Bytes_sent |Bytes_received |Uptime(day) |";
print "--------------------------------------------------------------------------------------------------------";}

#打印几个常用参数，前几个参数，是增量数据，因此需要记录上一次的值
$2 ~ /Com_select$/ {s=$4-ls; ls=$4;}
$2 ~ /Com_update$/ {u=$4-lu; lu=$4;}
$2 ~ /Com_insert$/ {i=$4-li; li=$4;}
$2 ~ /Com_delete$/ {d=$4-ld; ld=$4;}
$2 ~ /Com_commit$/ {c=$4-lc; lc=$4;}
$2 ~ /Com_rollback$/  {r=$4-lr; lr=$4;}
$2 ~ /Bytes_sent$/   {bs=$4-lbs;lbs=$4;}
$2 ~ /Bytes_received$/ {br=$4-lbr;lbr=$4;}
$2 ~ /Uptime$$/ {q=$4;

/* 设置lswitch的原因，为了打印10次出现一次表头 */
if (lswitch==0)
{lswitch=1;count=0;}
else {
    /* 打印10次数据，重新显示表头 */
    if (count>10) {
        count=0;
        print "--------------------------------------------------------------------------------------------------------";
        print "|Select |Update |Insert |Delete |Trans_commit |Trans_rollback |Bytes_sent |Bytes_received |Uptime(day) |";
        print "--------------------------------------------------------------------------------------------------------";
    } else {
        count+=1;
        /* 按照格式符进行打印，其中TPS值为Com_commit、Com_rollback的总和 */
        printf "|%-6d |%-6d |%-6d |%-6d |%-12d |%-15d|%-11d|%-15d|%-12d|\n", s,u,i,d,c,r,bs,br,q/86400;
    }
}
}'
}

# Threads function
function threads(){
${DB_cmd} -i1 -u${DB_user} -h${DB_host} -p${DB_passwd}|awk 'BEGIN{lswitch=0;
#打印信息表头 
print "|Threads_created |Threads_running |Threads_connected |Threads_cached |Connect Killed |";
print "--------------------------------------------------------------------------------------";}

#打印Threads_connected、Threads_running这五个状态
$2 ~ /Threads_created$/ {tc=$4;}
$2 ~ /Threads_running$/  {tr=$4;}
$2 ~ /Threads_connected$/    {tcod=$4;}
$2 ~ /Threads_cached$/   {tcad=$4;}
$2 ~ /Com_kill$/ {tk=$4;

/* 设置lswitch的原因，为了打印10次出现一次表头 */
if (lswitch==0)
{lswitch=1;count=0;}
else {
    /* 打印10次数据，重新显示表头 */
    if (count>10) {
        count=0;
        print "------------------------------------------------------------------------------------";
        print "|Threads_created |Threads_running |Threads_connected |Threads_cached |Connect Killed |";
        print "------------------------------------------------------------------------------------";
    } else {
        count+=1;
        /* 按照格式符进行打印 */
        printf "|%-15d |%-15d |%-17d |%-14d |%-15d|\n", tc,tr,tcod,tcad,tk;
    }
}
}'
}

# Locks function

function locks(){
${DB_cmd} -i1 -u${DB_user} -h${DB_host} -p${DB_passwd}|awk 'BEGIN{lswitch=0;
#打印信息表头 
print "|Table_locks_immediate |Table_locks_waited |Innodb_row_lock_current_waits |Innodb_row_lock_waits |Innodb_row_lock_time_avg |";
print "----------------------------------------------------------------------------------------------------------------------------";}

#查看锁的增量信息这五个参数，前三个参数，是增量数据，因此需要记录上一次的值
$2 ~ /Table_locks_immediate$/ {tli=$4-ltli; ltli=$4;}
$2 ~ /Table_locks_waited$/  {tlw=$4-ltlw; ltlw=$4;}
$2 ~ /Innodb_row_lock_current_waits$/    {irlcw=$4;}
$2 ~ /Innodb_row_lock_waits$/   {irlw=$4-lirlw;lirlw=$4;}
$2 ~ /Innodb_row_lock_time_avg$/ {irlta=$4/1000;

/* 设置lswitch的原因，为了打印10次出现一次表头 */
if (lswitch==0)
{lswitch=1;count=0;}
else {
    /* 打印10次数据，重新显示表头 */
    if (count>10) {
        count=0;
        print "----------------------------------------------------------------------------------------------------------------------------";
        print "|Table_locks_immediate |Table_locks_waited |Innodb_row_lock_current_waits |Innodb_row_lock_waits |Innodb_row_lock_time_avg |";
        print "----------------------------------------------------------------------------------------------------------------------------";
    } else {
        count+=1;
        /* 按照格式符进行打印，其中TPS值为Com_commit、Com_rollback的总和 */
        printf "|%-21d |%-18d |%-29d |%-21d |%-24d |\n", tli,tlw,irlcw,irlw,irlta;
    }
}
}'
}

# InnoDB Summary Function
function innodb(){
${DB_cmd} -i1 -u${DB_user} -h${DB_host} -p${DB_passwd}|awk 'BEGIN{lswitch=0;
#打印信息表头 
print "|Innodb_row_Select | Update | Insert | Delete | Innodb_row_lock_current_waits | Lock_time | Lock_time_avg | Lock_waits |";
print "------------------------------------------------------------------------------------------------------------------------";}

#打印Queries、Com_commit、Com_rollback、Threads_connected、Threads_running这五个参数，前三个参数，是增量数据，因此需要记录上一次的值
$2 ~ /Innodb_rows_read$/    {r=$4-lr; lr=$4;}
$2 ~ /Innodb_rows_inserted$/    {i=$4-li; li=$4;}
$2 ~ /Innodb_rows_updated$/    {u=$4-lu; lu=$4;}
$2 ~ /Innodb_rows_deleted$/    {d=$4-ld; ld=$4;}
$2 ~ /Innodb_row_lock_current_waits$/ {lcw=$4-llcw; llcw=$4;}
$2 ~ /Innodb_row_lock_time$/  {lt=$4-llt; llt=$4;}
$2 ~ /Innodb_row_lock_time_avg$/    {lta=$4-llta; llta=$4;}
$2 ~ /Innodb_row_lock_waits$/   {lw=$4;

/* 设置lswitch的原因，为了打印10次出现一次表头 */
if (lswitch==0)
{lswitch=1;count=0;}
else {
    /* 打印10次数据，重新显示表头 */
    if (count>10) {
        count=0;
        print "------------------------------------------------------------------------------------------------------------------------";
        print "|Innodb_row_Select | Update | Insert | Delete | Innodb_row_lock_current_waits | Lock_time | Lock_time_avg | Lock_waits |";
        print "------------------------------------------------------------------------------------------------------------------------";
    } else {
        count+=1;
        /* 按照格式符进行打印，其中TPS值为Com_commit、Com_rollback的总和 */
        printf "|%-17d |%-7d |%-7d |%-7d |%-30d |%-11d|%-14d |%-11d |\n", r,i,u,d,lcw,lt,lta,lw;
    }
}
}'
}


#print usage!打印使用说明
function usage(){
    echo """=========================================================
Usage:
=========================================================
-h --help                    print help information
                             帮助信息
-t --transaction             print threads information
                             查看链接相关信息
-T --threads                 print ion rollback;
                             打印服务器启动到现在的查询，事务，提交，回滚的总量！
-l --locks                   print locks summary information
                             打印服务器锁信息
-A --all                     print summary information for select,update,delete,insert,threads,transaction
                             打印增删改查汇总信息
-I --index                   print summary index usaging information
                             查看索引汇总信息
-i --increment               giving an increment steps for which you want.
                             配合其他功能查看增量信息的增量幅度，例如：3秒的增量则-i 3
-I --InnoDB                  print innodb engine information
                             查看innodb引擎信息
-h --help                    print help information
-h --help                    print help information
-h --help                    print help information
-h --help                    print help information

=========================================================
"""
    exit;
    
}

# Useful introduce
if [ $# -lt 1 ];then
    usage
else
    case $1 in
    -I)
        innodb
        ;;
    -T)
        threads
        ;;
    -A)
        summary
        ;;
    -l)
        locks
        ;;
    *)
        usage
        ;;
    esac
fi

# user choosing



