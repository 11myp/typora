#!/bin/bash
if [ $# -ne 2 ];then
  echo"Usage:incsLeakFiles.sh prov month"
  exit -1
fi

prov=$1
month=$2

>/app/mcb/incs/DELETED/maiyp/log/compare.${prov}

#Ims总的文件数量
grep "IBCF" /app/mcb/incs/var/log/ftpTransfer_Recv_${prov}_ims_incs.log.*|grep "successfully"|grep _${month}|awk -F'[' '{print $2}'|awk -F']' '{print $1}'|sort|uniq|grep -v "^$" >/app/mcb/incs/DELETED/maiyp/log/ftpImsList.${prov}
imsOriCount=`wc -l /app/mcb/incs/DELETED/maiyp/log/ftpImsList.${prov}`
#解码失败的文件数量
ls  /app/mcb/incs/nfs/data/abnormal/ims/${prov}/*_202105* |awk -F'/' '{print $10}' > /app/mcb/incs/DELETED/maiyp/log/ImsDeFail.${prov}
ImsDeFailNum=`ls  /app/mcb/incs/nfs/data/abnormal/ims/${prov}/*_202105* |wc -l`

#解码成功的文件数
comm -13 /app/mcb/incs/DELETED/maiyp/log/ImsDeFail.${prov} /app/mcb/incs/DELETED/maiyp/log/ftpImsList.${prov} > /app/mcb/incs/DELETED/maiyp/log/ImsDecSUCC.${prov}
ImsDecSUCC=`wc -l /app/mcb/incs/DELETED/maiyp/log/ImsDecSUCC.${prov}`
#ssh -n 10.253.23.123  "grep "/app/mcb/incs/nfs/data/dirdetect/voice/${prov}/" /app/mcb/incs/var/log/FileDecode* |grep _202105  " > /app/mcb/incs/DELETED/maiyp/log/ImsDecSUCCTmp.${porv}
#awk -F'/' '{print $24}' /app/mcb/incs/DELETED/maiyp/log/ImsDecSUCCTmp.${porv} |awk '{print $1}' > /app/mcb/incs/DELETED/maiyp/log/ImsDecSUCC.${porv}
#ImsDecSUCCNum=`wc -l /app/mcb/incs/DELETED/maiyp/log/ImsDecSUCC.${porv}`
#备份文件下的文件数
find /app/mcb/incs/nfs/arch/dirdetect/voice/${prov}/ -name "Vo_IBCF*_${month}*_*${prov}_20*"  > /app/mcb/incs/DELETED/maiyp/log/dfsImsListTmp.${prov}
cat /app/mcb/incs/DELETED/maiyp/log/dfsImsListTmp.${prov}|awk -F'Vo_' '{print $2}'|awk -F'_' -v OFS='_' '{print $1,$2,$3,$4,$5".dat"}'|sort|uniq > /app/mcb/incs/DELETED/maiyp/log/dfsImsList.${prov}
dfsImsNum=`cat /app/mcb/incs/DELETED/maiyp/log/dfsImsList.${prov}|wc -l`

#未处理的文件数量
#comm -13 /app/mcb/incs/DELETED/maiyp/log/dfsImsList.${prov} /app/mcb/incs/DELETED/maiyp/log/ImsDecSUCC.${prov} > 

hh=`date +%H`
mm=`date +%M`
ss=`date +%S`

echo "${hh}:${mm}:${ss} ${prov}原始文件数量是：${imsOriCount}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}解码成功文件数量是：${ImsDecSUCC}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
echo "${hh}:${mm}:${ss} ${prov}省文件服务器备份目录下语音数量是：${dfsImsNum}" >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}

let ImsLeakNums=${ImsDecSUCC}-${dfsImsNum}
ImsPre=`awk 'BEGIN{printf"%0.4f","'"${dfsImsNum}"'"/"'"${ImsDecSUCC}"'"}'`
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

CleanFileNum=`wc -l /app/mcb/incs/DELETED/maiyp/log/cleanFiles.${prov}`

if [[ $CleanFileNum -eq 0 ]];then
  echo "${prov}省无失败文件"  >> /app/mcb/incs/DELETED/maiyp/log/compare.${prov}
fi


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

