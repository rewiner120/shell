#!/bin/bash
tmplog="/root/date.log"

startime=$(date )
echo -e "######################################################\n$(date) backup began."
function fasong_chenggong(){
   for i in `cat $1`
do
     /usr/bin/python /opt/shell/weixin/fasongxiaoxi.py  $2 $i
done

   }

function fasong_shibai(){

   for i in `cat $1`
do
   /usr/bin/python /opt/shell/weixin/fasongxiaoxi.py  $2 $i

done

}
username="/opt/shell/username.txt"

/usr/local/percona-xtrabackup-2.4.4/bin/innobackupex --defaults-file=/etc/my.cnf --user=root --password='d*2501)^Dp2p*K' --socket=/data/data/mysql.sock  /data/ywz_backup  --slave-info --safe-slave-backup --parallel=4 >>${tmplog} 2>&1
echo "`date` innobackupex over" 
innotime=$(date )
if test $? -eq 0
then
      fasong_chenggong $username “46数据库，开始备份” 
else
      fasong_shibai  $username  “46数据库备份出错，退出备份,运维、db检查..”
      exit 1
fi

sleep 3
cd /data/ywz_backup
echo "##############################"
ls -lht /data/ywz_backup
echo "##############################"
ls -lht /data/backup

du -sh /data/ywz_backup
echo "##############################"

df -h


files=`ls`
tar zcf ${files}.tar.gz $files
mv ${files}.tar.gz ../backup

rm -rf ${files}
echo `date`


echo "##############################"
ls -lht /data/ywz_backup
echo "##############################"
ls -lht /data/backup


echo "##############################"
df -h

echo "/data/ywz_backup/${files}.tar.gz"
echo -e "$(date) end of backup.\n#######################################################################"

endtime=$(date )

echo -e "startime:$startime \ninnotime:$innotime \nendtime:$endtime"
