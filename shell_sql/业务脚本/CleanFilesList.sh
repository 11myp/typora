#!/usr/bin/bash
 #************************************************#
 # CleanFiles.sh                                  #
 # written by MaiYEPING                           #
 # Jan 03, 2023                                   #
 # Clean up  files                                #
 #功能：结算时获取失败文件列表后清理                 #
 #Uesge:CleanFiles.sh  ${prov}                    #
 #************************************************#

prov=$1
logFile=/app/mcb/incs/nfs/data/kb_ora/sttl/log/cleanlog.${prov}
deleteFileInfo=/app/mcb/incs/nfs/data/kb_ora/sttl/log/deleteFileInfo.${prov}

#获取数据库密码
mp_schema=incsdba
passwdtmp=`/app/mcb/incs/bin/PwdClient getdbpwd incss1 ${mp_schema} 2>/dev/null <<EOF
10.253.116.181:7088
EOF`
dbpasswd=`echo ${passwdtmp} |awk -F':' '{print $NF}'`



db_config_prov=`ksql "host=10.253.87.224 port=54321 user=${mp_schema} password=${dbpasswd} dbname=incsm" 2>/dev/null  <<EOF
select '#'||prov_cd||'|'||db_host||'|'||db_service_name||'#' from mcbdba.db_config_mapping_prov where prov_cd = ${prov};
EOF`

#若匹配不到库名和IP，则退出
if [ ${db_config_prov} ];then
  db_host=`echo ${db_config_prov} |awk -F'#' '{print $2}'|awk -F'|' '{print $2}'`
  db_name=`echo ${db_config_prov} |awk -F'#' '{print $2}'|awk -F'|' '{print $3}'`
  echo ${db_host} ${db_name}
else
  echo "Failed!can not get the db_server_nm!"  >>  ${logFile}
  exit -1
fi

   
fileNum=`cat /app/mcb/incs/nfs/data/kb_ora/sttl/log/cleanFiles.${prov}|wc -l`
curNum=1
hh=`date +%H`
mm=`date +%M`
ss=`date +%S`
echo "${hh}:${mm}:${ss}  开始清理数据">>${logFile}

cat /app/mcb/incs/nfs/data/kb_ora/sttl/log/cleanFiles.${prov}|while read aa
do
  hh=`date +%H`
  mm=`date +%M`
  ss=`date +%S`
  echo "${hh}:${mm}:${ss}  ${fileNum} 个文件数据需要清理,当前正在处理第${curNum}个文件:${aa}">>${logFile}

  #在结算中获取的失败列表，以省份区分文件，所以不需要通过文件判断省份
  if [[ $aa == Vo* ]];then
#       if [[ $aa == Vo_IBCF* ]];then
#          prov=`echo $aa|awk -F'_' '{print $7}'`
#       else
#          prov=`echo $aa|awk -F'_' '{print $4}'`
#       fi
          
# ksql "host=10.253.87.224 port=54321 user=incsdba password=${dbpasswd} dbname=incsm" 1>&2 > /app/mcb/incs/nfs/data/kb_ora/redoFiles_dblink.txt <<EOF
# select * from mcbdba.db_config_mapping_prov where prov_cd = ${prov};
# EOF

#     db_host=`cat /app/mcb/incs/nfs/data/kb_ora/kbFileLevel_db_link.txt|grep ${prov}|awk -F'|' '{print $1}'`
#     db_name=`cat /app/mcb/incs/nfs/data/kb_ora/kbFileLevel_db_link.txt|grep ${prov}|awk -F'|' '{print $3}'`
   
    clearVoFile ${aa} ${db_host} ${db_name}

  elif [[ ${aa} == Mo* ]];then
#       prov=`echo ${aa}|awk -F'_' '{print $2}'`
# ksql "host=10.253.87.224 port=54321 user=incsdba password=${dbpasswd} dbname=incsm" 1>&2 > /app/mcb/incs/nfs/data/kb_ora/redoFiles_dblink.txt <<EOF
# select * from mcbdba.db_config_mapping_prov where prov_cd = ${prov};
# EOF

#       db_host=`cat /app/mcb/incs/nfs/data/kb_ora/kbFileLevel_db_link.txt|grep ${prov}|awk -F'|' '{print $1}'`
#       db_name=`cat /app/mcb/incs/nfs/data/kb_ora/kbFileLevel_db_link.txt|grep ${prov}|awk -F'|' '{print $3}'`
    clearMoFile ${aa} ${db_host} ${db_name}
  else
