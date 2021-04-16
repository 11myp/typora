#!/usr/bin/ksh
#-------------------------------------------------------------------------
#
# COPYRIGHT
# COPYRIGHT Hewlett-Packard Company 2001.
#    All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# Hewlett-Packard company 2001.
# The program(s) may be used AND/or copied with the written permission
# from AND Hewlett-Packard Company 2001 or in accordance with the terms
# AND conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
#
# ***************************************************************************
# *********    MCBIII DR clean db Shell                            **********
# ***************************************************************************
#
# Name: db-clean.sh
# Description:
#This scripts is a common shell for clean database
#It should be installed in /opt/mcb/bin/.
#
#-----------------------------------------------------------------------------
# Usage: db-clean.sh
#-----------------------------------------------------------------------------
#

################  set env var  #############################
ProcNm=`basename $0`
ParaNm=$#
LogFile=$MCB_HOME/$MCB_APPID/var/log/db-clean.log
TmpFilePath=$MCB_HOME/$MCB_APPID/var/tmp
CfgFile=$MCB_HOME/$MCB_APPID/conf/db-clean.conf
PIDLock=/opt/mcb/$MCB_APPID/var/tmp/.db-clean.sh.lock
returnCode=0

################################################################
#
#--------------  main flows ------------------------------------
#
###################### Check env var         ##########################
if [ "$MCB_HOME" = "" ]
then
    echo "MCB_HOME not defined!"
    exit 1
fi
if [ "$MCB_APPID" = "" ]
then
    echo "MCB_APPID not defined!"
    exit 1
fi
############## initial log file  #############################
. ilogger.sh
lgInit ${LogFile} "COM" "db-clean.sh" "" "Y"
if [ "$?" -ne "0" ]; then
    echo "Init log file failed!"
    exit
fi 

if [ "$ParaNm" -ne 0 ];then
        echo "Usage: "$ProcNm" "
        lgWriteLog SERIOUS "main" 1 "Parameters error.Usage: "$ProcNm" "
        return 1
fi

if [ -r $PIDLock ]; then
        cat $PIDLock | read pid
        ps -ef | grep "${ProcNm}" |grep -v mcb_cronjob.sh|grep -v grep|awk '{print $2}'|while read proc_pid
        do
                if [ "${proc_pid}X" != "X" ];then
                        if [ "${pid}" = "${proc_pid}" ];then
                                lgWriteLog SERIOUS "" 1 "The same program ${ProcNm} is running now!"
                                exit 1
                        fi
                fi
        done
fi
echo $$ > $PIDLock              

lgWriteLog INFO "main" 0 "db-clean.sh start!"
#################### Load config file      ################################
if [ ! -f "$CfgFile" ];then
        Msg="The Config file "$CfgFile" is not exist!!"
        echo "$Msg"
        writeBuf="config"
        lgWriteLog SERIOUS "" 1 "$Msg"
        exit 1
fi
RowCount=0
cat $CfgFile|while read dbuser dbsid PWD_SERV_URL CleanTable CleanTableColumn TableType CleanCycle DATE_FLAG BatchNum
do
###################### config item check   ##############################
        RowCount=$((RowCount+1))
        FileHead=`echo $dbuser|cut -c 1`
        if [ "$FileHead" = "#" ];then
                continue
        fi
        if [ "$dbuser" = "" ];then
                continue
        fi
        #dbpwd=`getdbpwd $dbuser`
                ###

                      TMP_FILE="${TmpFilePath}/.db_pwd.$$"
  if [ ! -f ${MCB_HOME}/${MCB_APPID}/bin/PwdClient ];then
      lgWriteLog SERIOUS "" -1 ": --${MCB_HOME}${MCB_APPID}/bin/PwdClient"
      exit 1
  else
      ${MCB_HOME}/${MCB_APPID}/bin/PwdClient getdbpwd ${dbsid} ${dbuser} >${TMP_FILE} 2>&1 <<EOF
          ${PWD_SERV_URL}
