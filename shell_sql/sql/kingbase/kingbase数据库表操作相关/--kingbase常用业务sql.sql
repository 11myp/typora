--公参表
MCBDBA.BDC_SYNC_FILE

--kingbase常用业务sql
select * from incsdba.process_state_cdr_file@incss4

--统计查重错误的文件数量
select process_dt,count(cdr_file_nm) from incsdba.process_state_cdr_file@incss1  group by process_dt

--统计文件下载失败
select process_dt,count(cdr_file_nm) from incsdba.process_state_cdr_file@incss1  where ret_info='文件下载失败' group by process_dt 



--统计查重失败
select process_dt,count(cdr_file_nm) from incsdba.process_state_cdr_file@incss1  where stat='B' group by process_dt


--修改字段长度
alter table incsdba.sttl_voice_991 modify  calling_area_cd character varying(12)

----------------------日巡检-------------------------------------
--每天处理数量
SELECT 'incss1'||'|'||count(*)  from incsdba.process_state_cdr_file@incss1 where process_dt = 20220119 and cdr_file_type='Voice' union
SELECT 'incss2'||'|'||count(*)  from incsdba.process_state_cdr_file@incss2 where process_dt = 20220119 and cdr_file_type='Voice' union
SELECT 'incss3'||'|'||count(*)  from incsdba.process_state_cdr_file@incss3 where process_dt = 20220119 and cdr_file_type='Voice' union
SELECT 'incss4'||'|'||count(*)  from incsdba.process_state_cdr_file@incss4 where process_dt = 20220119 and cdr_file_type='Voice'

--处理状态
select stat,count(*) from incsdba.process_state_cdr_file@incss1 where process_dt = ${preday} group by stat union
select stat,count(*) from incsdba.process_state_cdr_file@incss2 where process_dt = ${preday} group by stat union
select stat,count(*) from incsdba.process_state_cdr_file@incss3 where process_dt = ${preday} group by stat union
select stat,count(*) from incsdba.process_state_cdr_file@incss4 where process_dt = ${preday} group by stat 


--错误的数量
select prov_cd,count(cdr_file_nm) from incsdba.process_state_cdr_file@incss1 where process_dt = 20220119 and stat!='C' and cdr_file_type='Voice' group by prov_cd
select prov_cd,count(cdr_file_nm) from incsdba.process_state_cdr_file@incss2 where process_dt = 20220119 and stat!='C' and cdr_file_type='Voice' group by prov_cd
select prov_cd,count(cdr_file_nm) from incsdba.process_state_cdr_file@incss3 where process_dt = 20220119 and stat!='C' and cdr_file_type='Voice' group by prov_cd
select prov_cd,count(cdr_file_nm) from incsdba.process_state_cdr_file@incss4 where process_dt = 20220119 and stat!='C' and cdr_file_type='Voice' group by prov_cd

--文件下载失败的
select count(*) from incsdba.process_state_cdr_file@incss1 where process_dt = ${preday}  and ret_cod='F310' union
select count(*) from incsdba.process_state_cdr_file@incss2 where process_dt = ${preday}  and ret_cod='F310' union
select count(*) from incsdba.process_state_cdr_file@incss3 where process_dt = ${preday}  and ret_cod='F310' union
select count(*) from incsdba.process_state_cdr_file@incss4 where process_dt = ${preday}  and ret_cod='F310' 

select count(*) from incsdba.process_state_cdr_file where process_dt = 20220119 and stat='C' and cdr_file_type='Voice' and prov_cd =280


--2022-01-19
select * from incsdba.cdr_voice_220 where db_insr_dt = 20220118

select * from incsdba.process_state_cdr_file where process_dt = 20220119   and ret_info = '文件下载失败'


select * from incsdba.process_state_cdr_file@incss4 where ret_code='F310' order by process_dt desc


--删除B文件分拣审计表中不需要下发的话单
delete from incsdba.PRE_MERGE_FILE_AUDIT where og_file_name ='tbf_later' and db_insr_dt < 20220413

select ic_prov_cd,count(ori_file_name) from incsdba.PRE_MERGE_FILE_AUDIT  where og_file_name ='tbf_later' and db_insr_dt < xxxx
--select * from incsdba.PRE_MERGE_FILE_AUDIT where og_file_name ='tbf_later' and db_insr_dt < 20220418


 select cdr_file_nm from incsdba.process_state_cdr_file where (cdr_file_nm like  'Vo%_${process_dt}_%DECODE' or cdr_file_nm like  'Vo_IBCF%_${process_dt}%_${prov}_${month}%') and stat='C' and prov_cd = ${prov} and process_dt in (${process_dt},${next_dt}) and cdr_file_type='Voice';