#       prov=`echo ${aa}|awk -F'_' '{print $2}'|awk -F'.' '{print $1}'`
# ksql "host=10.253.87.224 port=54321 user=incsdba password=${dbpasswd} dbname=incsm" 1>&2 > /app/mcb/incs/nfs/data/kb_ora/redoFiles_dblink.txt <<EOF
# select * from mcbdba.db_config_mapping_prov where prov_cd = ${prov};
# EOF

#       db_host=`cat /app/mcb/incs/nfs/data/kb_ora/kbFileLevel_db_link.txt|grep ${prov}|awk -F'|' '{print $1}'`
#       db_name=`cat /app/mcb/incs/nfs/data/kb_ora/kbFileLevel_db_link.txt|grep ${prov}|awk -F'|' '{print $3}'`
      clearRMMFile ${aa} ${db_host} ${db_name}
    fi
  
    curNum=`expr $curNum + 1`
  done

hh=`date +%H`
mm=`date +%M`
ss=`date +%S`
echo "${hh}:${mm}:${ss}  清理数据结束">>${logFile}

clearVoFile()
{
if [[ $1 == Vo_IBCF* ]];then
  prov=`echo $1|awk -F'_' '{print $7}'`
else
  prov=`echo $1|awk -F'_' '{print $4}'`
fi
db_host=$2
db_name=$3

ProcessDtTmp=`ksql "host=${db_host} port=54321 user=incsdba password=${dbpasswd} dbname=${db_name}" -t 2>/dev/null  <<EOF
  select process_dt from incsdba.process_state_cdr_file  where cdr_file_nm = '${aa}' and prov_cd=${prov} and cdr_file_type='Voice';
EOF`
ProcessDt=`echo ${ProcessDtTmp}|awk '{print $NF}'`


#先删除查重表和错单表，这两张表的分区是呼叫时间
if [[ ${ProcessDt} == *20* ]];then
  MinMaxDtTmp=`ksql "host=${db_host} port=54321 user=incsdba password=${dbpasswd} dbname=${db_name}" -t 2>/dev/null  <<EOF
  select min(call_start_dt)||'|'||max(call_start_dt) from incsdba.cdr_voice_${prov}_p${ProcessDt} where ori_file_name = '$aa';
EOF
  begin_dt=`echo ${MinMaxDtTmp}|awk -F'|' '{print $1}'`
  end_dt=`echo ${MinMaxDtTmp}|awk -F'|' '{print $2}'`
  if [[ ${begin_dt} == *20* ]];then
    ksql "host=${db_host} port=54321 user=incsdba password=${dbpasswd} dbname=${db_name}"  2>/dev/null >> ${deleteFileInfo}  <<EOF
      delete from incsdba.ckdup_ks_vo_${prov} where (sttl_dt between ${begin_dt} and ${end_dt}) and ktag = '${aa}';
      delete from incsdba.err_cdr_voice_${prov} where (db_insr_dt between ${begin_dt} and ${end_dt}) and ori_file_name = '${aa}';
      commit;
EOF

  else
  #如果记录表没记录，查重表和错单表有记录则执行这一步
  ksql "host=${db_host} port=54321 user=incsdba password=${dbpasswd} dbname=${db_name}"  2>/dev/null >> ${deleteFileInfo} <<EOF
    delete from incsdba.ckdup_ks_vo_${prov} where ktag = '$1';
    delete from incsdba.err_cdr_voice_${prov} where ori_file_name = '$1';
    commit;
EOF
  fi

  #删除记录表，详单表，分拣表，重单表，详单审计表，错单审计表。这几张表的分区是处理时间
  ksql "host=${db_host} port=54321 user=incsdba password=${dbpasswd} dbname=${db_name}"  2>/dev/null >> ${deleteFileInfo} <<EOF
    delete from  incsdba.process_state_cdr_file t where process_dt='${ProcessDt}' and  t.cdr_file_nm= '${aa}' and cdr_file_type='Voice';
    delete from incsdba.cdr_voice_${prov}_p${ProcessDt} where ori_file_name = '${aa}';
    delete from incsdba.sttl_voice_${prov}_p${ProcessDt} where ori_file_name = '${aa}';
    delete from incsdba.duplicate_cdr_voice_p${ProcessDt} where ori_file_name = '${aa}';
    delete from incsdba.cdr_voice_file_audit  where ori_file_name = '${aa}';
    delete from incsdba.err_voice_file_audit  where ori_file_name = '${aa}';
    commit;
EOF

else
  hh=`date +%H`
  mm=`date +%M`
  ss=`date +%S`
  echo  ${hh}:${mm}:${ss}  ${aa}:"redo ERROR:can not find the process_dt"  >> ${logFile}
          
  ksql "host=${db_host} port=54321 user=incsdba password=${dbpasswd} dbname=${db_name}"  2>/dev/null >> ${deleteFileInfo} <<EOF
    delete from  incsdba.process_state_cdr_file t where t.cdr_file_nm = '$1';
    delete from incsdba.cdr_voice_${prov} where ori_file_name = '$1';
    delete from incsdba.sttl_voice_${prov}  where ori_file_name = '$1';
    delete from incsdba.ckdup_ks_vo_${prov} where ktag = '$1';
    delete from incsdba.err_cdr_voice_${prov}  where ori_file_name = '$1';
    delete from incsdba.duplicate_cdr_voice  where ori_file_name = '$1';
    delete from incsdba.cdr_voice_file_audit  where ori_file_name = '$1';
    delete from incsdba.err_voice_file_audit  where ori_file_name = '$1';
    commit;
EOF

fi 
}


clearMoFile()
{
prov=`echo $1|awk -F'_' '{print $2}'`
db_host=$2
db_name=$3

ProcessDtTmp=`ksql "host=${db_host} port=54321 user=incsdba password=${dbpasswd} dbname=${db_name}" -t 2>/dev/null  <<EOF
  select process_dt from incsdba.process_state_cdr_file  where cdr_file_nm = '${aa}' and prov_cd=${prov} and cdr_file_type='Voice';
EOF`
ProcessDt=`echo ${ProcessDtTmp}|awk '{print $NF}'`


if [[ ${process_dt} == *20* ]];then
#删除短信详单，查重表
ksql "host=${db_host} port=54321 user=incsdba password=${dbpasswd} dbname=${db_name}"  2>/dev/null >> ${deleteFileInfo} <<EOF
  delete from incsdba.cdr_sms_${prov}_p${ProcessDt} where ori_file_name = '${aa}' and db_insr_dt = ${ProcessDt} ;
  delete from incsdba.ckdup_ks_sm_${prov}_p${ProcessDt} where ktag = '${aa}' and sttl_dt =${ProcessDt} ;
  commit;
EOF

#删除记录表，错单表，重单表，短信详单经分审计表，短信错单经分审计表
ksql "host=${db_host} port=54321 user=incsdba password=${dbpasswd} dbname=${db_name}"  2>/dev/null >> ${deleteFileInfo} <<EOF
  delete from incsdba.process_state_cdr_file t where process_dt='${ProcessDt}' and  t.cdr_file_nm = '${aa}';
  delete from incsdba.err_cdr_sms_p${ProcessDt} where ori_file_name = '${aa}';
  delete from incsdba.duplicate_cdr_sms_p${ProcessDt} where ori_file_name = '${aa}';
  delete from incsdba.cdr_sms_file_audit_p${ProcessDt} where ori_file_name = '${aa}';
  delete from incsdba.err_sms_file_audit_P${ProcessDt} where ori_file_name = '${aa}';
  commit;
EOF
else
  hh=`date +%H`
  mm=`date +%M`
  ss=`date +%S`
  echo ${hh}:${mm}:${ss} ${aa}:"redo ERROR:can not find the process_dt"  >> ${logFile}
         
  ksql "host=${db_host} port=54321 user=incsdba password=${dbpasswd} dbname=${db_name}"  2>/dev/null >> ${deleteFileInfo} <<EOF
    delete from incsdba.process_state_cdr_file t where t.cdr_file_nm = '${aa}';
    delete from incsdba.err_cdr_sms where ori_file_name = '${aa}';
    delete from incsdba.duplicate_cdr_sms where ori_file_name = '${aa}';
    delete from incsdba.cdr_sms_${prov} where ori_file_name = '${aa}';
    delete from incsdba.ckdup_ks_sm_${prov} where ktag = '${aa}';
    delete from incsdba.cdr_sms_file_audit where ori_file_name = '${aa}';
    delete from incsdba.err_sms_file_audit where ori_file_name = '${aa}';
    commit;
EOF
fi
}


clearRMMFile()
{
    prov=`echo $1|cut -c16-18`
    db_host=$2
    db_name=$3
 
 
ksql "host=${db_host} port=54321 user=incsdba password=${dbpasswd} dbname=${db_name}" 1>&2 <<EOF
   delete from  incsdba.process_state_cdr_file t where t.cdr_file_nm = '$1';
   delete from incsdba.cdr_rmm_${prov} where ori_file_name = '$1';
   delete from incsdba.ckdup_ks_rmm_${prov} where ktag = '$1';
   delete from incsdba.err_cdr_rmm  where ori_file_name = '$1';
   delete from incsdba.duplicate_cdr_rmm  where ori_file_name = '$1';
   delete from incsdba.cdr_rmm_file_audit where ori_file_name = '$1';
   delete from incsdba.err_rmm_file_audit where ori_file_name = '$1';
  commit;
EOF
}