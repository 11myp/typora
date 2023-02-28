[mcbadm@cmitcsdfs-a /app/mcb/incs/DELETED/wangying/shell]$ cat  getErrorSttlVo.sh
#!/usr/bin/bash
cat Voall.txt|while read aa
do
if [[ $aa == Vo_IBCF* ]];then
      prov=`echo $aa|awk -F'_' '{print $7}'`
else
      prov=`echo $aa|awk -F'_' '{print $4}'`
fi

/home/kingbase/server/bin/ksql  "host=10.253.87.224 port =54321 user=incsdba password=Cmit_incs0 dbname=incsm" > /app/mcb/incs/DELETED/wangying/dbsernm_${prov}.tmp <<EOF
     select db_host||'|'||db_service_name from mcbdba.db_config_mapping_prov where prov_cd ='${prov}';
EOF

db_service_nm=`grep incss /app/mcb/incs/DELETED/wangying/dbsernm_${prov}.tmp |awk -F'|' '{print $1}'|awk '{print $1}'`
db_name=`grep incss /app/mcb/incs/DELETED/wangying/dbsernm_${prov}.tmp |awk -F'|' '{print $2}'`



/home/kingbase/server/bin/ksql "host=${db_service_nm} port=54321 user=incsdba password=Cmit_incs0 dbname=${db_name}"  >> /app/mcb/incs/DELETED/wangying/Voerror.txt <<EOF
select '${aa}' file_nm from (select sum(cdr_count) cdr_cnt from incsdba.sttl_voice_${prov} t where sttl_dt >=20221130 and t.ori_file_name ='${aa}' ) a,
(select cdr_count cdr_cnt from "incsdba"."process_state_cdr_file" t where process_dt >= 20221130 and prov_cd=${prov} and t."cdr_file_type"='Voice'  and t."stat"='C' and t.cdr_file_nm ='${aa}') b 
where a.cdr_cnt <> b.cdr_cnt ;
EOF
done


#sql：查询某一天中，记录表话单量和sttl表话单量不一致的文件
select a.ori_file_name from 
(select ori_file_name,sum(cdr_count) cdr_cnt from incsdba.sttl_voice_210  where sttl_dt >=20221130 group by ori_file_name) a 
inner join
(select cdr_file_nm,cdr_count from "incsdba"."process_state_cdr_file" t where process_dt >= 20221130 and prov_cd=210 and t."cdr_file_type"='Voice'  and t."stat"='C') b 
on a.cdr_cnt <> b.cdr_count


select  a.ori_file_name from (select ori_file_name,sum(cdr_count) cdr_cnt from incsdba.sttl_voice_220 t where sttl_dt >=20221130 group by  ori_file_name ) a,
(select cdr_file_nm,cdr_count from "incsdba"."process_state_cdr_file" t where process_dt =20230101 and prov_cd=220 and t."cdr_file_type"='Voice'  and t."stat"='C' ) b 
where a.cdr_cnt <> b.cdr_cnt ;

select 'Vo_IBCF20_H_090220_20230111235354_01193665_210_20230112_00000005' cdr_file_nm (select sum(cdr_count) cdr_cnt from incsdba.sttl_voice_210 t where sttl_dt >=20221130 and t.ori_file_name ='Vo_IBCF20_H_090220_20230111235354_01193665_210_20230112_00000005') a,
(select cdr_count cdr_cnt from "incsdba"."process_state_cdr_file" t where process_dt >= 20221130 and prov_cd=210 and t."cdr_file_type"='Voice'  and t."stat"='C' and t.cdr_file_nm ='Vo_IBCF20_H_090220_20230111235354_01193665_210_20230112_00000005') b
where a.cdr_cnt <> b.cdr_cnt ;
Vo_IBCF20_H_090220_20230111235354_01193665_210_20230112_00000005




deleteErrorSttl.sh
#!/usr/bin/bash
cat first.txt|while read aa
do
if [[ $aa == Vo_IBCF* ]];then
      prov=`echo $aa|awk -F'_' '{print $7}'`
else
      prov=`echo $aa|awk -F'_' '{print $4}'`
fi

/home/kingbase/server/bin/ksql  "host=10.253.87.224 port =54321 user=incsdba password=Cmit_incs0 dbname=incsm" > /app/mcb/incs/DELETED/wangying/dbsernm_${prov}.tmp1 <<EOF
     select db_host||'|'||db_service_name from mcbdba.db_config_mapping_prov where prov_cd ='${prov}';
EOF

db_service_nm=`grep incss /app/mcb/incs/DELETED/wangying/dbsernm_${prov}.tmp1 |awk -F'|' '{print $1}'|awk '{print $1}'`
db_name=`grep incss /app/mcb/incs/DELETED/wangying/dbsernm_${prov}.tmp1 |awk -F'|' '{print $2}'`



/home/kingbase/server/bin/ksql "host=${db_service_nm} port=54321 user=incsdba password=Cmit_incs0 dbname=${db_name}"  >> /app/mcb/incs/DELETED/wangying/DeleteVoSttl.txt <<EOF
delete from incsdba.sttl_voice_${prov} t where sttl_dt >= 20221201 and db_insr_dt <= 20221224 and t.ori_file_name ='${aa}';
commit;
EOF
done