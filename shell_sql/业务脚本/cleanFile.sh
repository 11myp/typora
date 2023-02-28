#!/usr/bin/bash

mp_schema=incsdba
mp_dbpwd=Cmit_incs0

if [ $# -ne 1 ];then
  echo"Usage:cleanFiles.sh prov"
  exit -1
fi

prov=$1

logFile=/app/mcb/incs/DELETED/maiyp/log/cleaningLog.${prov}
>${logFile}

fileNum=`cat /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${prov}|wc -l`
curNum=1
hh=`date +%H`
mm=`date +%M`
ss=`date +%S`
echo "${hh}:${mm}:${ss}  开始清理数据">>${logFile}

clearVoFile()
{
    prov=`echo $1|awk -F'_' '{print $4}'`
    echo $prov
    file_dt=`echo $1|awk -F'_' '{print $5}'`
        db_service_nm=$2

    process_dt=`sqlplus -S /nolog 2>&1 <<EOF
        set echo off
                set feedback off
                set heading off
                set pagesize 0
                connect  ${mp_schema}/${mp_dbpwd}@${db_service_nm}
                  select t.process_dt from incsdba.process_state_cdr_file t where t.cdr_file_nm = '$1';
EOF`
    if [[ ${process_dt} == *20* ]];then
      process_dt=`echo $process_dt|sed 's/ //g'`

sqlplus -S ${mp_schema}/${mp_dbpwd}@${db_service_nm} <<EOF  2>&1
       set feedback off
       set heading off
       set pagesize 0
          delete from incsdba.ckdup_ks_vo_${prov} where ktag = '$1';
                 commit;
EOF


sqlplus -S ${mp_schema}/${mp_dbpwd}@${db_service_nm} <<EOF  2>&1
       set feedback off
       set heading off
       set pagesize 0
          delete from  incsdba.process_state_cdr_file t where t.cdr_file_nm = '$1';
          delete from incsdba.cdr_voice_${prov} partition(P${process_dt}) where ori_file_name = '$1';
          delete from incsdba.sttl_voice_${prov} partition(P${process_dt}) where ori_file_name = '$1';
          delete from incsdba.err_cdr_voice partition(P${process_dt}) where ori_file_name = '$1';
          delete from incsdba.duplicate_cdr_voice partition(P${process_dt}) where ori_file_name = '$1';
          delete from incsdba.pre_merge_file_audit where ori_file_name = '$1';
          delete from incsdba.pre_merge_cdr_bgsm_${prov} where ori_file_name = '$1';
          delete from incsdba.cdr_voice_file_audit partition(P${process_dt}) where ori_file_name = '$1';
          commit;
EOF
   else
      echo $1" redo ERROR:can not find the process_dt"
sqlplus -S ${mp_schema}/${mp_dbpwd}@${db_service_nm} <<EOF  2>&1
       set feedback off
       set heading off
       set pagesize 0
          delete from  incsdba.process_state_cdr_file t where t.cdr_file_nm = '$1';
          delete from incsdba.cdr_voice_${prov} where ori_file_name = '$1';
          delete from incsdba.sttl_voice_${prov}  where ori_file_name = '$1';
          delete from incsdba.ckdup_ks_vo_${prov} where ktag = '$1';
          delete from incsdba.err_cdr_voice  where ori_file_name = '$1';
          delete from incsdba.duplicate_cdr_voice  where ori_file_name = '$1';
          delete from incsdba.pre_merge_file_audit where ori_file_name = '$1';
          delete from incsdba.pre_merge_cdr_bgsm_${prov} where ori_file_name = '$1';
          delete from incsdba.cdr_voice_file_audit  where ori_file_name = '$1';
          commit;
EOF

   fi
}


clearMoFile()
{
    prov=`echo $1|awk -F'_' '{print $2}'`
    echo $prov
    file_dt=`echo $1|awk -F'_' '{print $3}'`
        db_service_nm=$2

    process_dt=`sqlplus -S /nolog 2>&1 <<EOF
        set echo off
                set feedback off
                set heading off
                set pagesize 0
                connect  ${mp_schema}/${mp_dbpwd}@${db_service_nm}
                  select t.process_dt from incsdba.process_state_cdr_file t where t.cdr_file_nm = '$1';
EOF`
    if [[ ${process_dt} == *20* ]];then
      process_dt=`echo $process_dt|sed 's/ //g'`

sqlplus -S ${mp_schema}/${mp_dbpwd}@${db_service_nm} <<EOF  2>&1
       set feedback off
       set heading off
       set pagesize 0
           delete from incsdba.cdr_sms_${prov} where ori_file_name = '$1';
           delete from incsdba.ckdup_ks_sm_${prov} where ktag = '$1';
           commit;
EOF

sqlplus -S ${mp_schema}/${mp_dbpwd}@${db_service_nm} <<EOF  2>&1
       set feedback off
       set heading off
       set pagesize 0
          delete from  incsdba.process_state_cdr_file t where t.cdr_file_nm = '$1';
          delete from incsdba.err_cdr_sms partition(P${process_dt}) where ori_file_name = '$1';
          delete from incsdba.duplicate_cdr_sms partition(P${process_dt}) where ori_file_name = '$1';
          delete from incsdba.cdr_sms_file_audit partition(P${process_dt}) where ori_file_name = '$1';
          commit;
EOF
   else
     echo $1" redo ERROR:can not find the process_dt"
sqlplus -S ${mp_schema}/${mp_dbpwd}@${db_service_nm} <<EOF  2>&1
       set feedback off
       set heading off
       set pagesize 0
          delete from incsdba.process_state_cdr_file t where t.cdr_file_nm = '$1';
          delete from incsdba.err_cdr_sms where ori_file_name = '$1';
          delete from incsdba.duplicate_cdr_sms where ori_file_name = '$1';
          delete from incsdba.cdr_sms_${prov} where ori_file_name = '$1';
          delete from incsdba.ckdup_ks_sm_${prov} where ktag = '$1';
          delete from incsdba.cdr_sms_file_audit where ori_file_name = '$1';
          commit;
EOF
   fi
}


clearRMMFile()
{
    prov=`echo $1|cut -c16-18`
    echo $prov
    file_dt=`echo $1|cut -c4-11`
    db_service_nm=$2


sqlplus -S ${mp_schema}/${mp_dbpwd}@${db_service_nm} <<EOF  2>&1
       set feedback off
       set heading off
       set pagesize 0
          delete from  incsdba.process_state_cdr_file t where t.cdr_file_nm = '$1';
          delete from incsdba.cdr_rmm_${prov} where ori_file_name = '$1';
          delete from incsdba.ckdup_ks_rmm_${prov} where ktag = '$1';
          delete from incsdba.err_cdr_rmm  where ori_file_name = '$1';
          delete from incsdba.duplicate_cdr_rmm  where ori_file_name = '$1';
          delete from incsdba.cdr_rmm_file_audit where ori_file_name = '$1';
          commit;
EOF
}

cat /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${prov}|while read aa
  do
    hh=`date +%H`
    mm=`date +%M`
    ss=`date +%S`
    echo "${hh}:${mm}:${ss}  ${fileNum} 个文件数据需要清理,当前正在处理第${curNum}个文件:$aa">>${logFile}

    if [[ $aa == Vo* ]];then
            file_prov=`echo ${aa}|awk -F'_' '{print $4}'`
            db_service_nm=`sqlplus -S /nolog 2>&1 <<EOF
        set echo off
                set feedback off
                set heading off
                set pagesize 0
                connect  ${mp_schema}/${mp_dbpwd}@incsm
                  select db_service_name from mcbdba.db_config_mapping_prov where prov_cd = '${file_prov}';
EOF`
       echo ${db_service_nm}
       clearVoFile $aa ${db_service_nm}
    elif [[ $aa == Mo* ]];then
            file_prov=`echo ${aa}|awk -F'_' '{print $2}'`
            db_service_nm=`sqlplus -S /nolog 2>&1 <<EOF
        set echo off
                set feedback off
                set heading off
                set pagesize 0
                connect  ${mp_schema}/${mp_dbpwd}@incsm
                  select db_service_name from mcbdba.db_config_mapping_prov where prov_cd = '${file_prov}';
EOF`
       echo ${db_service_nm}
       clearMoFile $aa ${db_service_nm}
    else
           file_prov=`echo ${aa}|awk -F'_' '{print $2}'|awk -F'.' '{print $1}'`
           db_service_nm=`sqlplus -S /nolog 2>&1 <<EOF
        set echo off
                set feedback off
                set heading off
                set pagesize 0
                connect  ${mp_schema}/${mp_dbpwd}@incsm
                  select db_service_name from mcbdba.db_config_mapping_prov where prov_cd = '${file_prov}';
EOF`
       echo ${db_service_nm}
       clearRMMFile $aa  ${db_service_nm}
    fi

    curNum=`expr $curNum + 1`
  done

hh=`date +%H`
mm=`date +%M`
ss=`date +%S`
echo "${hh}:${mm}:${ss}  清理数据结束">>${logFile}