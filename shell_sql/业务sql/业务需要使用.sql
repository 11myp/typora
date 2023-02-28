--################################经分#####################################
--1、经分数据验证
select * from incsdba.cdr_voice_file_audit@incss4 where voice_og_file_name like 'tbf%'and ic_prov_cd=731;

--经分审计表的处理速度
select ic_prov_cd,sum(cdr_count) from incsdba.cdr_voice_file_audit@incss4  where voice_og_file_name like 'WJ_VOICE%20210130%' group by ic_prov_cd
--每个省某天产生的文件总数
select prov_cd,sum(cdr_count) from incsdba.process_state_cdr_file@incss4   where cdr_file_nm like 'V%_20210130_%' group by prov_cd

select distinct voice_og_file_name from incsdba.cdr_voice_file_audit@incss4 where voice_og_file_name not like 'WJ%' and ic_prov_cd=731
--统计经分一天抽取的话单量
select ic_prov_cd,sum(cdr_count) from incsdba.cdr_voice_file_audit@incss4 where  voice_og_file_name like 'WJ_VOICE_20210114%' group by ic_prov_cd

--排查经分是否有积压
select ori_file_name from incsdba.cdr_voice_file_audit  where voice_og_file_name like 'tbf%' and db_insr_dt = 20210417 and ic_prov_cd = 731

select ic_prov_cd,count(*) from incsdba.cdr_voice_file_audit@public.incss1  where voice_og_file_name = 'tbf_later' group by ic_prov_cd
union
select ic_prov_cd,count(*) from incsdba.cdr_voice_file_audit@public.incss2  where voice_og_file_name = 'tbf_later' group by ic_prov_cd
union
select ic_prov_cd,count(*) from incsdba.cdr_voice_file_audit@public.incss3  where voice_og_file_name = 'tbf_later' group by ic_prov_cd
union
select ic_prov_cd,count(*) from incsdba.cdr_voice_file_audit@public.incss4  where voice_og_file_name = 'tbf_later' group by ic_prov_cd
union
select ic_prov_cd,count(*) from incsdba.cdr_voice_file_audit@public.incss5  where voice_og_file_name = 'tbf_later' group by ic_prov_cd
union
select ic_prov_cd,count(*) from incsdba.cdr_voice_file_audit@public.incss6  where voice_og_file_name = 'tbf_later' group by ic_prov_cd
--错单 -err
select ic_prov_cd,count(*) from incsdba.err_voice_file_audit@public.incss1  where voice_og_file_name = 'tbf_later' group by ic_prov_cd
union
select ic_prov_cd,count(*) from incsdba.err_voice_file_audit@public.incss2  where voice_og_file_name = 'tbf_later' group by ic_prov_cd
union
select ic_prov_cd,count(*) from incsdba.err_voice_file_audit@public.incss3  where voice_og_file_name = 'tbf_later' group by ic_prov_cd
union
select ic_prov_cd,count(*) from incsdba.err_voice_file_audit@public.incss4  where voice_og_file_name = 'tbf_later' group by ic_prov_cd
union
select ic_prov_cd,count(*) from incsdba.err_voice_file_audit@public.incss5  where voice_og_file_name = 'tbf_later' group by ic_prov_cd
union
select ic_prov_cd,count(*) from incsdba.err_voice_file_audit@public.incss6  where voice_og_file_name = 'tbf_later' group by ic_prov_cd

--一级经分/大数据经分
select * from incsdba.bigdata_gz_state




--######################巡检################################

--巡检，数据平衡性。要先刷新/app/mcb/incs/bin/checkIncsDaily.sh  （ncs-1）
select * from incsdba.incs_file_complete_daily where file_dt like '202101%' and stat!='1'
--巡检系统处理情况，
select * from incsdba.incs_process_status_daily where ic_file_dt = 
--上线省份重处理文件
select distinct prov_cd from incsdba.incs_file_complete_daily where stat!='1' and file_dt =  '20210314' and prov_cd in (951,351,931,431,971,991,311,451,220,891,898,471,731) and a.revise_flag=0 

--查看数据处理状态表
select * from incsdba.process_state_cdr_file  where process_dt=20210311 and stat='C' and cdr_file_type='Voice'

select count（*） from incsdba.process_state_cdr_file@incss1  where process_dt=20210311 and stat='C' and cdr_file_type='Voice'
union
select count（*） from incsdba.process_state_cdr_file@incss2  where process_dt=20210311 and stat='C' and cdr_file_type='Voice'
union
select count（*） from incsdba.process_state_cdr_file@incss3  where process_dt=20210311 and stat='C' and cdr_file_type='Voice'
union
select count（*） from incsdba.process_state_cdr_file@incss4  where process_dt=20210311 and stat='C' and cdr_file_type='Voice'



