#! /bin/sh
#only use for online server 19
#only backup bi_sync and test table structure and rountine,event
backuser=""
password=""
host=""
port=""
backup_dir=""
mysqldump_path=""

${mysqldump_path} -u${backuser} -p${password} -h${host} -P${port} -ERF --triggers --all-databases --lock-all-tables --master-data=2 >${backup_dir}/2018-10-30.sql
