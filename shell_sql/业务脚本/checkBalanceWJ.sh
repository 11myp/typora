#!/bin/bash
if [ $# -lt 1 ]; then
  Date=$(preday 1 date)
else
  Date=$1
fi

resultLog=/app/mcb/incs/var/log/BalanceWJ.log


. ilogger.sh
lgInit ${resultLog} "COM" "${centralizeReport_check}" "" "Y"
if [ "$?" -ne "0" ]; then
        echo "Init log file failed!"
        exit -1
fi

lgWriteLog INFO "" 0 "BalanceWJ start!"


BalanceWJNums=`grep '^[Vo|Mo|RMM]' /app/mcb/incs/DELETED/maiyp/database/file/BalanceWJ.txt`


if [ ${BalanceWJNums} -ne 0 ]; then
   lgWriteLog WARNING "平衡性核查" -1 "WJ文件不平衡,请通知值班电话!!!"
else
    lgWriteLog INFO "平衡性核查" 0 "WJ文件平衡!!!"
fi