EOF
      dbpwd=`grep "sPasswd :" ${TMP_FILE}|awk -F: '{print $2}'`

  fi

        rm -f ${TMP_FILE}
        if [ "$dbpwd" = "" ];then
                Msg="The db user "$dbuser" is not defined in passwd file,please check!!"
                echo $Msg
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue
        fi
        if [ "$dbsid" = "" ];then
                Msg="The config file content error!The item db sid at "$RowCount" is null"
                echo $Msg
                writeBuf="db sid"
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue

        fi
        if [ "$CleanTable" = "" ];then
                Msg="The config file content error!The item clean table at "$RowCount" is null"
                echo $Msg
                writeBuf="clean table"
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue

        fi
        if [ "$CleanTableColumn" = "" ];then
                Msg="The config file content error!The item clean table column sid at "$RowCount" is null"
                echo $Msg
                writeBuf="clean table column"
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue

        fi
        if [ "$CleanCycle" = "" ];then
                Msg="The config file content error!The item clean cycle at "$RowCount" is null"
                echo $Msg
                writeBuf="clean cycle"
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue

        fi
        if [ "$TableType" = "" ];then
                Msg="The config file content error!The item table type at "$RowCount" is null"
                echo $Msg
                writeBuf="table type"
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue

        fi
        if [ "$BatchNum" = "" ];then
                Msg="The config file content error!The item batch num at "$RowCount" is null"
                echo $Msg
                writeBuf="batch num"
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue

        fi
   #modify by kongcy 201711
        if [[ $BatchNum != [1-9][0-9]* ]];then
                Msg="The config file content error!The item batch num at "$RowCount" is not positive integer"
                echo $Msg
                writeBuf="batch num"
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue

        fi
        if [ "$TableType" != D -a "$TableType" != W -a "$TableType" != M -a "$TableType" != Y ];then
                Msg="The config file table type item value out of scope!The value "$TableType" in "$RowCount"!"
                echo $Msg
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue

        fi
        if [ "$dbsid" = "-" ];then
                dbsid=$ORACLE_SID
        fi
        TmpFilePrefix="dbclean_"$dbsid"_"$dbuser"_table_"
############   do clean db with clean type
case "$TableType" in
D)
        CleanDur=day
        ;;
W)
        CleanDur=week
        ;;
M)
        CleanDur=month
        ;;
Y)
        CleanDur=year
        ;;
*)
        ;;
esac
        TmpFile=$TmpFilePrefix$CleanDur.lst
if [ "${DATE_FLAG}" = "DATE" ];then
sqlplus -S /nolog 2>&1 >$TmpFilePath/${TmpFile}.connect << !!!
connect $dbuser/$dbpwd@$dbsid
spool $TmpFilePath/$TmpFile
DECLARE
/* clean_type D:daily W:weekly M:monthly Y:year */
       clean_type VARCHAR2(3) := '$TableType';
       clean_time DATE;
BEGIN
    LOOP
        IF clean_type = 'D' THEN
               clean_time := trunc(sysdate-($CleanCycle),'dd');
               DELETE FROM $CleanTable 
               WHERE $CleanTableColumn < clean_time AND rownum<=$BatchNum;
        END IF;
        IF clean_type = 'W' THEN
                clean_time := trunc(sysdate-(($CleanCycle) * 7),'dd');
                DELETE FROM $CleanTable
                WHERE $CleanTableColumn < clean_time AND rownum<=$BatchNum;
        END IF;
        IF clean_type = 'M' THEN
                clean_time := trunc(add_months(sysdate, -($CleanCycle)), 'mm');
                DELETE FROM $CleanTable
                WHERE $CleanTableColumn < clean_time AND rownum<=$BatchNum;
        END IF;
        IF clean_type = 'Y' THEN
                clean_time := trunc(add_months(sysdate, -($CleanCycle * 12)), 'yyyy');
                DELETE FROM $CleanTable
                WHERE $CleanTableColumn < clean_time AND rownum<=$BatchNum;
        END IF;
        IF sql%notfound THEN
                exit;
        END IF;
        COMMIT;
    END LOOP;
