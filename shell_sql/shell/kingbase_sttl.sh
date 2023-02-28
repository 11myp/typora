#!/bin/bash
E_WRONG_ARGS=65
Number_of_expected_args=2
DB_PASSWORD=`getdbpwd incsdba`
PROV=$1
month=$2

#脚本正确使用提示
script_parameters="Usage:incsLeakFiles.sh PROV month"


#检查参数
if [ $# -ne $Number_of_expected_args ]
then
    echo "Usage:`basename $0` $script_parameters"  
       exit $E_WRONG_ARGS
fi
> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}

ssh -n mcbpcs${PROV} "grep Vo /opt/mcb/pcs/var/log/FileDecode*|grep "_${PROV}_${MONTH}"|grep "Decode_output"" > /app/mcb/incs/DELETED/zengtf/log/pcsVolistTmp.${PROV}
cat /app/mcb/incs/DELETED/zengtf/log/pcsVolistTmp.${PROV}|awk -F'/VoFiles/' '{print $2}'|awk -F' sucess' '{print $1}'|sort|uniq > /app/mcb/incs/DELETED/zengtf/log/pcsVoList.${PROV}
pcsVoNum=`cat /app/mcb/incs/DELETED/zengtf/log/pcsVoList.${PROV}|wc -l`
find /app/mcb/incs/nfs/arch/dirdetect/voice/${PROV}/ -name "Vo_*_${PROV}_${MONTH}*DECODE" > /app/mcb/incs/DELETED/zengtf/log/dfsVoListTmp.${PROV}
cat /app/mcb/incs/DELETED/zengtf/log/dfsVoListTmp.${PROV}|awk -F'Vo_' '{print "Vo_"$2}'|sort|uniq > /app/mcb/incs/DELETED/zengtf/log/dfsVoList.${PROV}
dfsVoNum=`cat /app/mcb/incs/DELETED/zengtf/log/dfsVoList.${PROV}|wc -l`

ssh -n mcbpcs${PROV} "grep Mo /opt/mcb/pcs/var/log/FileDecode*|grep "_"${PROV}"_${MONTH}"|grep "outgoing"" > /app/mcb/incs/DELETED/zengtf/log/pcsMoListTmp.${PROV}
cat /app/mcb/incs/DELETED/zengtf/log/pcsMoListTmp.${PROV}|awk -F'/' '{print $14}'|awk -F' To' '{print $1}'|sort|uniq > /app/mcb/incs/DELETED/zengtf/log/pcsMoList.${PROV}
pcsMoNum=`cat /app/mcb/incs/DELETED/zengtf/log/pcsMoList.${PROV}|wc -l`
find /app/mcb/incs/nfs/arch/dirdetect/sms/${PROV} -name "Mo*_${PROV}_${MONTH}*" > /app/mcb/incs/DELETED/zengtf/log/dfsMoListTmp.${PROV}
cat /app/mcb/incs/DELETED/zengtf/log/dfsMoListTmp.${PROV}|awk -F'Mo_' '{print "Mo_"$2}'|sort|uniq > /app/mcb/incs/DELETED/zengtf/log/dfsMoList.${PROV}
dfsMoNum=`cat /app/mcb/incs/DELETED/zengtf/log/dfsMoList.${PROV}|wc -l`

find /app/mcb/incs/nfs/arch/dirdetect/rmm/${PROV} -name "RMM${MONTH}*_${PROV}*" > /app/mcb/incs/DELETED/zengtf/log/dfsRmmListTmp.${PROV}
cat /app/mcb/incs/DELETED/zengtf/log/dfsRmmListTmp.${PROV}|awk -F'RMM' '{print "RMM"$2}'|sort|uniq > /app/mcb/incs/DELETED/zengtf/log/dfsRmmList.${PROV}
dfsRmmNum=`cat /app/mcb/incs/DELETED/zengtf/log/dfsRmmList.${PROV}|wc -l`

PROCESS_TM=`date +"%Y-%m-%d %H:%M:%S"`

