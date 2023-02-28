#!/bin/bash
 #************************************************#
 # Fdiff_Sttl_Proc_Filenm.sh                      #
 # written by MaiYEPING                           #
 # Jan 05, 2023                                   #
 #功能：核对重处理文件是否准确                      #
 #Uesge:Fdiff_Sttl_Proc_Filenm.sh  ${filelist}    #
 #************************************************#

# start_date="${month}01"
# nowDt=`date +"%Y%m%d"`
#/app/mcb/incs/nfs/data/kb_ora/sttl/log/cleanFiles.${prov}
filelist=$1


curDay=`date +"%Y%m%d"`

mp_schema=incsdba
passwdtmp=`/app/mcb/incs/bin/PwdClient getdbpwd incss1 ${mp_schema} 2>/dev/null <<EOF
10.253.116.181:7088
EOF`
dbpasswd=`echo ${passwdtmp} |awk -F':' '{print $NF}'`
#若获取不到密码
if [ ! ${dbpasswd} ];then
  echo "获取密码失败" >> ${LOGFILE} 
  exit -1
fi

#目录若不存在则创建
if [ ! -d /app/mcb/incs/nfs/data/kb_ora/sttl/ ];then
   mkdir -p /app/mcb/incs/nfs/data/kb_ora/sttl/
fi

if [ ! -d /app/mcb/incs/nfs/data/kb_ora/sttl/log/ ];then
   mkdir -p /app/mcb/incs/nfs/data/kb_ora/sttl/log/
fi

LOGFILE=/app/mcb/incs/nfs/data/kb_ora/sttl/log/fdiff_sttl_proc_filenm.${curDay}

#判断主机是否安装ksql
KSQL=`whereis ksql|awk -F':' '{print $NF}'`
if [ ! ${KSQL} ];then
  echo "ksql is not installed!please check"  >> ${LOGFILE}
  exit -1
fi


cat ${filelist} |while read filenm
do
  if [[ ${filenm} == RMM* ]];then
    prov=`echo ${filenm}|awk -F"_" '{print $2}' | awk -F"." '{print $1}'`
  elif [[ ${filenm} == Mo* ]];then
    prov=`echo ${filenm} |awk -F"_" '{print $2}'`
  elif [[ ${filenm} == Vo_IBCF* ]];then
    prov=`echo ${filenm} | awk -F"_" '{print $7}'`
  else
    prov=`echo ${filenm} | awk -F"_" '{print $4}'`
  fi
  db_config_prov=`${KSQL} "host=10.253.87.224 port=54321 user=${mp_schema} password=${dbpasswd} dbname=incsm" -t 2>/dev/null  <<EOF
    select '#'||prov_cd||'|'||db_host||'|'||db_service_name||'#' from mcbdba.db_config_mapping_prov where prov_cd = ${prov};
EOF`
  #若匹配不到库名和IP，则退出
  if [ ${db_config_prov} ];then
    db_host=`echo ${db_config_prov} |awk -F'#' '{print $2}'|awk -F'|' '{print $2}'`
    db_name=`echo ${db_config_prov} |awk -F'#' '{print $2}'|awk -F'|' '{print $3}'`
  else
    echo "Failed!can not get the db_server_nm!"
    exit -1
  fi
  DupliCountTmp=`${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}" -t 2>/dev/null  <<EOF
    select duplicate_count from incsdba.process_state_cdr_file t where stat = 'C' and cdr_file_type = 'Voice' and prov_cd = ${prov} and cdr_file_nm='${filenm}' and cdr_count=0 and duplicate_count >0;
EOF`
  DupliCount=`echo ${DupliCountTmp}|awk '{print $NF}'`
  ProcCountTmp=`${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}" -t 2>/dev/null  <<EOF
    select cdr_count from incsdba.process_state_cdr_file t where stat = 'C' and cdr_file_type = 'Voice' and prov_cd = ${prov} and cdr_file_nm='${filenm}';
EOF`
  ProcCount=`echo ${ProcCountTmp}|awk '{print $NF}'`

  SttlCountTmp=`${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}"  -t 2>/dev/null  <<EOF
    select ori_file_name||'|'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt between ${start_date} and ${curDay} and ori_file_name ='${filenm}' and trans_flag != '1' group by ori_file_name;
EOF`
  SttlCount=`echo ${SttlCountTmp} |awk '{print $NF}'`
  #如果sttl表话单量不等于记录表话单量，说明清理表有遗漏
  if [[ ${DupliCount} -gt 0 ]] || [[ ${SttlCount} -ne ${ProcCount} ]];then
    echo ${filenm} "clearup failed!" "ProcCount:${ProcCount}" "SttlCount:${SttlCount}" >> ${LOGFILE}
    exit -1
  fi
done
