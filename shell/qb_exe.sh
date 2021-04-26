#!/bin/bash
#-------------------------------------------------------------------------
#
# NAME
# alias_qb.sh
#
# COPYRIGHT
# COPYRIGHT Chinamobile SZ Company 2007.
#           All rights reserved.
#

# --------------------------------------------------------------------------
#

# DRIZE Team 

# Purpose:  change statistics for dr. This is the list of added function:
#       1. Extern_InitPlatform S_STAT... 000
#       2. Extern_InitIDX
#       3. Extern_syncvar=dr_SyncIdxVar @String "$sv_syncvar"
#       4. Extern_CommitIDX ""              
#       5. Extern_ReleasePlatform
#       6. Extern_AbortIDX
#       7. Extern_sttl_err
#       8. Extern_writelog
# This lib is:  $MCB_HOME/lib/nls/msg/libdrapi.sh
# Explain: the symbol '--' before sqlplus phase is remarked by wangwei.
#***********************************************************

. ilogger.sh

configfile=$MCB_HOME/$MCB_APPID/conf/alias_qb.conf
logfile=$MCB_HOME/$MCB_APPID/var/log/alias_qb.log

mkdir -p $MCB_HOME/$MCB_APPID/var/log
mkdir -p $MCB_HOME/$MCB_APPID/var/tmp

function show_help
{
   if [[ "$proc" = '*' ]]
   then
      echo Usage: alias_qb.sh command [argument...]
      echo command must be one of follow:
      
      for p in ${proc_name[@]}
      do
         echo $p
      done
      
      echo
      echo Type [alias_qb.sh command -help] for each command detail describe
      echo       
   else
      echo "${proc_help[proc_index]}"
      echo
   fi
   return
}

function sumdb_err
{
        grep "unable to open file " $MCB_HOME/$MCB_APPID/var/tmp/.alias_qb_$proc_index.log
        if [ $? -ne 1 ]; then
                echo "Unable to open file!"
                message="Unable to open file!"
                lgWriteLog SERIOUS "sumdb_err" 1 "${proc_sql1[$proc_index]} ${message}"
                return 1
        fi
#       grep "ERROR " $MCB_HOME/$MCB_APPID/var/tmp/.alias_qb_$proc_index.log |grep "ORA-" $MCB_HOME/$MCB_APPID/var/tmp/.alias_qb_$proc_index.log
#       if [ $? -ne 1 ]; then
#               echo "PL/SQL is wrong!"
#               message="PL/SQL is wrong!"
#               lgWriteLog SERIOUS "sumdb_err" 1 "${proc_sql1[$proc_index]} ${message}" 
#               return 1
#       fi
        grep "sql_ret_err" $MCB_HOME/$MCB_APPID/var/tmp/.alias_qb_$proc_index.log
        if [ $? -ne 1 ]; then
                echo "PL/SQL executing result is wrong!"
                message="PL/SQL executing result is wrong!"
                lgWriteLog SERIOUS "sumdb_err" 1 "${proc_sql1[$proc_index]} ${message}" 
                return 1
        fi
}


# main
. ${configfile}

