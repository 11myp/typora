#!/bin/bash
 #************************************************#
 # Sttl_Ims_KB.sh                                 #
 # written by MaiYEPING                           #
 # Jan 04, 2023                                   #
 #功能：IMS语音话单每月结算预出账                    #
 #1、文件平衡性对比：传输日志与数据库 
 #2、日月结算存储过程运行                           #
 #3、结算表与记录表话单量平衡性对比                  #
 #Uesge:Sttl_Ims_KB.sh  ${prov}  ${month}         #
 #检验结果：查看compare.${prov}文件中，月份语音处理记录表话单量(以文件名做日期)与月份语音分拣表话单量(以文件名做日期)一致；
 #月份语音分拣表话单量(以账期日做日期)、月份语音日结算表话单量、月份语音月结算表话单量(ZG)、月份语音月结算表话单量(QD)四者话单量一致。
 #若话单量不一致，则需要排查不一致的原因，解决之后再重跑日结算和月结算。
 #************************************************#

if [ $# -ne 2 ];then
  echo"Usage:Sttl_Ims_KB_New.sh prov month"
  exit -1
fi

prov=$1
month=$2
year=`echo ${month} |cut -c 1-4`
premonLastD=`/app/mcb/incs/bin/preday 1 date ${month}01`
start_date="${month}01"
nowDt=`date +"%Y%m%d"`

firsttime1="${month}10"
secondtime1="${month}11"
secondtime2="${month}20"
thirdtime1="${month}21"

#判断目录
if [ ! -d /app/mcb/incs/nfs/data/kb_ora/sttl/ ];then
   mkdir -p /app/mcb/incs/nfs/data/kb_ora/sttl/
fi

if [ ! -d /app/mcb/incs/nfs/data/kb_ora/sttl/log/ ];then
   mkdir -p /app/mcb/incs/nfs/data/kb_ora/sttl/log/
fi

CompareFile=/app/mcb/incs/nfs/data/kb_ora/sttl/log/compare.${prov}
>${CompareFile}

mp_schema=incsdba
passwdtmp=`/app/mcb/incs/bin/PwdClient getdbpwd incss1 ${mp_schema} 2>/dev/null <<EOF
10.253.116.181:7088
EOF`
dbpasswd=`echo ${passwdtmp} |awk -F':' '{print $NF}'`

#判断主机是否安装ksql
KSQL=`whereis ksql|awk -F':' '{print $NF}'`
if [ ! ${KSQL} ];then
  echo "ksql is not installed!please check"  >>  ${CompareFile}
  exit -1
fi

echo "" > /app/mcb/incs/nfs/data/kb_ora/sttl/log/ftpImsListTmp.${prov}
while [ ${start_date} -le ${nowDt} ];
do
  grep -a IBCF /app/mcb/incs/var/log/ftpTrans*_Recv_${prov}*ims.log.${start_date}* | grep -oE "\bIBCF.*.dat\b"|grep -v "#file_name" |grep _${month}|sort|uniq >> /app/mcb/incs/nfs/data/kb_ora/sttl/log/ftpImsListTmp.${prov}
  start_date=`preday -1 date ${start_date}`
done
grep IBCF /app/mcb/incs/nfs/data/kb_ora/sttl/log/ftpImsListTmp.${prov} |sort |uniq > /app/mcb/incs/nfs/data/kb_ora/sttl/log/ftpImsList.${prov}

imsOriCount=`cat /app/mcb/incs/nfs/data/kb_ora/sttl/log/ftpImsList.${prov}|wc -l`

ssh cmitcsext-a "sh /app/mcb/incs/nfs/data/kb_ora/sttl/FindImsAB.sh ${prov} ${month};exit"
scp cmitcsext-a:/app/mcb/incs/nfs/data/kb_ora/sttl/log/ImsDeFail.${prov} /app/mcb/incs/nfs/data/kb_ora/sttl/log/
if [ -f /app/mcb/incs/nfs/data/kb_ora/sttl/log/ImsDeFail.${prov} ];then
  ImsDeFailNum=`cat /app/mcb/incs/nfs/data/kb_ora/sttl/log/ImsDeFail.${prov} |wc -l`
else
  echo "获取不到${prov}省IMS解码失败文件" >> ${CompareFile}
fi
hh=`date +%H`
mm=`date +%M`
ss=`date +%S`
echo "${hh}:${mm}:${ss} ${prov}省IMS原文件数量是:${imsOriCount}" >> ${CompareFile}
echo "${hh}:${mm}:${ss} ${prov}省解码faied IMS文件数量是：${ImsDeFailNum}" >> ${CompareFile}


db_config_prov=`${KSQL} "host=10.253.87.224 port=54321 user=${mp_schema} password=${dbpasswd} dbname=incsm" -t 2>/dev/null  <<EOF
select '#'||prov_cd||'|'||db_host||'|'||db_service_name||'#' from mcbdba.db_config_mapping_prov where prov_cd = ${prov};
EOF`

#若匹配不到库名和IP，则退出
if [ ${db_config_prov} ];then
  db_host=`echo ${db_config_prov} |awk -F'#' '{print $2}'|awk -F'|' '{print $2}'`
  db_name=`echo ${db_config_prov} |awk -F'#' '{print $2}'|awk -F'|' '{print $3}'`
  echo ${db_host} ${db_name}
else
  echo "Failed!can not get the db_server_nm!"
  exit -1
fi

${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}" > /app/mcb/incs/nfs/data/kb_ora/sttl/log/ImsCleanTmp.${prov} <<EOF
  select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\'  and stat != 'C' and prov_cd = ${prov} and process_dt between ${month}01 and ${nowDt};
EOF

cat /app/mcb/incs/nfs/data/kb_ora/sttl/log/ImsCleanTmp.${prov}|grep IBCF > /app/mcb/incs/nfs/data/kb_ora/sttl/log/cleanFiles.${prov}
CFileNum=`cat /app/mcb/incs/nfs/data/kb_ora/sttl/log/cleanFiles.${prov} |wc -l`

if  [[ ${CFileNum} -eq 0 ]];then
  echo "无失败文件"
#若存在失败文件，则调用清理脚本CleanFilesProv.sh
elif [[ ${CFileNum} -lt 100 ]] && [[ ${CFileNum} -ne 0 ]];then

  /app/mcb/incs/nfs/data/kb_ora/sttl/CleanFilesProv.sh ${prov}
  cat /app/mcb/incs/nfs/data/kb_ora/sttl/log/cleanFiles.${prov} |while read fileNm
  do
      prov=`echo $fileNm|awk -F'_' '{print $7}'`
      dt=`echo $fileNm|awk -F'_' '{print $8}'`
      #如果获取不到省份和日期，则跳出循环接着遍历下一个文件
      if [[ -z "${prov}" || -z "${dt}" ]];then
         echo ${fileNm} "is error!" >>  ${CompareFile}
         continue
      else
         ssh cmitcsext-a"cp /app/mcb/incs/nfs/arch/dirdetect/voice/${prov}/${dt}/$fileNm /app/mcb/incs/nfs/data/dirdetect/voice/${prov}"
      fi
  done
  #休眠10分钟，让失败文件重处理入库
  sleep 600
  #判断重处理文件是否正常清理
  sh Fdiff_Sttl_Proc_Filenm.sh /app/mcb/incs/nfs/data/kb_ora/sttl/log/cleanFiles.${prov} 
  if [ $? -eq -1 ];then
    echo "clearup file is failed!"  >> ${CompareFile}
    exit -1
  fi
else
  echo ${prov}"省失败文件列表获取失败或失败文件过多" >>  ${CompareFile}
  exit -1
fi

${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}" > /app/mcb/incs/nfs/data/kb_ora/sttl/log/dbImsFilesTmp.${prov} <<EOF
select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\' and stat = 'C' and prov_cd = ${prov} and process_dt between ${month}01 and ${nowDt};
EOF

grep IBCF /app/mcb/incs/nfs/data/kb_ora/sttl/log/dbImsFilesTmp.${prov}|sort|uniq > /app/mcb/incs/nfs/data/kb_ora/sttl/log/dbImsFiles.${prov}
curDbVoNums=`cat /app/mcb/incs/nfs/data/kb_ora/sttl/log/dbImsFiles.${prov} |wc -l`

awk -F'_'  -v OFS='_' '{print $2,$3,$4,$5,$6".dat"}' /app/mcb/incs/nfs/data/kb_ora/sttl/log/dbImsFiles.${prov} |sort|uniq> /app/mcb/incs/nfs/data/kb_ora/sttl/log/dbIms.${prov}
comm -13 /app/mcb/incs/nfs/data/kb_ora/sttl/log/dbIms.${prov} /app/mcb/incs/nfs/data/kb_ora/sttl/log/ftpImsList.${prov} > /app/mcb/incs/nfs/data/kb_ora/sttl/log/LeakDbFtp.${prov}
DbFtpLeakNum=`cat /app/mcb/incs/nfs/data/kb_ora/sttl/log/LeakDbFtp.${prov} |wc -l`

hh=`date +%H`
mm=`date +%M`
ss=`date +%S`
echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音文件数${dfsImsNum},当前数据库成功处理文件数${curDbVoNums}" >> ${CompareFile}
curday=`preday 0 date`
if [[ ${DbFtpLeakNum} -eq 0  ]];then
  curDay=`preday 0 date`
  echo "正在跑结算数据" >> ${CompareFile}
  nexmonth=`date -d "-1 months ago ${month}01" +"%Y%m%d"`
  sttlpreday=`preday 2 date ${nexmonth}`
  #运行出账日期前两天的日结算 eg:12.01出账即跑11.29-12.01三天的日结算
  /app/mcb/incs/nfs/data/kb_ora/sttl/batch_run_sttl_daily.sh ${sttlpreday} ${curday} ${prov} VOICE
  /app/mcb/incs/bin/qb_exe_kingbase.sh qb_sttl_voice_monthly_zg_kingbase ${month} ${prov}
  /app/mcb/incs/bin/qb_exe_kingbase.sh qb_sttl_voice_monthly_qd_kingbase ${month} ${prov}
  
  #查询语句需要拆分,一次性查询一个月的话单量较久并且容易超时，会话断开，没有结果返回。
  ${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}" > /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResult.${prov} <<EOF
    select 'voiceSttlSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt between ${premonLastD} and ${firsttime1} and sttl_dt like '${month}%' and ori_file_name like 'Vo_IBCF%';
EOF

  ${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}" >> /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResult.${prov} <<EOF
    select 'voiceSttlSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt between ${secondtime1} and ${secondtime2} and sttl_dt like '${month}%' and ori_file_name like 'Vo_IBCF%';
EOF

  ${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}" >> /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResult.${prov} <<EOF
    select 'voiceSttlSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt between ${thirdtime1} and ${curDay} and sttl_dt like '${month}%' and ori_file_name like 'Vo_IBCF%';
EOF

  ${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}" >> /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResult.${prov} <<EOF  
   select 'voiceProcessFileDt###'||sum(cdr_count) from incsdba.process_state_cdr_file t where cdr_file_nm like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\'  and stat = 'C' and cdr_file_type = 'Voice'  and  prov_cd = ${prov}; 
EOF

  ${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}" >> /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResult.${prov} <<EOF
     select 'voiceSttlFileDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt between ${premonLastD} and ${firsttime1} and ori_file_name like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\' and trans_flag != '1'; 
EOF

  ${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}" >> /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResult.${prov} <<EOF
     select 'voiceSttlFileDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt between ${secondtime1} and ${secondtime2} and ori_file_name like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\' and trans_flag != '1'; 
EOF

  ${KSQL}  "host=${db_host} port =54321 user=incsdba password=${dbpasswd} dbname=${db_name}" >> /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResult.${prov} <<EOF
     select 'voiceSttlFileDt###'||sum(cdr_count) from incsdba.sttl_voice_${prov}  where db_insr_dt between ${thirdtime1} and ${curDay} and ori_file_name like 'Vo\_IBCF%\_${month}%\_%${prov}\_20%' escape '\' and trans_flag != '1'; 
EOF

  ${KSQL}  "host=10.253.87.224 port =54321 user=incsdba password=${dbpasswd} dbname=incsm"  1>&2 > /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResultM.${prov} <<EOF
    select 'voiceDailySttlDt###'||sum(cdr_count) from incsdba.sttl_voice_daily t where  t.sttl_dt like '${month}%' and prov_cd = ${prov} and cdr_type = 1 ;
    select 'voiceMonthlyZgSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_monthly_zg t where sttl_month = ${month} and prov_cd = ${prov} and cdr_type = 1; 
    select 'voiceMonthlyQdSttlDt###'||sum(cdr_count) from incsdba.sttl_voice_monthly_qd t where sttl_month = ${month} and prov_cd = ${prov} and cdr_type = 1;
EOF
  voiceProcessFileDt=`grep "voiceProcessFileDt###" /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
  #voiceSttlFileDt=`grep "voiceSttlFileDt###" /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
  voiceSttlFileDt=`grep "voiceSttlFileDt" /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResul*${prov} |awk -F'#' 'BEGIN{sum=0}{sum+=$NF}END{print sum}'`
  #voiceSttlSttlDt=`grep "voiceSttlSttlDt###" /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
  voiceSttlSttlDt=`grep "voiceSttlSttlDt" /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResul*${prov} |awk -F'#' 'BEGIN{sum=0}{sum+=$NF}END{print sum}'`
  voiceDailySttlDt=`grep "voiceDailySttlDt###" /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
  voiceMonthlyZgSttlDt=`grep "voiceMonthlyZgSttlDt###" /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResul*${prov}|awk -F'###' '{print $2}'`
  voiceMonthlyQdSttlDt=`grep "voiceMonthlyQdSttlDt###" /app/mcb/incs/nfs/data/kb_ora/sttl/log/sttlResul*${prov}|awk -F'###' '{print $2}'`

  echo "${hh}:${mm}:${ss} ${prov}省${month}月份结果如下：" >> ${CompareFile}
  echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音处理记录表话单量(以文件名做日期):${voiceProcessFileDt}" >> ${CompareFile}
  echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音分拣表话单量(以文件名做日期):${voiceSttlFileDt}" >> ${CompareFile}
  echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音分拣表话单量(以账期日做日期)：${voiceSttlSttlDt}" >> ${CompareFile}
  echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音日结算表话单量：${voiceDailySttlDt}" >> ${CompareFile}
  echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音月结算表话单量(ZG)：${voiceMonthlyZgSttlDt}" >> ${CompareFile}
  echo "${hh}:${mm}:${ss} ${prov}省${month}月份语音月结算表话单量(QD)：${voiceMonthlyQdSttlDt}" >> ${CompareFile}

  echo ${prov}"省" ${month}":"  >>  /app/mcb/incs/nfs/data/kb_ora/sttl/log/compare.log
  if [ ${imsOriCount} -ne  ${curDbVoNums} ];then
    echo "处理文件数不平衡"    >>  /app/mcb/incs/nfs/data/kb_ora/sttl/log/compare.log
  fi

  if [ ${voiceProcessFileDt} -ne ${voiceSttlFileDt} ];then
    echo "处理记录表话单量(以文件名做日期)与分拣表话单量(以文件名做日期)不一致" >> /app/mcb/incs/nfs/data/kb_ora/sttl/log/compare.log
  fi

  if [ ${voiceSttlSttlDt} -ne ${voiceDailySttlDt} ]||[ ${voiceDailySttlDt} -ne ${voiceMonthlyZgSttlDt} ]|| [ ${voiceMonthlyZgSttlDt} -ne ${voiceSttlSttlDt} ] ;then
    echo "结算话单量不一致" >>  /app/mcb/incs/nfs/data/kb_ora/sttl/log/compare.log
  fi

  echo "END"  >>  /app/mcb/incs/nfs/data/kb_ora/sttl/log/compare.log
fi