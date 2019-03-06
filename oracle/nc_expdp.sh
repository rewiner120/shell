time=`date '+%Y%m%d'`
su - oracle -c "expdp nc65/nc65 directory=dir_dp dumpfile=nc$time.dump logfile=error.log"