--状态表（incsm）
B文件:og_proc_state
WJ短信处理状态表：cdr_sms_proc_state   
WJ语音：cdr_voice_proc_state
WJ彩信：cdr_rmm_proc_state

 一级经分打包状态表：BIGDATA_GZ_STATE

语音错单处理状态表：err_voice_proc_state 

短信错单处理状态表：err_sms_proc_state

彩信错单处理状态表：err_rmm_proc_state

监控文件状态表：MONITOR_STATE_FILE


--查询话单量   彩信
select sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss1 where process_dt between 20220901 and 20221008 and cdr_file_type ='MMS' and cdr_file_nm like 'RMM202209%' 
union
select sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss2 where process_dt between 20220901 and 20221008 and cdr_file_type ='MMS' and cdr_file_nm like 'RMM202209%' 
union
select sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss3 where process_dt between 20220901 and 20221008 and cdr_file_type ='MMS' and cdr_file_nm like 'RMM202209%' 
union
select sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss4 where process_dt between 20220901 and 20221008 and cdr_file_type ='MMS' and cdr_file_nm like 'RMM202209%' 
union
select sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss5 where process_dt between 20220901 and 20221008 and cdr_file_type ='MMS' and cdr_file_nm like 'RMM202209%' 
union
select sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss6 where process_dt between 20220901 and 20221008 and cdr_file_type ='MMS' and cdr_file_nm like 'RMM202209%' 

[mcbadm@cmitcsncs-1 /app/mcb/incs/DELETED/zengtf/log]$ grep "202209月份彩信处理记录表话单量" compare.* |awk -F':' 'BEGIN{sum=0}{sum+=$NF}END{print sum}'
6088186
--查询话单量  短信

[mcbadm@cmitcsncs-1 /app/mcb/incs/DELETED/zengtf/log]$ grep "202209月份短信处理记录表话单量" compare.* |awk -F':' 'BEGIN{sum=0}{sum+=$NF}END{print sum}'
1291022290
--查询话单量 话音
[mcbadm@cmitcsncs-1 /app/mcb/incs/DELETED/zengtf/log]$ grep "202209月份语音处理记录表话单量" compare.* |awk -F':' 'BEGIN{sum=0}{sum+=$NF}END{print sum}'
10168703771

[mcbadm@cmitcsncs-1 /app/mcb/incs/DELETED/maiyp/log]$ grep "202209月份语音处理记录表话单量" compare.* |awk -F':' 'BEGIN{sum=0}{sum+=$NF}END{print sum}'
22898526117

--九月份平均每秒需处理话音话单13257.84条


34,364,340,364


--汇总程序，icfile
select  * from incsdba.ic_file_check_audit
select  * from incsdba.ic_file_check_audit where proc_dt = 20221205 and prov= 250

--重命名表
select * from incsdba.ic_file_rename_audit
select * from incsdba.ic_file_rename_audit where proc_dt = 20221205 and prov_cd =250 and rename_file_nm like '%RMM%'


--og审计表
B文件
select * from incsdba.pre_merge_cdr_bgsm_731 t where  calling_number='18400607896' and db_insr_dt between  20221215 and 20221227
select * from incsdba.pre_merge_file_audit where ori_file_name like 'Vo_IBCF03_Z_187301_20221215171734_01323697%' 



--清理脚本核查
select * from  incsdba.process_state_cdr_file t where t.cdr_file_nm = 'Vo_IBCF01_H_190101_20221202010223_02170473_200_20221202_00000317';
select * from incsdba.cdr_voice_200 where db_insr_dt=20221221 and  ori_file_name = 'Vo_IBCF01_H_190101_20221202010223_02170473_200_20221202_00000317';

select * from incsdba.sttl_voice_200  where db_insr_dt=20221221 and ori_file_name = 'Vo_IBCF01_H_190101_20221202010223_02170473_200_20221202_00000317';

select * from incsdba.ckdup_ks_vo_200 where  ktag = 'Vo_IBCF01_H_190101_20221202010223_02170473_200_20221202_00000317';


select * from incsdba.err_cdr_voice_200  where db_insr_dt=20221221 and ori_file_name = 'Vo_IBCF01_H_190101_20221202010223_02170473_200_20221202_00000317';

select * from incsdba.duplicate_cdr_voice  where db_insr_dt=20221221 and ori_file_name = 'Vo_IBCF01_H_190101_20221202010223_02170473_200_20221202_00000317';

select * from incsdba.cdr_voice_file_audit  where db_insr_dt between 20221220 and 20221222  and  ori_file_name = 'Vo_IBCF01_H_190101_20221202010223_02170473_200_20221202_00000317';

select * from incsdba.err_voice_file_audit  where db_insr_dt=20221221 and ori_file_name = 'Vo_IBCF01_H_190101_20221202010223_02170473_200_20221202_00000317';s