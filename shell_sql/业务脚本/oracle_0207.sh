#!/usr/bin/bash

if [ $# -ne 2 ];then
  echo"Usage:incsLeakFiles.sh prov month"
  exit -1
fi

prov=$1
month=$2

>/app/mcb/incs/DELETED/maiyp/log/compare.${prov}

ssh -n mcbpcs${prov} "grep Vo /opt/mcb/pcs/var/log/FileDecode*|grep "_${prov}_${month}"|grep "Decode_output"" > /app/mcb/incs/DELETED/maiyp/log/pcsVolistTmp.${prov}
cat /app/mcb/incs/DELETED/maiyp/log/pcsVolistTmp.${prov}|awk -F'/VoFiles/' '{print $2}'|awk -F' sucess' '{print $1}'|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/pcsVoList.${prov}
pcsVoNum=`cat /app/mcb/incs/DELETED/maiyp/log/pcsVoList.${prov}|wc -l`
find /app/mcb/incs/nfs/arch/dirdetect/voice/${prov}/ -name "Vo_*_${prov}_${month}*DECODE" > /app/mcb/incs/DELETED/maiyp/log/dfsVoListTmp.${prov}
cat /app/mcb/incs/DELETED/maiyp/log/dfsVoListTmp.${prov}|awk -F'Vo_' '{print "Vo_"$2}'|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dfsVoList.${prov}
dfsVoNum=`cat /app/mcb/incs/DELETED/maiyp/log/dfsVoList.${prov}|wc -l`

ssh -n mcbpcs${prov} "grep Mo /opt/mcb/pcs/var/log/FileDecode*|grep "_"${prov}"_${month}"|grep "outgoing"" > /app/mcb/incs/DELETED/maiyp/log/pcsMoListTmp.${prov}
cat /app/mcb/incs/DELETED/maiyp/log/pcsMoListTmp.${prov}|awk -F'/' '{print $14}'|awk -F' To' '{print $1}'|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/pcsMoList.${prov}
pcsMoNum=`cat /app/mcb/incs/DELETED/maiyp/log/pcsMoList.${prov}|wc -l`
find /app/mcb/incs/nfs/arch/dirdetect/sms/${prov} -name "Mo*_${prov}_${month}*" > /app/mcb/incs/DELETED/maiyp/log/dfsMoListTmp.${prov}
cat /app/mcb/incs/DELETED/maiyp/log/dfsMoListTmp.${prov}|awk -F'Mo_' '{print "Mo_"$2}'|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dfsMoList.${prov}
dfsMoNum=`cat /app/mcb/incs/DELETED/maiyp/log/dfsMoList.${prov}|wc -l`

find /app/mcb/incs/nfs/arch/dirdetect/rmm/${prov} -name "RMM${month}*_${prov}*" > /app/mcb/incs/DELETED/maiyp/log/dfsRmmListTmp.${prov}
cat /app/mcb/incs/DELETED/maiyp/log/dfsRmmListTmp.${prov}|awk -F'RMM' '{print "RMM"$2}'|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dfsRmmList.${prov}
dfsRmmNum=`cat /app/mcb/incs/DELETED/maiyp/log/dfsRmmList.${prov}|wc -l`

hh=`date +%H`
mm=`date +%M`
ss=`date +%S`
echo "${hh}:${mm}:${ss} ${prov}省通信服务器语音解码成功数量是：${pcsVoNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省文件服务器备份目录下语音数量是：${dfsVoNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省通信服务器短信解码成功数量是：${pcsMoNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省文件服务器备份目录下短信数量是：${dfsMoNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}

let leakVoNums=${pcsVoNum}-${dfsVoNum}
let leakMoNums=${pcsMoNum}-${dfsMoNum}
VoPre=`awk 'BEGIN{printf"%0.4f","'"${dfsVoNum}"'"/"'"${pcsVoNum}"'"}'`
MoPre=`awk 'BEGIN{printf"%0.4f","'"${dfsMoNum}"'"/"'"${pcsMoNum}"'"}'`

if [ `expr ${VoPre} \> 0.99` -eq 0 ];then
   echo "${hh}:${mm}:${ss} 语音文件完整系数${VoPre}，遗失文件数${leakVoNums},暂不处理" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
   exit -1
else
   echo "${hh}:${mm}:${ss} 语音文件完整系数${VoPre}，遗失文件数${leakVoNums},可以补处理文件" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
   fi

if [ `expr ${MoPre} \> 0.99` -eq 0 ];then
   echo "${hh}:${mm}:${ss} 语音文件完整系数${MoPre}，遗失文件数${leakMoNums},暂不处理" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
   exit -1
else
   echo "${hh}:${mm}:${ss} 语音文件完整系数${MoPre}，遗失文件数${leakMoNums},可以补处理文件" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
fi

db_service_nm=`sqlplus -S /nolog 2>&1 <<EOF
        set echo off
                set feedback off
                set heading off
                set pagesize 0
                connect  incsdba/Cmit_incs0@incsm
                  select db_service_name from mcbdba.db_config_mapping_prov where prov_cd = '${prov}';
EOF`

while [ true ]
do

#查看是否有处理失败状态不为C的文件，清理数据
sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/voCleanTmp.${prov} <<EOF
set feedback off
set echo off
set linesize 500
set pagesize 500
select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'V%_${prov}_${month}_%' and stat != 'C';
EOF

sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/moCleanTmp.${prov} <<EOF
set feedback off
set echo off
set linesize 500
set pagesize 500
select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'M%_${prov}_${month}_%' and stat != 'C';
EOF

sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/rmmCleanTmp.${prov} <<EOF
set feedback off
set echo off
set linesize 500
set pagesize 500
select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'RMM${month}%_${prov}%' and stat != 'C';
EOF

#select cdr_file_nm from incsdba.process_state_cdr_fiel where cdr_file_nm like '%_${prov}_${month}_%'  and stat != 'C';
#select cdr_file_nm from incsdba.process_state_cdr_fiel where cdr_file_nm like 'RMM${month}%_${prov}%' 
cat /app/mcb/incs/DELETED/maiyp/log/voCleanTmp.${prov}|grep 'Vo_' > /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${prov}
cat /app/mcb/incs/DELETED/maiyp/log/moCleanTmp.${prov}|grep 'Mo_' >> /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${prov}
cat /app/mcb/incs/DELETED/maiyp/log/rmmCleanTmp.${prov}|grep 'RMM' >> /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${prov}

/app/mcb/incs/DELETED/maiyp/shell/cleanFiles.sh ${prov}

#比较数据库成功的数量和dfs上的文件，缺少的放文件
sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbVoFilesTmp.${prov} <<EOF
set feedback off
set echo off
set linesize 500
set pagesize 500
select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'V%_${prov}_${month}_%' and stat = 'C';
EOF


sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbMoFilesTmp.${prov} <<EOF
set feedback off
set echo off
set linesize 500
set pagesize 500
select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'M%_${prov}_${month}_%' and stat = 'C';
EOF

sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbRmmFilesTmp.${prov} <<EOF
set feedback off
set echo off
set linesize 500
set pagesize 500
select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'RMM${month}%_${prov}%' and stat = 'C';
EOF


grep Mo_ /app/mcb/incs/DELETED/maiyp/log/dbMoFilesTmp.${prov}|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dbMoFiles.${prov}
grep Vo_ /app/mcb/incs/DELETED/maiyp/log/dbVoFilesTmp.${prov}|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dbVoFiles.${prov}
grep RMM /app/mcb/incs/DELETED/maiyp/log/dbRmmFilesTmp.${prov}|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dbRmmFiles.${prov}

comm -13 /app/mcb/incs/DELETED/maiyp/log/dbVoFiles.${prov} /app/mcb/incs/DELETED/maiyp/log/dfsVoList.${prov} > /app/mcb/incs/DELETED/maiyp/log/LeakFiles.${prov}
comm -13 /app/mcb/incs/DELETED/maiyp/log/dbMoFiles.${prov} /app/mcb/incs/DELETED/maiyp/log/dfsMoList.${prov} >> /app/mcb/incs/DELETED/maiyp/log/LeakFiles.${prov}
comm -13 /app/mcb/incs/DELETED/maiyp/log/dbRmmFiles.${prov} /app/mcb/incs/DELETED/maiyp/log/dfsRmmList.${prov} >> /app/mcb/incs/DELETED/maiyp/log/LeakFiles.${prov}

cat /app/mcb/incs/DELETED/maiyp/log/LeakFiles.${prov}|while read fileNm
do
  if [[ $fileNm == Vo* ]];then
    prov=`echo $fileNm|awk -F'_' '{print $4}'`
    if [[ $prov == 240 ]] || [[ $prov == 270 ]];then
      dt=`echo $fileNm|awk -F'_' '{print $6}'`
    else
      dt=`echo $fileNm|awk -F'_' '{print $5}'`
    fi
    cp /app/mcb/incs/nfs/arch/dirdetect/voice/${prov}/${dt}/$fileNm /app/mcb/incs/nfs/data/dirdetect/voice/${prov}
  elif [[ $fileNm == Mo* ]];then
    prov=`echo $fileNm|awk -F'_' '{print $2}'`
    cp /app/mcb/incs/nfs/arch/dirdetect/sms/${prov}/$fileNm  /app/mcb/incs/nfs/data/dirdetect/sms/${prov}
  else
    prov=`echo $fileNm|cut -c16-18`
    cp /app/mcb/incs/nfs/arch/dirdetect/rmm/${prov}/$fileNm  /app/mcb/incs/nfs/data/dirdetect/rmm/${prov}
  fi
done

sleep 1000

#比较当前数据库文件数量是否与文件服务器一致
sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbVoFilesTmp.${prov} <<EOF
set feedback off
set echo off
set linesize 500
set pagesize 500
select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'V%_${prov}_${month}_%' and stat = 'C';
EOF

sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbMoFilesTmp.${prov} <<EOF
set feedback off
set echo off
set linesize 500
set pagesize 500
select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'M%_${prov}_${month}_%' and stat = 'C';
EOF

sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbRmmFilesTmp.${prov} <<EOF
set feedback off
set echo off
set linesize 500
set pagesize 500
select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'RMM${month}%_${prov}%' and stat = 'C';
EOF

curDbVoNums=`cat /app/mcb/incs/DELETED/maiyp/log/dbVoFilesTmp.${prov}|grep 'Vo_'|sort|uniq|wc -l`
curDbMoNums=`cat /app/mcb/incs/DELETED/maiyp/log/dbMoFilesTmp.${prov}|grep 'Mo_'|sort|uniq|wc -l`
curDbRmmNums=`cat /app/mcb/incs/DELETED/maiyp/log/dbRmmFilesTmp.${prov}|grep 'RMM'|sort|uniq|wc -l`

hh=`date +%H`
mm=`date +%M`
ss=`date +%S`
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音文件数${dfsVoNum},当前数据库成功处理文件数${curDbVoNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份短信文件数${dfsMoNum},当前数据库成功处理文件数${curDbMoNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份彩信文件数${dfsRmmNum},当前数据库成功处理文件数${curDbRmmNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}

nowDt=`preday 0 date`
if [[ ${curDbVoNums} == ${dfsVoNum} && ${curDbMoNums} == ${dfsMoNum} && ${curDbRmmNums} == ${dfsRmmNum} ]];then
        curDay=`preday 0 date`

        echo "正在跑结算数据"
        /app/mcb/incs/bin/batch_run_sttl_daily.sh ${month}01 ${curDay} ${prov} ALL
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_voice_monthly_zg ${month} ${prov} ${nowDt}
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_sms_monthly_zg ${month} ${prov} ${nowDt}
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_rmm_monthly_zg ${month} ${prov} ${nowDt}
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_voice_monthly_qd ${month} ${prov} ${nowDt}
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_sms_monthly_qd ${month} ${prov} ${nowDt}
        /app/mcb/incs/bin/qb_exe.sh qb_sttl_rmm_monthly_qd ${month} ${prov} ${nowDt}
#        /app/mcb/incs/bin/qb_exe.sh qb_input_out_call ${prov} ${month}
#        /app/mcb/incs/bin/qb_exe.sh qb_month_vsr_data ${prov} ${month}
#        /app/mcb/incs/bin/qb_exe.sh qb_month_new_vsr_data ${month}

sqlplus incsdba/Cmit_incs0@${db_service_nm} 1>&2 > /app/mcb/incs/DELETED/maiyp/log/sttlResult.${prov}  <<EOF
        set linesize 200
        select 'smsCdrSttlDt###'||count(*) from incsdba.cdr_sms_${prov} where db_insr_dt >= ${month}01 and db_insr_dt <= ${curDay} and sttl_dt like '${month}%' and send_state = '0' and sttl_fee <> 0 and sttl_prov_cd = ${prov};
        select 'voiceSttlSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt >= ${month}01 and db_insr_dt <= ${curDay} and sttl_dt like '${month}%';
        select 'rmmCdrSttlDt###'||count(*) from incsdba.cdr_rmm_${prov} where sttl_dt like '${month}%' and send_status in ('01','02','03'); 
        select 'smsProcessFileDt###'||sum(cdr_count) from incsdba.process_state_cdr_file t where cdr_file_nm like 'Mo_${prov}_${month}%'; 
        select 'smsCdrFileDt###'||count(*) from incsdba.cdr_sms_${prov} where db_insr_dt >= ${month}01 and db_insr_dt <= ${curDay} and ori_file_name like 'Mo_${prov}_${month}%' ;
        select 'voiceProcessFileDt###'||sum(cdr_count) from incsdba.process_state_cdr_file t where cdr_file_nm like '%_${prov}_${month}%' and stat = 'C' and cdr_file_type = 'Voice' ; 
        select 'voiceSttlFileDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt >= ${month}01 and db_insr_dt <= ${curDay} and ori_file_name like '%_${prov}_${month}%' and trans_flag != '1'; 
        select 'rmmProcessFileDt###'||sum(cdr_count) from incsdba.process_state_cdr_file t where cdr_file_nm like 'RMM${month}%' and prov_cd = ${prov} and stat = 'C'; 
        select 'rmmCdrFileDt###'||count(*) from incsdba.cdr_rmm_${prov} where ori_file_name like 'RMM${month}%';  
EOF

sqlplus incsdba/Cmit_incs0@incsm 1>&2 > /app/mcb/incs/DELETED/maiyp/log/sttlResultM.${prov}  <<EOF
        set linesize 200
        select 'smsDailySttlDt###'||sum(cdr_count) from incsdba.sttl_sms_daily  where prov_cd = ${prov} and sttl_dt like '${month}%';
        select 'smsMonthlyZgSttlDt###'||sum(cdr_count) from incsdba.sttl_sms_monthly_zg where prov_cd = ${prov} and sttl_month = ${month}; 
        select 'smsMonthlyQdSttlDt###'||sum(cdr_count) from incsdba.sttl_sms_monthly_qd where prov_cd = ${prov} and sttl_month = ${month};
        select 'voiceDailySttlDt###'||sum(cdr_count) from incsdba.sttl_voice_daily t where  t.sttl_dt like '${month}%' and prov_cd = ${prov} ;
        select 'voiceMonthlyZgSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_monthly_zg t where sttl_month = ${month} and prov_cd = ${prov}; 
        select 'voiceMonthlyQdSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_monthly_qd t where sttl_month = ${month} and prov_cd = ${prov};
        select 'rmmDailySttlDt###'||sum(cdr_count) from incsdba.sttl_rmm_daily where prov_cd  = ${prov} and sttl_dt like '${month}%';  
        select 'rmmMonthlyZgSttlDt###'||sum(cdr_count) from incsdba.sttl_rmm_monthly_zg where prov_cd = ${prov} and sttl_month = '${month}';  
        select 'rmmMonthlyQdSttlDt###'||sum(cdr_count) from incsdba.sttl_rmm_monthly_qd where prov_cd = ${prov} and sttl_month = '${month}';
EOF

voiceProcessFileDt=`grep "^voiceProcessFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
voiceSttlFileDt=`grep "^voiceSttlFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
voiceSttlSttlDt=`grep "^voiceSttlSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
voiceDailySttlDt=`grep "^voiceDailySttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
voiceMonthlyZgSttlDt=`grep "^voiceMonthlyZgSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
voiceMonthlyQdSttlDt=`grep "^voiceMonthlyQdSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
smsProcessFileDt=`grep "^smsProcessFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
smsCdrFileDt=`grep "^smsCdrFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
smsCdrSttlDt=`grep "^smsCdrSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
smsDailySttlDt=`grep "^smsDailySttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
smsMonthlyZgSttlDt=`grep "^smsMonthlyZgSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
smsMonthlyQdSttlDt=`grep "^smsMonthlyQdSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
rmmProcessFileDt=`grep "^rmmProcessFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
rmmCdrFileDt=`grep "^rmmCdrFileDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
rmmCdrSttlDt=`grep "^rmmCdrSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
rmmDailySttlDt=`grep "^rmmDailySttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
rmmMonthlyZgSttlDt=`grep "^rmmMonthlyZgSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
rmmMonthlyQdSttlDt=`grep "^rmmMonthlyQdSttlDt###" /app/mcb/incs/DELETED/maiyp/log/sttlResul*${prov}|awk -F'###' '{print $2}'`

echo "${hh}:${mm}:${ss} ${prov}省${month}月份结果如下：" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}

echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音解码成功文件数${pcsVoNum},当前数据库成功处理文件数${dfsVoNum},缺失文件数${leakVoNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音处理记录表话单量(以文件名做日期):${voiceProcessFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音分拣表话单量(以文件名做日期):${voiceSttlFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音分拣表话单量(以账期日做日期)：${voiceSttlSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音日结算表话单量：${voiceDailySttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音月结算表话单量(ZG)：${voiceMonthlyZgSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音月结算表话单量(QD)：${voiceMonthlyQdSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}

echo "${hh}:${mm}:${ss} ${prov}省${month}月份短信解码成功文件数${pcsMoNum},当前数据库成功处理文件数${dfsMoNum},缺失文件数${leakMoNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份短信处理记录表话单量(以文件名做日期):${smsProcessFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份短信详单表话单量(以文件名做日期):${smsCdrFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份短信详单表话单量(以账期日做日期)：${smsCdrSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份短信日结算表话单量：${smsDailySttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份短信月结算表话单量(ZG)：${smsMonthlyZgSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份短信月结算表话单量(QD)：${smsMonthlyQdSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}

echo "${hh}:${mm}:${ss} ${prov}省${month}月份数据库成功处理彩信文件数${dfsRmmNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份彩信处理记录表话单量(以文件名做日期):${rmmProcessFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份彩信详单表话单量(以文件名做日期):${rmmCdrFileDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份彩信详单表话单量(以账期日做日期)：${rmmCdrSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份彩信日结算表话单量：${rmmDailySttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份彩信月结算表话单量(ZG)：${rmmMonthlyZgSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份彩信月结算表话单量(QD)：${rmmMonthlyQdSttlDt}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}

exit -1
fi

done