if (( $# == 0 ))
then
   #show help text
   proc=*
   show_help
   exit
fi

if (( $# == 1 ))
then
   if [[ "$1" = "-help" ]]
   then
      #show help text
      proc=*
      show_help
      exit
   fi
fi

typeset -i i
i=0
i_mark=0
for p in ${proc_name[@]}
do
   if [[ "$1" = "${p}" ]]
   then
      proc=$p   
      proc_index=$i
      i_mark=1
      break
   fi
   (( i += 1 ))
done

if [[ "$i_mark" = "0" ]]
then
   #show warning message
   sv_userid="gsmdba"
   proc="$1"
   arg[0]="0"
   arg[1]="0"
   message="Invalid arguments!"   
   echo "Invalid arguments!"
   exit
fi

#ZengXH 20070929{
if (( $# == 2 ))
then
   if [[ "$2" = "-help" ]]
   then
      show_help
      exit
   fi
fi
#ZengXH 20070929}

lgInit ${logfile} "COM" "alias_qb.sh" $1 "Y"
if [ "$?" -ne "0" ]; then
    echo "Init log file failed!"
    exit
fi    
lgWriteLog INFO "main" 0 "alias_qb.sh start!"

echo 'Process name:' $proc
echo 'Process start date and time:' `date`
echo

#zhenglc add 2010.3.15
sv_sysdate=`date +"%Y%m%d%H%M%S"`

sv_dbsid=${proc_dbsid[$proc_index]}
sv_userid=${proc_userid[$proc_index]}

sv_password=`echo "${pwd_server}" | PwdClient getdbpwd ${sv_dbsid} ${sv_userid} | grep "sPasswd" | awk -F ':' '{print $2}' | sed 's/ //g'`
if [ -z "${sv_password}" ] ; then
    message="Get db passwd error"
    arg[0]="0"
    arg[1]="0"
    lgWriteLog SERIOUS "main" -1 "${proc_sql1[$proc_index]} ${message}!"
    echo "Get db passwd error"
    exit
fi

conn_str="$sv_userid/$sv_password@$sv_dbsid"

arg_count=${proc_arg_count[$proc_index]}
(( i_media = arg_count + 1 ))
if (( $#>i_media ))
then
   message="have excessive arguments!"
   arg[0]="0"
   arg[1]="0"
   lgWriteLog SERIOUS "main" -1 "${proc_sql1[$proc_index]} ${message}"
   echo "have excessive arguments!"
   
   exit
fi

tab_count=${proc_tab_count[$proc_index]}

shift

i=0
while (( $# > 0 ))
do
   arg[$i]=$1
   (( i += 1 ))
   shift
done

if [[ "${arg[0]}" = "" ]]
then
   arg[0]=$(eval "${proc_arg1[$proc_index]}")
   if (test $? = 1) 
   then
      message="Get First Argument's Default Value Error!"
      lgWriteLog SERIOUS "main" -1 "${proc_sql1[$proc_index]} ${message}"
      echo "Get First Argument's Default Value Error!"
      
      exit
   fi
fi

if [[ "${arg[1]}" = "" ]]
then
   arg[1]=$(eval "${proc_arg2[$proc_index]}")
   if (test $? = 1) 
   then
      message="Get Second Argument's Default Value Error!"
      lgWriteLog SERIOUS "main" -1"${proc_sql1[$proc_index]} ${message}"
      echo "Get Second Argument's Default Value Error!"
      
      exit
   fi
fi

if [[ "${arg[2]}" = "" ]]
then
   arg[2]=$(eval "${proc_arg3[$proc_index]}")
   if (test $? = 1) 
   then
      message="Get Third Argument's Default Value Error!"
      lgWriteLog SERIOUS "main" -1 "${proc_sql1[$proc_index]} ${message}"
      echo "Get Third Argument's Default Value Error!"
      
      exit
   fi
fi

if [ ! -r "$MCB_SQL_PATH/${proc_sql1[$proc_index]}" ]
then
   message="Can not open $MCB_SQL_PATH/${proc_sql1[$proc_index]} sql file"
   echo "$message"
   lgWriteLog SERIOUS "main" -1 "${proc_sql1[$proc_index]} ${message}!"
   
   exit
fi

echo sql=${proc_sql1[$proc_index]}
echo param=${arg[*]}

echo "aaaaaaaaaa$conn_str"
sqlplus -S /nolog 2>&1 >$MCB_HOME/$MCB_APPID/var/tmp/.alias_qb_$proc_index.log <<EOF
connect $conn_str
@$MCB_SQL_PATH/${proc_sql1[$proc_index]} ${arg[*]} $sv_sysdate
EOF

# 20070929{
if (test $? -ne 0) then
   message="Can not access db or Can not write to $MCB_HOME/$MCB_APPID/var/tmp/.alias_qb_$proc_index.log"
   lgWriteLog SERIOUS "main" -1 "${proc_sql1[$proc_index]} ${message}!"
   echo "Failed! Can not access db or Can not write to $MCB_HOME/$MCB_APPID/var/tmp/.alias_qb_$proc_index.log"
   exit -1
fi
# 20070929}

sumdb_err

if [ $? -ne 0 ]; then
        exit -1
else
   message="Success"
   echo "$message"
   lgWriteLog INFO "main" 0 "Process ${message}!"
fi

echo
echo 'Process name:' $proc
echo 'Porcess end date and time:' `date`
echo
lgWriteLog INFO "main" 0 "alias_qb.sh finished!"