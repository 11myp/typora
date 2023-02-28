#!/bin/bash
#workdir：工作目录，可修改
workdir='/app/mcb/incs/DELETED/maiyp/tmp/cptar'
prov=$1
cd ${workdir1}
#comm -13 /app/mcb/incs/DELETED/zengtf/log/dfsVoList.${prov} /app/mcb/incs/DELETED/zengtf/log/pcsVoList.${prov} > lack_${prov}.txt
ssh mcbpcs${prov} mkdir /opt/mcb/pcs/DELETED/maiyp/
scp ${workdir}/lack_${prov}.txt mcbpcs${prov}:/opt/mcb/pcs/DELETED/maiyp/
scp /app/mcb/incs/DELETED/maiyp/shell/findori.sh mcbpcs${prov}:/opt/mcb/pcs/DELETED/maiyp/

#pcs
ssh -n mcbpcs${prov} "nohup /opt/mcb/pcs/DELETED/maiyp/findori.sh ${prov} &"
#findor.sh is done
sleep 360
 
scp mcbpcs${prov}:/opt/mcb/pcs/DELETED/maiyp/ori_${prov}.txt  ${workdir1}/
scp mcbpcs${prov}:/opt/mcb/pcs/DELETED/maiyp/oriDE_${prov}.txt ${workdir1}/

cat ${workdir}/lack_${prov}.txt |awk -F'_' '{print $5}'| sort| uniq > ${workdir}/logdate.txt

for line in `cat ${workdir}/logdate.txt`
do
       scp mcbpcs${prov}:/opt/mcb/pcs/var/log/gzip_incs_upload_file.log.${line} /app/mcb/incs/DELETED/maiyp/tmp/
done

echo "" > ${workdir}/gsmtarTmp${prov}
#dt,need to be modified

for line in `cat /app/mcb/incs/DELETED/maiyp/tmp/ori_${prov}.txt`
  do
    grep -A1000 $line /app/mcb/incs/DELETED/maiyp/tmp/gzip_incs_upload_file.log.* |grep tar|head -1|awk  '{print $2}'|awk -F' success' '{print $1}' >> ${workdir}/gsmtarTmp${prov}
  done
fi

sort /app/mcb/incs/DELETED/maiyp/tmp/gsmtarTmp${prov}|uniq  > /app/mcb/incs/DELETED/maiyp/tmp/gsmtar.${prov} 
cat /app/mcb/incs/DELETED/maiyp/tmp/gsmtar.${prov} |xargs -i cp /app/mcb/incs/nfs/arch/gzip_upload/${prov}/{} /app/mcb/incs/DELETED/maiyp/tmp/

cd ${workdir2} 
ls *.tar | xargs -i tar xf {}
cat /app/mcb/incs/DELETED/maiyp/tmp/ori_${prov}.txt | xargs -i gunzip {}.gz

while read line
do
        source=`echo $line |awk  '{print $1}'`
        Vofile=`echo $line |awk  '{print $2}'`
        mv /app/mcb/incs/DELETED/maiyp/tmp/${source} /app/mcb/incs/DELETED/maiyp/tmp/${Vofile}
done < /app/mcb/incs/DELETED/maiyp/tmp/oriDE_${prov}.txt

scp /app/mcb/incs/DELETED/maiyp/tmp/Vo* mcbpcs${prov}:/opt/mcb/pcs/data/incs/upload/gsm/