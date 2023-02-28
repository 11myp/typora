--�޸Ĵ�����F171,311
update incsdba.err_cdr_resend_b t  set t.src_line=substr(t.src_line,1,109)||'2'||substr(t.src_line,111),t.revise_flag=1
where t.file_name like 'EB01%' and t.err_cd='F171' and t.revise_flag=0 and substr(t.src_line,108,3)=311;

--F171,312
update incsdba.err_cdr_resend_b t  set t.src_line=substr(t.src_line,1,109)||'1'||substr(t.src_line,111),t.revise_flag=1
where t.file_name like 'EB01%' and t.err_cd='F171' and t.revise_flag=0 and substr(t.src_line,108,3)=312;

commit;



---kingbase#20221209#修复B文件未截取12540#
-- 02               18721204888    04511254010712345       202212082229390003208613445692451 8613445692000    3110003240                                                                         

 --剔除F043报错中的12540+NNN,剔除部分补充空格更新语句
update incsdba.ERR_CDR_RESEND_B
set revise_flag=1,
   src_line =  substr(  src_line, 0,  32  )|| 
 rpad(substr(substr(src_line,33,24), 0, instr(substr(src_line,33,24), '12540') -1 ) ||
       substr(substr(src_line,33,24), instr(substr(src_line,33,24), '12540') + 8, length(substr(src_line,33,24))) ,
       24,
       ' ')||
  substr(src_line,57,134)
where
  DB_INSR_DT=20221209 and  ERR_CD = 'F043'   and substr(src_line,33,24) like '%12540%';