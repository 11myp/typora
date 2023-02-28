#!/usr/bin/bash
prov=$1
Old_Pcs=$2
New_Pcs_Ip=$3


if [ $# != 3 ];then
   echo "Error!Usage:./Unix_To_Pcs.sh prov mcbpcsxxx 10.xxx.xxx.xxx"
   exit -1
fi

scp ${Old_Pcs}:/opt/mcb/pcs/bin/gzip_incs_upload_file.sh   /app/mcb/incs/DELETED/maiyp/newpcswork/
scp ${Old_Pcs}:/opt/mcb/pcs/bin/incsZipTool.sh             /app/mcb/incs/DELETED/maiyp/newpcswork/
scp ${Old_Pcs}:/opt/mcb/pcs/bin/incs_cdr_file_rename.sh    /app/mcb/incs/DELETED/maiyp/newpcswork/
scp ${Old_Pcs}:/opt/mcb/pcs/bin/incs_mv_rename_list.sh     /app/mcb/incs/DELETED/maiyp/newpcswork/
scp 10.250.58.12:/opt/mcb/pcs/bin/FileDecode    /app/mcb/incs/DELETED/maiyp/newpcswork/

scp ${Old_Pcs}:/opt/mcb/pcs/conf/incs_cdr_file_ren*conf /app/mcb/incs/DELETED/maiyp/newpcswork/
scp ${Old_Pcs}:/opt/mcb/pcs/conf/gzip_incs_upload_file.conf /app/mcb/incs/DELETED/maiyp/newpcswork/
scp ${Old_Pcs}:/opt/mcb/pcs/conf/incsZipTool.conf /app/mcb/incs/DELETED/maiyp/newpcswork/
scp ${Old_Pcs}:/opt/mcb/pcs/conf/FileDecode*conf /app/mcb/incs/DELETED/maiyp/newpcswork/
scp ${Old_Pcs}:/opt/mcb/pcs/conf/MscCode*conf /app/mcb/incs/DELETED/maiyp/newpcswork/


scp /app/mcb/incs/DELETED/maiyp/newpcswork/*sh ${New_Pcs_Ip}:/opt/mcb/pcs/bin/
scp /app/mcb/incs/DELETED/maiyp/newpcswork/FileDecode ${New_Pcs_Ip}:/opt/mcb/pcs/bin/
scp /app/mcb/incs/DELETED/maiyp/newpcswork/*conf ${New_Pcs_Ip}:/opt/mcb/pcs/conf/


ssh ${New_Pcs_Ip} "mkdir -p /opt/mcb/pcs/var/tmp"
grep "/opt/mcb/pcs" *conf|grep -v list|awk -F'=' '{print "mkdir -p",$2}'|awk '{print "ssh ${New_Pcs_Ip} \""$0"\""}'|sh
grep list *conf|awk -F'=' '{print $2}'|awk '{print "ssh ${New_Pcs_Ip} \"touch",$0"\""}'|sh

ssh ${New_Pcs_Ip} "mkdir -p /opt/mcb/pcs/incstmp"

date=`preday 1 date`
find /app/mcb/incs/nfs/arch/dirdetect/voice/${prov}/${date}/ -type f|grep -v IBCF|awk -F'/' '{print substr($11,1,10)}'|sort|uniq|while read aa
do
find /app/mcb/incs/nfs/arch/dirdetect/voice/${prov}/${date}/ -type f -name "${aa}*"|head -20|awk '{print "cp",$0,"/app/mcb/incs/DELETED/maiyp/newpcswork/"}'|sh
done

find /app/mcb/incs/nfs/arch/dirdetect/sms/${prov} -type f -name "*${date}*"|head -20|awk '{print "cp",$0,"/app/mcb/incs/DELETED/maiyp/newpcswork/"}'|sh

scp /app/mcb/incs/DELETED/maiyp/newpcswork/*DECODE ${New_Pcs_Ip}:/opt/mcb/pcs/incstmp


cp /app/mcb/incs/nfs/arch/gzip_upload/${prov}/*${date}*tar /app/mcb/incs/DELETED/maiyp/newpcswork/

ls /app/mcb/incs/DELETED/maiyp/newpcswork/*tar|while read aa
do
tar -xvf ${aa} -C /app/mcb/incs/DELETED/maiyp/newpcswork/
done


scp ${Old_Pcs}:/opt/mcb/pcs/var/log/incs_cdr_file_renam*${date} /app/mcb/incs/DELETED/maiyp/newpcswork/

ls /app/mcb/incs/DELETED/maiyp/newpcswork/*DECODE|while read aa
do
decodeNm=`echo ${aa}|awk -F'newpcswork/' '{print $2}'|awk -F'_DECODE' '{print $1}'`
oriNm=`grep ${decodeNm} /app/mcb/incs/DELETED/maiyp/newpcswork/incs_cdr_file_renam*${date}|awk -F'[' '{print $2}'|awk '{print $1}'`
gunzip /app/mcb/incs/DELETED/maiyp/newpcswork/${oriNm}*
cp /app/mcb/incs/DELETED/maiyp/newpcswork/${oriNm} /app/mcb/incs/DELETED/maiyp/newpcswork/${decodeNm}
scp /app/mcb/incs/DELETED/maiyp/newpcswork/${decodeNm} ${New_Pcs_Ip}:/opt/mcb/pcs/incstmp
done


rm -rf /app/mcb/incs/DELETED/maiyp/newpcswork/*