END;
/
quit
!!!
else
sqlplus -S /nolog 2>&1 >$TmpFilePath/${TmpFile}.connect << !!!
connect $dbuser/$dbpwd@$dbsid
spool $TmpFilePath/$TmpFile
DECLARE
/* clean_type D:daily W:weekly M:monthly Y:year */
       clean_type VARCHAR2(3) := '$TableType';
       clean_time VARCHAR2(8);
BEGIN
    LOOP
        IF clean_type = 'D' THEN
               clean_time := to_char(trunc(sysdate-($CleanCycle),'dd'),'yyyymmdd');
               DELETE FROM $CleanTable 
               WHERE $CleanTableColumn < clean_time AND rownum<=$BatchNum;
        END IF;
        IF clean_type = 'W' THEN
                clean_time := to_char(trunc(sysdate-(($CleanCycle) * 7),'dd'),'yyyymmdd');
                DELETE FROM $CleanTable
                WHERE $CleanTableColumn < clean_time AND rownum<=$BatchNum;
        END IF;
        IF clean_type = 'M' THEN
                clean_time := to_char(trunc(add_months(sysdate, -($CleanCycle)), 'mm'),'yyyymmdd');
                DELETE FROM $CleanTable
                WHERE $CleanTableColumn < clean_time AND rownum<=$BatchNum;
        END IF;
        IF clean_type = 'Y' THEN
                clean_time := to_char(trunc(add_months(sysdate, -($CleanCycle * 12)), 'yyyy'),'yyyymmdd');
                DELETE FROM $CleanTable
                WHERE $CleanTableColumn < clean_time AND rownum<=$BatchNum;
        END IF;
        IF sql%notfound THEN
                exit;
        END IF;
        COMMIT;
    END LOOP;
END;
/
quit
!!!
fi
        if [ $? -ne 0 ]; then
                Msg="Clean "$CleanTable" of "$dbuser" keep duration in "$CleanDur" error!!"
                writeBuf=$CleanTable" of "$dbuser"@"$dbsid" keep duration in "$CleanCycle" "$CleanDur
                echo $Msg
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue

        fi
        OraErrCon=`grep "ORA-" $TmpFilePath/${TmpFile}.connect`
        if [ $? -eq 0 ]; then
                Msg="Exec clean "$CleanTable" of "$dbuser"@"$dbsid" keep duration in "$CleanDur" error!!The error message:["$OraErrCon"]!"
                writeBuf=$CleanTable" of "$dbuser"@"$dbsid" keep duration in "$CleanCycle" "$CleanDur
                echo $Msg
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue
        fi
        OraErr=`grep "ORA-" $TmpFilePath/$TmpFile`
        if [ $? -eq 0 ]; then
                Msg="Exec clean "$CleanTable" of "$dbuser" keep duration in "$CleanDur" PL/SQL error!!The error message:["$OraErr"]!"
                writeBuf=$CleanTable" of "$dbuser"@"$dbsid" keep duration in "$CleanCycle" "$CleanDur
                echo $Msg
                lgWriteLog SERIOUS "main" 1 "$Msg"
                #return 1
                (( returnCode += 1 ))
                continue

        else
                OraErr=`grep "ERROR " $TmpFilePath/$TmpFile`
                if [ $? -eq 0 ]; then
                        Msg="Exec clean "$CleanTable" of "$dbuser" keep durationin days PL/SQL error!!The error message:["$OraErr"]"
                        writeBuf=$CleanTable" of "$dbuser"@"$dbsid" keep duration in "$CleanCycle" "$CleanDur
                        echo $Msg
                        lgWriteLog SERIOUS "main" 1 "$Msg"
                        #return 1
                        (( returnCode += 1 ))
                        continue

                fi

        fi
        Msg="Clean "$CleanTable" of "$dbuser"@"$dbsid" keep duration in "$CleanCycle" "$CleanDur" sucess!!"
        lgWriteLog INFO "main" 0 "$Msg"
done
Msg="The "$ProcNm" end with return code $returnCode !!"
echo "$Msg"
lgWriteLog INFO "main" 0 "$Msg"
return $returnCode 