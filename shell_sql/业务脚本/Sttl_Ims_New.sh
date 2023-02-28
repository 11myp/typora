if [ $# -ne 2 ];then
  echo"Usage:incsLeakFiles.sh prov month"
  exit -1
fi

prov=$1
month=$2
year=`echo ${month} |cut -c 1-4`
premonLastD=`preday 1 date ${month}01`
start_date="${month}01"
nowDt=`preday 0 date`

>/app/mcb/incs/DELETED/maiyp/log/compare.${prov}

echo "" > /app/mcb/incs/DELETED/maiyp/log/ftpImsListTmp.${prov}
while [ ${start_date} -le ${nowDt} ];
do
  grep -oE "\bIBCF.*.dat\b" /app/mcb/incs/var/log/ftpTrans*_Recv_${prov}*ims.log.${start_date}* | grep -v "#file_name" |grep _${month}   >> /app/mcb/incs/DELETED/maiyp/log/ftpImsListTmp.${prov}
  start_date=`preday 1 date ${start_date}`
done


sort /app/mcb/incs/DELETED/maiyp/log/ftpImsListTmp.${prov} |uniq > /app/mcb/incs/DELETED/maiyp/log/ftpImsList.${prov}

imsOriCount=`cat /app/mcb/incs/DELETED/maiyp/log/ftpImsList.${prov}|wc -l`

ls  /app/mcb/incs/nfs/data/abnormal/ims/${prov}/*_${month}* |awk -F'/' '{print $10}' > /app/mcb/incs/DELETED/maiyp/log/ImsDeFail.${prov}
ImsDeFailNum=`ls  /app/mcb/incs/nfs/data/abnormal/ims/${prov}/*_${month}* |wc -l`




hh=`date +%H`
mm=`date +%M`
ss=`date +%S`

echo "${hh}:${mm}:${ss} ${prov}省IMS原文件数量是:${imsOriCount}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省解码faied IMS文件数量是：${ImsDeFailNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}



db_service_nm=`sqlplus -S /nolog 2>&1 <<EOF
        set echo off
                set feedback off
                set heading off
                set pagesize 0
                connect  incsdba/Cmit_incs0@incsm
                  select db_service_name from mcbdba.db_config_mapping_prov where prov_cd = '${prov}';
EOF`
sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/ImsCleanTmp.${prov} <<EOF
  set feedback off
  set echo off
  set linesize 500
  set pagesize 500
  select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\'  and stat != 'C' and prov_cd = ${prov};
EOF

cat /app/mcb/incs/DELETED/maiyp/log/ImsCleanTmp.${prov}|grep IBCF > /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${prov}

if [[ -s /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${prov} ]];then
  /app/mcb/incs/DELETED/zengtf/shell/cleanFiles.sh ${prov}
  cat /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${prov} |while read fileNm
  do
      prov=`echo $fileNm|awk -F'_' '{print $7}'`
      dt=`echo $fileNm|awk -F'_' '{print $8}'`
      if [[ -z "${prov}" || -z "${dt}" ]];then
         exit -1
      else
         cp /app/mcb/incs/nfs/arch/dirdetect/voice/${prov}/${dt}/$fileNm /app/mcb/incs/nfs/data/dirdetect/voice/${prov}
      fi
  done
  sleep 300
fi



sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbImsFilesTmp.${prov} <<EOF
  set feedback off
  set echo off
  set linesize 500
  set pagesize 500
  select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\' and stat = 'C' and prov_cd = ${prov};
EOF
grep IBCF /app/mcb/incs/DELETED/maiyp/log/dbImsFilesTmp.${prov}|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dbImsFiles.${prov}
curDbVoNums=`cat /app/mcb/incs/DELETED/maiyp/log/dbImsFiles.${prov} |wc -l`

awk -F'_'  -v OFS='_' '{print $2,$3,$4,$5,$6".dat"}' /app/mcb/incs/DELETED/maiyp/log/dbImsFiles.${prov} |sort|uniq> /app/mcb/incs/DELETED/maiyp/log/dbIms.${prov}
comm -13 /app/mcb/incs/DELETED/maiyp/log/dbIms.${prov} /app/mcb/incs/DELETED/maiyp/log/ftpImsList.${prov} > /app/mcb/incs/DELETED/maiyp/log/LeakDbFtp.${prov}
DbFtpLeakNum=`cat /app/mcb/incs/DELETED/maiyp/log/LeakDbFtp.${prov} |wc -l`

hh=`date +%H`
mm=`date +%M`
ss=`date +%S`
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音文件数${dfsImsNum},当前数据库成功处理文件数${curDbVoNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}

if [[ ${DbFtpLeakNum} -eq 0  ]];then
    curDay=`preday 0 date`
    echo "正在跑结算数据"
    /app/mcb/incs/bin/batch_run_sttl_daily.sh ${month}01 ${curDay} ${prov} VOICE
    /app/mcb/incs/bin/qb_exe.sh qb_sttl_voice_monthly_zg ${month} ${prov} ${nowDt}
    /app/mcb/incs/bin/qb_exe.sh qb_sttl_voice_monthly_qd ${month} ${prov} ${nowDt}

sqlplus incsdba/Cmit_incs0@${db_service_nm} 1>&2 > /app/mcb/incs/DELETED/maiyp/log/sttlResult.${prov}  <<EOF
    set linesize 200
        select 'voiceSttlSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt >= ${premonLastD} and db_insr_dt <= ${curDay} and sttl_dt like '${month}%' and ori_file_name like 'Vo_IBCF%';
    select 'voiceProcessFileDt###'||sum(cdr_count) from incsdba.process_state_cdr_file t where cdr_file_nm like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\'  and stat = 'C' and cdr_file_type = 'Voice'  and  prov_cd = ${prov}; 
    select 'voiceSttlFileDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt >= ${premonLastD} and db_insr_dt <= ${curDay} and ori_file_name like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\' and trans_flag != '1'; 
EOF

sqlplus incsdba/Cmit_incs0@incsm 1>&2 > /app/mcb/incs/DELETED/maiyp/log/sttlResultM.${prov}  <<EOF
    set linesize 200
    select 'voiceDailySttlDt###'||sum(cdr_count) from incsdba.sttl_voice_daily t where  t.sttl_dt like '${month}%' and prov_cd = ${prov} and cdr_type = 1 ;
    select 'voiceMonthlyZgSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_monthly_zg t where sttl_month = ${month} and prov_cd = ${prov} and cdr_type = 1; 
    select 'voiceMonthlyQdSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_monthly_qd t where sttl_month = ${month} and prov_cd = ${prov} and cdr_type = 1;
EOF
voiceProcessFileDt=`grep "^voiceProcessFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
voiceSttlFileDt=`grep "^voiceSttlFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
voiceSttlSttlDt=`grep "^voiceSttlSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
voiceDailySttlDt=`grep "^voiceDailySttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
voiceMonthlyZgSttlDt=`grep "^voiceMonthlyZgSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
voiceMonthlyQdSttlDt=`grep "^voiceMonthlyQdSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`

echo "${hh}:${mm}:${ss} ${prov}省${month}月份结果如下：" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}

echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音处理记录表话单量(以文件名做日期):${voiceProcessFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音分拣表话单量(以文件名做日期):${voiceSttlFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音分拣表话单量(以账期日做日期)：${voiceSttlSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音日结算表话单量：${voiceDailySttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音月结算表话单量(ZG)：${voiceMonthlyZgSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音月结算表话单量(QD)：${voiceMonthlyQdSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
fi