--#####################EB：B文件错单##################################
--修复错单，F080
update incsdba.err_cdr_resend_b a 
set a.src_line=substr(a.src_line,1,86)||(select substr(b.ld_area_cd,2,3) from mcbdba.swch_id_ld_cd b 
where substr(src_line,79,8) =b.swch_area_id 
)||substr(src_line,90), 
a.revise_flag=1
where err_cd='F080' and a.file_name like 'EB0119%'  
and a.prov_cd=931 and exists 
(select 1 
from mcbdba.swch_id_ld_cd b 
where substr(src_line,79,8) =b.swch_area_id ) 

--##################错单回收#########################################
--配置错单回收
--1.查看错单量,错单量不多才可以配置
select count(*) from incsdba.err_cdr_voice_771 where db_insr_dt between 20210401 and 20210430 and err_code = 'F098'
--查看多天的错单量
select substr(call_start_tm,1,8),count(*) from incsdba.err_cdr_voice_771 
where err_code = 'F098' and substr(call_start_tm,1,8) between '20210401' and '20210430' group by substr(call_start_tm,1,8)

--2.配置
--查看之前是否回收过相同项
insert into  mcbdba.ERR_RECOVERY_CONFIG(prov_cd,cdr_file_type,err_type,re_start_time,re_end_time,recovery_flag) values(771,'VOICE','F098',20210401,20210401,0)

--paas
#951
select count(*) from incsdba.process_state_cdr_file where cdr_file_nm like '%_951_20201123%'

select sum(cdr_count),sum(error_count),sum(duplicate_count),sum(not_trunk_count),sum(not_sttl_rule_count) from incsdba.process_state_cdr_file where cdr_file_nm like '%_951_20201123%' ;

select sum(cdr_count)+sum(error_count)+sum(duplicate_count)+sum(not_trunk_count)+sum(not_sttl_rule_count)
 from incsdba.process_state_cdr_file where cdr_file_nm like '%_951_20201123%' ;
 

--################################系统性能#################################
--统计某天处理记录表每个小时文件的处理量
select substr(to_char(prcss_tm,'YYYY/MM/DDHH24:MI'),0,13),count(cdr_file_nm) from incsdba.process_state_cdr_file where prov_cd=851 and process_dt=20210419 
group by substr(to_char(prcss_tm,'YYYY/MM/DDHH24:MI'),0,13)

--



--话单平均处理时长
select sum(to_number(to_date(to_char(end_time,'yyyy/mm/dd hh24:mi:ss'),'yyyy/mm/dd hh24:mi:ss')-
to_date(to_char(prcss_tm,'yyyy/mm/dd hh24:mi:ss'),'yyyy/mm/dd hh24:mi:ss'))*24*60*60)/count(*)  from incsdba.process_state_cdr_file where process_dt like '202105%'

--
select substr(process_dt,1,6),sum(to_number(to_date(to_char(end_time,'yyyy/mm/dd hh24:mi:ss'),'yyyy/mm/dd hh24:mi:ss')-
to_date(to_char(prcss_tm,'yyyy/mm/dd hh24:mi:ss'),'yyyy/mm/dd hh24:mi:ss'))*24*60*60)/count(*)  from incsdba.process_state_cdr_file where process_dt like '20210%'
group by  substr(process_dt,1,6)

--统计系统吞吐量（TPS）
select 'incss1'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss1 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%'
union 
select 'incss2'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss2 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%'
union 
select 'incss3'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss3 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%'
union 
select 'incss4'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss4 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%'
union 
select 'incss5'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss5 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%'
union 
select 'incss6'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss6 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%' 


--sql：查询某一天中，记录表话单量和sttl表话单量不一致的文件
select a.ori_file_name from 
(select ori_file_name,sum(cdr_count) cdr_cnt from incsdba.sttl_voice_210  where sttl_dt = 20230101 group by ori_file_name) a,
(select cdr_file_nm,cdr_count from "incsdba"."process_state_cdr_file" t where process_dt = 20221130 and prov_cd=210 and t."cdr_file_type"='Voice'  and t."stat"='C') b 
on a.cdr_cnt <> b.cdr_count and a.ori_file_name =b.cdr_file_nm;

--例子
select a.ori_file_name from 
(select ori_file_name,sum(cdr_count) cdr_cnt from test.sttl_voice_210  where sttl_dt like  '2023-01-01%' group by ori_file_name) a,
(select cdr_file_nm,cdr_count from test.process_state_cdr_file t where process_dt like  '2023-01-01%' ) b 
where a.cdr_cnt <> b.cdr_count and a.ori_file_name=b.cdr_file_nm;
--快，百条数据，8ms

select a.ori_file_name from 
(select ori_file_name,sum(cdr_count) cdr_cnt from test.sttl_voice_210  where sttl_dt like  '2023-01-01%' group by ori_file_name) a
inner join
(select cdr_file_nm,cdr_count from test.process_state_cdr_file t where process_dt like  '2023-01-01%' ) b 
where a.cdr_cnt <> b.cdr_count and a.ori_file_name=b.cdr_file_nm ;
--慢,百条数据，16ms