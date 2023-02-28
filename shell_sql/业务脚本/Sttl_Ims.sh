#!/bin/bash
if [ $# -ne 2 ];then
  echo"Usage:incsLeakFiles.sh prov month"
  exit -1
fi

prov=$1
month=$2

>/app/mcb/incs/DELETED/maiyp/log/compare.${prov}

#解码成功文件数量
grep "IBCF" /app/mcb/incs/var/log/ftpTransfer_Recv_${prov}_ims_incs.log.*|grep "successfully"|grep _${month}|awk -F'[' '{print $2}'|awk -F']' '{print $1}'|sort|uniq|grep -v "^$" >/app/mcb/incs/DELETED/maiyp/log/ftpImsList.${prov}
imsOriCount=`wc -l /app/mcb/incs/DELETED/maiyp/log/ftpImsList.${prov}`

#备份文件下的文件数
find /app/mcb/incs/nfs/arch/dirdetect/voice/${prov}/ -name "Vo_IBCF*_${month}*_*${prov}_20*"  > /app/mcb/incs/DELETED/maiyp/log/dfsImsListTmp.${prov}
cat /app/mcb/incs/DELETED/maiyp/log/dfsImsListTmp.${prov}|awk -F'Vo_' '{print "Vo_"$2}'|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dfsImsList.${prov}
dfsImsNum=`cat /app/mcb/incs/DELETED/maiyp/log/dfsImsList.${prov}|wc -l`

hh=`date +%H`
mm=`date +%M`
ss=`date +%S`

echo "${hh}:${mm}:${ss} ${prov}解码成功文件数量是：${imsOriCount}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省文件服务器备份目录下语音数量是：${dfsImsNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}

let ImsLeakNums=${imsOriCount}-${dfsImsNum}
ImsPre=`awk 'BEGIN{printf"%0.4f","'"${dfsImsNum}"'"/"'"${imsOriCount}"'"}'`
if [ `expr ${ImsPre} \> 0.99` -eq 0 ];then
   echo "${hh}:${mm}:${ss} 语音文件完整系数${ImsPre}，遗失文件数${ImsLeakNums},暂不处理" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
   exit -1
else
   echo "${hh}:${mm}:${ss} 语音文件完整系数${ImsPre}，遗失文件数${ImsLeakNums},可以补处理文件" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
fi


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
  select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\'  and stat != 'C';
EOF

cat /app/mcb/incs/DELETED/maiyp/log/ImsCleanTmp.${prov}|grep IBCF > /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${prov}

#查看是否有处理失败状态不为C的文件，清理数据
/app/mcb/incs/DELETED/zengtf/shell/cleanFiles.sh ${prov}

#比较数据库成功的数量和dfs上的文件，缺少的放文件
sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbImsFilesTmp.${prov} <<EOF
  set feedback off
  set echo off
  set linesize 500
  set pagesize 500
  select cdr_file_nm from incsdba.process_state_cdr_file where  cdr_file_nm like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\'  and stat = 'C';
EOF
grep IBCF /app/mcb/incs/DELETED/maiyp/log/dbImsFilesTmp.${prov}|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dbImsFiles.${prov}
comm -13 /app/mcb/incs/DELETED/maiyp/log/dbImsFiles.${prov} /app/mcb/incs/DELETED/maiyp/log/dfsImsList.${prov} > /app/mcb/incs/DELETED/maiyp/log/ImsLeakFiles.${prov}

cat /app/mcb/incs/DELETED/maiyp/log/ImsLeakFiles.${prov}|while read fileNm
do
    prov=`echo $fileNm|awk -F'_' '{print $7}'`
    dt=`echo $fileNm|awk -F'_' '{print $8}'`
    cp /app/mcb/incs/nfs/arch/dirdetect/voice/${prov}/${dt}/$fileNm /app/mcb/incs/nfs/data/dirdetect/voice/${prov}
done
sleep 3000

#比较当前数据库文件数量是否与文件服务器一致
sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbImsFilesTmp.${prov} <<EOF
  set feedback off
  set echo off
  set linesize 500
  set pagesize 500
  select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\' and stat = 'C';
EOF
curDbVoNums=`cat /app/mcb/incs/DELETED/maiyp/log/dbImsFilesTmp.${prov}|grep IBCF|sort|uniq|wc -l`

hh=`date +%H`
mm=`date +%M`
ss=`date +%S`
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音文件数${dfsImsNum},当前数据库成功处理文件数${curDbVoNums}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
nowDt=`preday 0 date`
if [[ ${curDbVoNums} == ${dfsImsNum}  ]];then
    curDay=`preday 0 date`
    echo "正在跑结算数据"
    /app/mcb/incs/bin/batch_run_sttl_daily.sh ${month}01 ${curDay} ${prov} VOICE
    /app/mcb/incs/bin/qb_exe.sh qb_sttl_voice_monthly_zg ${month} ${prov} ${nowDt}
    /app/mcb/incs/bin/qb_exe.sh qb_sttl_voice_monthly_qd ${month} ${prov} ${nowDt}

sqlplus incsdba/Cmit_incs0@${db_service_nm} 1>&2 > /app/mcb/incs/DELETED/maiyp/log/sttlResult.${prov}  <<EOF
    set linesize 200
    select 'voiceSttlSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt >= ${month}01 and db_insr_dt <= ${curDay} and sttl_dt like '${month}%' and cdr_type = 1 ;
    select 'voiceProcessFileDt###'||sum(cdr_count) from incsdba.process_state_cdr_file t where cdr_file_nm like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\'  and stat = 'C' and cdr_file_type = 'Voice'  and  prov_cd = ${prov}; 
    select 'voiceSttlFileDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt >= ${month}01 and db_insr_dt <= ${curDay} and ori_file_name like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\' and trans_flag != '1'; 
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

leakVoNums=`wc -l /app/mcb/incs/DELETED/maiyp/log/ImsLeakFiles.${prov}`
imsDecodeFailNum=`ls /app/mcb/incs/nfs/data/abnormal/ims/${prov}/IBCF*_${month}*|wc -l`
echo "${hh}:${mm}:${ss} ${prov}省${month}月份结果如下：" >> /app/mcb/incs/DELETED/zengtf/log/compare.${prov}

echo "${hh}:${mm}:${ss} ${prov}省${month}月份Ims文件数${imsOriCount},当前数据库成功处理文件数${dfsImsNum},distinct文件数${leakVoNums}(include ims decode fail file nums:${imsDecodeFailNum}" >> /app/mcb/incs/DELETED/zengtf/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音处理记录表话单量(以文件名做日期):${voiceProcessFileDt}" >> /app/mcb/incs/DELETED/zengtf/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音分拣表话单量(以文件名做日期):${voiceSttlFileDt}" >> /app/mcb/incs/DELETED/zengtf/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音分拣表话单量(以账期日做日期)：${voiceSttlSttlDt}" >> /app/mcb/incs/DELETED/zengtf/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音日结算表话单量：${voiceDailySttlDt}" >> /app/mcb/incs/DELETED/zengtf/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音月结算表话单量(ZG)：${voiceMonthlyZgSttlDt}" >> /app/mcb/incs/DELETED/zengtf/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音月结算表话单量(QD)：${voiceMonthlyQdSttlDt}" >> /app/mcb/incs/DELETED/zengtf/log/compare.${prov}
fi
