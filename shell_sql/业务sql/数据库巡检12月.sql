--all
select * from incsdba.err_cdr_resend_b t where t.file_name like 'EB07%' and t.revise_flag=0  and call_start_tm like '2021%'

select  err_cd,count(*) from incsdba.err_cdr_resend_b t where t.file_name like 'EB07%' and t.revise_flag=0 group by err_cd

select * from incsdba.err_cdr_resend_b t where t.file_name like 'EB07%' and t.revise_flag=0 and t.err_cd ='F045' and prov_cd = 431

select * from incsdba.err_cdr_resend_b t where t.file_name like 'EB%' and t.revise_flag=0  and err_cd = 'F045' and src_line not like '%17300%'

select * from incsdba.err_cdr_resend_b t where t.file_name like 'EB%' and t.revise_flag=0  and err_cd = 'F042' and src_line not  like '%17300%'




--��ѯ����
select * from incsdba.err_cdr_resend_b  t
where t.file_name like 'EB07%' and t.err_cd='F171' and t.revise_flag=0 and substr(t.src_line,108,3)=311 

select t.err_cd,substr(t.src_line,1,109)||'2'||substr(t.src_line,111) from incsdba.err_cdr_resend_b  t
where t.file_name like 'EB07%' and t.err_cd='F171' and t.revise_flag=0 and substr(t.src_line,108,3)=311 

select t.err_cd,substr(t.src_line,1,109)||'1'||substr(t.src_line,111) from incsdba.err_cdr_resend_b  t
where t.file_name like 'EB07%' and t.err_cd='F171' and t.revise_flag=0 and substr(t.src_line,108,3)=312

select * from incsdba.err_cdr_resend_b  t
where t.file_name like 'EB07%' and t.err_cd='F171' and t.revise_flag=0 and substr(t.src_line,108,3)=312

--F171,311
update incsdba.err_cdr_resend_b t  set t.src_line=substr(t.src_line,1,109)||'2'||substr(t.src_line,111),t.revise_flag=1
where t.file_name like 'EB07%' and t.err_cd='F171' and t.revise_flag=0 and substr(t.src_line,108,3)=311

--F171,312
update incsdba.err_cdr_resend_b t  set t.src_line=substr(t.src_line,1,109)||'1'||substr(t.src_line,111),t.revise_flag=1
where t.file_name like 'EB07%' and t.err_cd='F171' and t.revise_flag=0 and substr(t.src_line,108,3)=312


--F043
select substr(t.src_line,1,36) from incsdba.err_cdr_resend_b t 
where t.file_name like 'EB07%' and t.err_cd='F043' and t.revise_flag=0

select substr(t.src_line,43,11) from incsdba.err_cdr_resend_b t 
where t.file_name like 'EB07%' and t.err_cd='F043' and t.revise_flag=0

select substr(t.src_line,3,6) from incsdba.err_cdr_resend_b t 
where t.file_name like 'EB07%' and t.err_cd='F043' and t.revise_flag=0

select substr(t.src_line,54,137) from incsdba.err_cdr_resend_b t 
where t.file_name like 'EB07%' and t.err_cd='F043' and t.revise_flag=0

select substr(t.src_line,1,36)||substr(t.src_line,43,11)||substr(t.src_line,3,6)||substr(t.src_line,54) from incsdba.err_cdr_resend_b t 
where t.file_name like 'EB07%' and t.err_cd='F043' and t.revise_flag=0

select * from incsdba.err_cdr_resend_b t 
where t.file_name like 'EB07%' and t.err_cd='F043' and t.revise_flag=0

--�޸�F043����
update incsdba.err_cdr_resend_b t  set t.src_line=substr(t.src_line,1,36)||substr(t.src_line,43,11)||substr(t.src_line,3,6)||substr(t.src_line,54),t.revise_flag=1
where t.file_name like 'EB07%' and t.err_cd='F043' and t.revise_flag=0