echo "${PROCESS_TM}  ${PROV}省通信服务器语音解码成功数量是：${pcsVoNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "${PROCESS_TM}  ${PROV}省文件服务器备份目录下语音数量是：${dfsVoNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "${PROCESS_TM}  ${PROV}省通信服务器短信解码成功数量是：${pcsMoNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "${PROCESS_TM}  ${PROV}省文件服务器备份目录下短信数量是：${dfsMoNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}

let leakVoNums=${pcsVoNum}-${dfsVoNum}
let leakMoNums=${pcsMoNum}-${dfsMoNum}
VoPre=`awk 'BEGIN{printf"%0.4f","'"${dfsVoNum}"'"/"'"${pcsVoNum}"'"}'`
MoPre=`awk 'BEGIN{printf"%0.4f","'"${dfsMoNum}"'"/"'"${pcsMoNum}"'"}'`

if [ `expr ${VoPre} \> 0.99` -eq 0 ];then
  echo "${PROCESS_TM} 语音文件完整系数${VoPre}，遗失文件数${leakVoNums},暂不处理" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
  exit -1
else
  echo "${PROCESS_TM} 语音文件完整系数${VoPre}，遗失文件数${leakVoNums},可以补处理文件" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
  fi

if [ `expr ${MoPre} \> 0.99` -eq 0 ];then
  echo "${PROCESS_TM} 语音文件完整系数${MoPre}，遗失文件数${leakMoNums},暂不处理" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
  exit -1
else
  echo "${PROCESS_TM} 语音文件完整系数${MoPre}，遗失文件数${leakMoNums},可以补处理文件" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
fi

DB_SERVICE_NM=`ksql -h 10.253.87.224 -p 54321 -U incsdba -d incsm -W${DB_PASSWORD}  -t -c 'select db_service_name from mcbdba.db_config_mapping_PROV where PROV_cd =${PROV};'`
DB_HOST=`ksql -h 10.253.87.224 -p 54321 -U incsdba -d incsm -W${DB_PASSWORD}  -t -c 'select db_host from mcbdba.db_config_mapping_PROV where PROV_cd =${PROV};'`


while true 
do
  #查询是否有处理失败的文件,若有，清理数据
  ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/VoCleanTmp.${PROV} <<EOF
   select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'V%_${PROV}_${MONTH}_%' and stat !='C';
  EOF

  ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/MoCleanTmp.${PROV} <<EOF
    select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'M%_${PROV}_${MONTH}_%' and stat != 'C';
  EOF
  ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/RMMCleanTmp.${PROV} <<EOF
    select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'RMM${MONTH}%_${PROV}%' and stat != 'C';
  EOF
  grep '^Vo_' /app/mcb/incs/DELETED/maiyp/log/VoCleanTmp.${PROV}  > /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${PROV}
  grep '^Mo_' /app/mcb/incs/DELETED/maiyp/log/MoCleanTmp.${PROV}  >> /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${PROV}
  grep '^RMM' /app/mcb/incs/DELETED/maiyp/log/RMMCleanTmp.${PROV} >> /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${PROV}
  
  /app/mcb/incs/DELETED/maiyp/shell/cleanFiles.sh ${PROV}

  #比较数据库成功的数量和dfs上的文件，缺少的放文件
  ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbVoFilesTmp.${PROV} <<EOF
    select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'V%_${PROV}_${MONTH}_%' and stat = 'C';
  EOF

  ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbMoFilesTmp.${PROV} <<EOF
    select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'M%_${PROV}_${MONTH}_%' and stat = 'C';
  EOF

  ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbRMMFilesTmp.${PROV} <<EOF
    select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'RMM${MONTH}%_${PROV}%' and stat = 'C';
  EOF

  grep Mo_ /app/mcb/incs/DELETED/maiyp/log/dbMoFilesTmp.${PROV}|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dbMoFiles.${PROV}
  grep Vo_ /app/mcb/incs/DELETED/maiyp/log/dbVoFilesTmp.${PROV}|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dbVoFiles.${PROV}
  grep RMM /app/mcb/incs/DELETED/maiyp/log/dbRmmFilesTmp.${PROV}|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dbRmmFiles.${PROV}
  comm -13 /app/mcb/incs/DELETED/maiyp/log/dbVoFiles.${PROV} /app/mcb/incs/DELETED/maiyp/log/dfsVoList.${PROV} > /app/mcb/incs/DELETED/maiyp/log/LeakFiles.${PROV}
  comm -13 /app/mcb/incs/DELETED/maiyp/log/dbMoFiles.${PROV} /app/mcb/incs/DELETED/maiyp/log/dfsMoList.${PROV} >> /app/mcb/incs/DELETED/maiyp/log/LeakFiles.${PROV}
  comm -13 /app/mcb/incs/DELETED/maiyp/log/dbRmmFiles.${PROV} /app/mcb/incs/DELETED/maiyp/log/dfsRmmList.${PROV} >> /app/mcb/incs/DELETED/maiyp/log/LeakFiles.${PROV}

  cat /app/mcb/incs/DELETED/maiyp/log/LeakFiles.${PROV}|while read fileNm
  do
    if [[ $fileNm == Vo* ]];then
      PROV=`echo $fileNm|awk -F'_' '{print $4}'`
      if [[ $PROV == 240 ]] || [[ $PROV == 270 ]];then
        dt=`echo $fileNm|awk -F'_' '{print $6}'`
      else
        dt=`echo $fileNm|awk -F'_' '{print $5}'`
      fi
      cp /app/mcb/incs/nfs/arch/dirdetect/voice/${PROV}/${dt}/$fileNm /app/mcb/incs/nfs/data/dirdetect/voice/${PROV}
    elif [[ $fileNm == Mo* ]];then
      PROV=`echo $fileNm|awk -F'_' '{print $2}'`
      cp /app/mcb/incs/nfs/arch/dirdetect/sms/${PROV}/$fileNm  /app/mcb/incs/nfs/data/dirdetect/sms/${PROV}
    else
      PROV=`echo $fileNm|cut -c16-18`
      cp /app/mcb/incs/nfs/arch/dirdetect/rmm/${PROV}/$fileNm  /app/mcb/incs/nfs/data/dirdetect/rmm/${PROV}
    fi
  done
  sleep 1000
  #比较当前数据库文件数量是否与文件服务器一致
    ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbVoFilesTmp.${PROV} <<EOF
    select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'V%_${PROV}_${MONTH}_%' and stat = 'C';
  EOF

  ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbMoFilesTmp.${PROV} <<EOF
    select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'M%_${PROV}_${MONTH}_%' and stat = 'C';
  EOF

  ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbRMMFilesTmp.${PROV} <<EOF
    select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'RMM${MONTH}%_${PROV}%' and stat = 'C';
  EOF

  curDbVoNums=`cat /app/mcb/incs/DELETED/maiyp/log/dbVoFilesTmp.${PROV}|grep '^Vo_'|sort|uniq|wc -l`
  curDbMoNums=`cat /app/mcb/incs/DELETED/maiyp/log/dbMoFilesTmp.${PROV}|grep '^Mo_'|sort|uniq|wc -l`
  curDbRmmNums=`cat /app/mcb/incs/DELETED/maiyp/log/dbRmmFilesTmp.${PROV}|grep '^RMM'|sort|uniq|wc -l`

  PROCESS_TM=`date +"%Y-%m-%d %H:%M:%S"`
  echo "${PROCESS_TM} ${PROV}省${MONTH}月份语音文件数${dfsVoNum},当前数据库成功处理文件数${curDbVoNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
  echo "${PROCESS_TM} ${PROV}省${MONTH}月份短信文件数${dfsMoNum},当前数据库成功处理文件数${curDbMoNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
  echo "${PROCESS_TM} ${PROV}省${MONTH}月份彩信文件数${dfsRmmNum},当前数据库成功处理文件数${curDbRmmNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}

  nowDt=`preday 0 date`
  if [[ ${curDbVoNums} == ${dfsVoNum} && ${curDbMoNums} == ${dfsMoNum} && ${curDbRmmNums} == ${dfsRmmNum} ]];then
        curDay=`preday 0 date`

        echo "正在跑结算数据"
        /app/mcb/incs/bin/batch_run_sttl_daily.sh ${MONTH}01 ${curDay} ${PROV} ALL
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_voice_monthly_zg ${MONTH} ${PROV} ${nowDt}
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_sms_monthly_zg ${MONTH} ${PROV} ${nowDt}
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_rmm_monthly_zg ${MONTH} ${PROV} ${nowDt}
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_voice_monthly_qd ${MONTH} ${PROV} ${nowDt}
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_sms_monthly_qd ${MONTH} ${PROV} ${nowDt}
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_rmm_monthly_qd ${MONTH} ${PROV} ${nowDt}
#        /app/mcb/incs/bin/qb_exe.sh qb_input_out_call ${PROV} ${MONTH}
#        /app/mcb/incs/bin/qb_exe.sh qb_month_vsr_data ${PROV} ${MONTH}
#        /app/mcb/incs/bin/qb_exe.sh qb_month_new_vsr_data ${MONTH}
  ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/sttlResultVo.${PROV} <<EOF
    select 'smsCdrSttlDt###'||count(*) from incsdba.cdr_sms_${PROV} where db_insr_dt >= ${MONTH}01 and db_insr_dt <= ${curDay} and sttl_dt like '${MONTH}%' and send_state = '0' and sttl_fee <> 0 and sttl_PROV_cd = ${PROV};
    select 'voiceSttlSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_${PROV}  where db_insr_dt >= ${MONTH}01 and db_insr_dt <= ${curDay} and sttl_dt like '${MONTH}%';
    select 'rmmCdrSttlDt###'||count(*) from incsdba.cdr_rmm_${PROV} where sttl_dt like '${MONTH}%' and send_status in ('01','02','03'); 
    select 'smsProcessFileDt###'||sum(cdr_count) from incsdba.process_state_cdr_file t where cdr_file_nm like 'Mo_${PROV}_${MONTH}%'; 
    select 'smsCdrFileDt###'||count(*) from incsdba.cdr_sms_${PROV} where db_insr_dt >= ${MONTH}01 and db_insr_dt <= ${curDay} and ori_file_name like 'Mo_${PROV}_${MONTH}%' ;
    select 'voiceProcessFileDt###'||sum(cdr_count) from incsdba.process_state_cdr_file t where cdr_file_nm like '%_${PROV}_${MONTH}%' and stat = 'C' and cdr_file_type = 'Voice' ; 
    select 'voiceSttlFileDt###'||sum(cdr_count) from incsdba.sttl_voice_${PROV}  where db_insr_dt >= ${MONTH}01 and db_insr_dt <= ${curDay} and ori_file_name like '%_${PROV}_${MONTH}%' and trans_flag != '1'; 
    select 'rmmProcessFileDt###'||sum(cdr_count) from incsdba.process_state_cdr_file t where cdr_file_nm like 'RMM${MONTH}%' and PROV_cd = ${PROV} and stat = 'C'; 
    select 'rmmCdrFileDt###'||count(*) from incsdba.cdr_rmm_${PROV} where ori_file_name like 'RMM${MONTH}%';  
  EOF
  ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/sttlResultMo.${PROV} <<EOF
    select 'smsDailySttlDt###'||sum(cdr_count) from incsdba.sttl_sms_daily  where prov_cd = ${PROV} and sttl_dt like '${MONTH}%';
    select 'smsMonthlyZgSttlDt###'||sum(cdr_count) from incsdba.sttl_sms_monthly_zg where prov_cd = ${PROV} and sttl_month = ${MONTH}; 
    select 'smsMonthlyQdSttlDt###'||sum(cdr_count) from incsdba.sttl_sms_monthly_qd where prov_cd = ${PROV} and sttl_month = ${MONTH};
    select 'voiceDailySttlDt###'||sum(cdr_count) from incsdba.sttl_voice_daily t where  t.sttl_dt like '${MONTH}%' and prov_cd = ${PROV} ;
    select 'voiceMonthlyZgSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_monthly_zg t where sttl_month = ${MONTH} and prov_cd = ${PROV}; 
    select 'voiceMonthlyQdSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_monthly_qd t where sttl_month = ${MONTH} and prov_cd = ${PROV};
    select 'rmmDailySttlDt###'||sum(cdr_count) from incsdba.sttl_rmm_daily where prov_cd  = ${PROV} and sttl_dt like '${MONTH}%';  
    select 'rmmMonthlyZgSttlDt###'||sum(cdr_count) from incsdba.sttl_rmm_monthly_zg where prov_cd = ${PROV} and sttl_month = '${MONTH}';  
    select 'rmmMonthlyQdSttlDt###'||sum(cdr_count) from incsdba.sttl_rmm_monthly_qd where prov_cd = ${PROV} and sttl_month = '${MONTH}';
  EOF
  voiceProcessFileDt=`grep "^voiceProcessFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  voiceSttlFileDt=`grep "^voiceSttlFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  voiceSttlSttlDt=`grep "^voiceSttlSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  voiceDailySttlDt=`grep "^voiceDailySttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  voiceMonthlyZgSttlDt=`grep "^voiceMonthlyZgSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  voiceMonthlyQdSttlDt=`grep "^voiceMonthlyQdSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  smsProcessFileDt=`grep "^smsProcessFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  smsCdrFileDt=`grep "^smsCdrFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  smsCdrSttlDt=`grep "^smsCdrSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  smsDailySttlDt=`grep "^smsDailySttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  smsMonthlyZgSttlDt=`grep "^smsMonthlyZgSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  smsMonthlyQdSttlDt=`grep "^smsMonthlyQdSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  rmmProcessFileDt=`grep "^rmmProcessFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  rmmCdrFileDt=`grep "^rmmCdrFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  rmmCdrSttlDt=`grep "^rmmCdrSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  rmmDailySttlDt=`grep "^rmmDailySttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  rmmMonthlyZgSttlDt=`grep "^rmmMonthlyZgSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  rmmMonthlyQdSttlDt=`grep "^rmmMonthlyQdSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${PROV}|awk -F'###' '{print $2}'`
  

  echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份结果如下：" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}

echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份语音解码成功文件数${pcsVoNum},当前数据库成功处理文件数${dfsVoNum},缺失文件数${leakVoNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份语音处理记录表话单量(以文件名做日期):${voiceProcessFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份语音分拣表话单量(以文件名做日期):${voiceSttlFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份语音分拣表话单量(以账期日做日期)：${voiceSttlSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份语音日结算表话单量：${voiceDailySttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份语音月结算表话单量(ZG)：${voiceMonthlyZgSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份语音月结算表话单量(QD)：${voiceMonthlyQdSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}

echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份短信解码成功文件数${pcsMoNum},当前数据库成功处理文件数${dfsMoNum},缺失文件数${leakMoNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份短信处理记录表话单量(以文件名做日期):${smsProcessFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份短信详单表话单量(以文件名做日期):${smsCdrFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份短信详单表话单量(以账期日做日期)：${smsCdrSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份短信日结算表话单量：${smsDailySttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份短信月结算表话单量(ZG)：${smsMonthlyZgSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份短信月结算表话单量(QD)：${smsMonthlyQdSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}

echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份数据库成功处理彩信文件数${dfsRmmNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份彩信处理记录表话单量(以文件名做日期):${rmmProcessFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份彩信详单表话单量(以文件名做日期):${rmmCdrFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份彩信详单表话单量(以账期日做日期)：${rmmCdrSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份彩信日结算表话单量：${rmmDailySttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份彩信月结算表话单量(ZG)：${rmmMonthlyZgSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}
echo "`date +"%Y-%m-%d %H:%M:%S"` ${PROV}省${MONTH}月份彩信月结算表话单量(QD)：${rmmMonthlyQdSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${PROV}

exit -1
fi

done
