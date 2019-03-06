export ORACLE_SID=prod
export ORACLE_BASE=/oracle/app/oracle
export ORACLE_HOME=/oracle/app/oracle/product/10.2.0/db_1
/oracle/app/oracle/product/10.2.0/db_1/bin/rman target / nocatalog cmdfile=/backup/shell/bak.rman log=/backup/shell/rman_`date +%Y%m%d%H%M`.log
