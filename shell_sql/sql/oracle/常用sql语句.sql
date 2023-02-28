--查看数据库表空间
select distinct tablespace_name from dba_data_files ;


--查询当前用户拥有哪些表
select table_name from user_table;

--3、查询所有表空间以及每个表空间的大小，已用空间，剩余空间，使用率和空闲率，直接执行语句就可以了：

select a.tablespace_name, total, free, total-free as used, substr(free/total * 100, 1, 5) as "FREE%", substr((total - free)/total * 100, 1, 5) as "USED%" from 
(select tablespace_name, sum(bytes)/1024/1024 as total from dba_data_files group by tablespace_name) a, 
(select tablespace_name, sum(bytes)/1024/1024 as free from dba_free_space group by tablespace_name) b
where a.tablespace_name = b.tablespace_name 
order by a.tablespace_name;



--4、查看表空间使用率
Select tablespace_name,sum_space/(1024*1024) as total_space,sum_free_space/(1024*1024) as free_space,(sum_space-sum_free_space)/1024/1024 as used_space,to_char(100*(sum_space-sum_free_space)/sum_space,'99.99')||'%' as pct_use
from            
(select tablespace_name,sum(bytes) as sum_space
from dba_data_files          
group  by tablespace_name) , 
(select tablespace_name as fs_ts_name,sum(bytes) as sum_free_space
from dba_free_space          
group by tablespace_name)    
where tablespace_name=fs_ts_name
order by pct_use;    


--5、查看某个表空间下所有表所占空间大小
 select t.tablespace_name, t.segment_name, t.segment_type, sum(t.bytes / 1024 / 1024) MB
from dba_segments t
where t.tablespace_name = 'TBS_INCSDBA'
and t.segment_type='TABLE'
group by t.tablespace_name, t.segment_name, t.segment_type
order by MB desc;

--查看当前数据库的所有表
select * from dba_tables;
--查询当前数据库的库名、实例名
Select name from v$database;/SELECT instance_name FROM v$instance;

--6、查看某个表空间的使用率
select a.tablespace_name, total, free, total-free as used, substr(free/total * 100, 1, 5) as "FREE%", substr((total - free)/total * 100, 1, 5) as "USED%" from 
(select tablespace_name, sum(bytes)/1024/1024 as total from dba_data_files group by tablespace_name) a, 
(select tablespace_name, sum(bytes)/1024/1024 as free from dba_free_space group by tablespace_name) b
where a.tablespace_name = b.tablespace_name  and a.tablespace_name ='TBS_INCSDBA'
order by a.tablespace_name;

--7、创建dblink

create public database link NC65DBLINK    
 connect to nc56 identified by nc56  
 using '(DESCRIPTION =(HOST = 192.168.17.254))';
 
 create public database link testlink
 connect to WANGYONG identified by "123456" USING 'ORCL21'


--8、查看数据库当前执行的sql语句
SELECT b.sid oracleID,  
       b.username Oracle用户,  
       b.serial#,  
       spid 操作系统ID,  
       paddr,  
       sql_text 正在执行的SQL,  
       b.machine 计算机名  
FROM v$process a, v$session b, v$sqlarea c  
WHERE a.addr = b.paddr  
   AND b.sql_hash_value = c.hash_value;


--9、查看是否有锁表
select b.owner,b.object_name,a.session_id,a.locked_mode from v$locked_object a,dba_objects b where b.object_id = a.object_id;

--10、查看慢sql
select *
 from (select sa.SQL_TEXT,
        sa.SQL_FULLTEXT,
        sa.EXECUTIONS "执行次数",
        round(sa.ELAPSED_TIME / 1000000, 2) "总执行时间",
        round(sa.ELAPSED_TIME / 1000000 / sa.EXECUTIONS, 2) "平均执行时间",
        sa.COMMAND_TYPE,
        sa.PARSING_USER_ID "用户ID",
        u.username "用户名",
        sa.HASH_VALUE
     from v$sqlarea sa
     left join all_users u
      on sa.PARSING_USER_ID = u.user_id
     where sa.EXECUTIONS > 0
     order by (sa.ELAPSED_TIME / sa.EXECUTIONS) desc)
 where rownum <= 50;

 
--11、Oracle模糊匹配多个字符串，效率比较低
--匹配字符串开头
 select stat from incsdba.process_state_cdr_file where regexp_like(cdr_file_nm, '(Vo_IBCF02_H_210202_20210406155721_00000720|Vo_IBCF02_H_210202_20210406105407_00000712)$')
--结尾 
select stat from incsdba.process_state_cdr_file where regexp_like(cdr_file_nm, '^(Vo_IBCF02_H_210202_20210406155721_00000720|Vo_IBCF02_H_210202_20210406105407_00000712)')
--所有
select stat from incsdba.process_state_cdr_file where regexp_like(cdr_file_nm, '(Vo_IBCF02_H_210202_20210406155721_00000720|Vo_IBCF02_H_210202_20210406105407_00000712)')


--12、备份数据库表
create table incsdba.process_state_cdr_file_20210423 as
  select * from incsdba.process_state_cdr_file_20210423 where process_dt < 20210101

delete * from incsdba.process_state_cdr_file where process_dt < 20210101

--查看某个用户下的所有表和视图
select * from all_tab_comments where owner = 'MCBDBA'  and TABLE_TYPE ='TABLE'







--、函数使用
--instr(源字符串，目标字符串，起始字符串，匹配字符串)=返回要截取的字符串在源字符串中的位置，从字符的开始，只检索一次
--substr(字符串，截取开始位置，截取长度)=返回截取的字
substr("WJ_VOICE_20210426_039.100",10,8)=20210426
substring_index(str, delim, count)  str：需要拆分的字符串；；delim：分隔符，根据此字符来拆分字符串；count：当 count 为正数，从左到右数，取第 n 个分隔符之前的所有字符； 当 count 为负数，从右往左数，取倒数第 n 个分隔符之后的所有字符
left(SUBSTRING(cdr_file_nm,charindex('_',cdr_file_nm,1)+1,len(cdr_file_nm)),CHARINDEX('_',SUBSTRING(cdr_file_nm,charindex('_',cdr_file_nm,1)+1),1)-1)
select LEFT(SUBSTRING(@str,charindex(',',@str,1)+1,len(@str)),CHARINDEX(',',SUBSTRING(@str,charindex(',',@str,1)+1,len(@str)),1)-1) as '中间的值'
set @str='462,464,2';
--13、查看当前连接数

--14、查询未提交事务 DML 语句
SELECT  S.SID
       ,S.SERIAL#
       ,S.USERNAME
       ,S.OSUSER 
       ,S.PROGRAM 
       ,S.EVENT
       ,TO_CHAR(S.LOGON_TIME,'YYYY-MM-DD HH24:MI:SS') 
       ,TO_CHAR(T.START_DATE,'YYYY-MM-DD HH24:MI:SS') 
       ,S.LAST_CALL_ET 
       ,S.BLOCKING_SESSION   
       ,S.STATUS
       ,( 
              SELECT Q.SQL_TEXT 
              FROM    V$SQL Q 
              WHERE  Q.LAST_ACTIVE_TIME=T.START_DATE 
              AND    ROWNUM<=1) AS SQL_TEXT   
FROM   V$SESSION S, 
       V$TRANSACTION T  
WHERE  S.SADDR = T.SES_ADDR;


--15、表空间扩容
alter tablespace TBS_DETAILCDR add datafile '/database/oracle/datafile/incss3/detailcdr178.dbf' size 30g autoextend off;

--16.查看所有的序列和触发器
--某个用户下的序列
select SEQUENCE_OWNER,SEQUENCE_NAME from dba_sequences where sequence_owner='INCSDBA';

--某个用户下触发器
select * from all_triggers where owner = 'INCSDBA'

--过滤时间戳字段
select * from incsdba.process_state_cdr_file where cdr_file_nm = 'zzz' and to_date(to_char(prcss_tm,'yyyy/mm/dd hh24:mi:ss'))>to_date('2021/07/29 19:34:50')


--17、查看指定表的所有字段，并以|隔开
select listagg(column_name,'|')within GROUP(order by COLUMN_ID) from all_tab_columns where table_name='ACCESS_NUM';




-----------------kingbase数据库中的sql使用-------------------------------------
--统计连接数
select count(*) from sys_stat_activity
--

--17、查询某个字段是否重复
select *  from mcbdba.USER_INFORMATION_451 where phone in (select phone from  mcbdba.USER_INFORMATION_451 group by phone having count(phone)>1)

--18、查看是否有调用存储过程的权限
select * from session_privs where privilege like '%PROCEDURE%';
--确定用户帐户所授予的权限
select * from DBA_tab_privs ;   直接授予用户帐户的对象权限
select * from DBA_role_privs ; 授予用户帐户的角色
select * from DBA_sys_privs ;   授予用户帐户的系统权限

--查看当前用户权限:
SQL> select * from session_privs;
-- 
SELECT *
  FROM DBA_SYS_PRIVS D
 WHERE D.PRIVILEGE = 'CREATE ANY PROCEDURE' OR
       D.PRIVILEGE = 'EXECUTE ANY PROCEDURE' OR
       D.PRIVILEGE = 'DEBUG ANY PROCEDURE'
--关于存储过程的系统权限一般有六种： CREATE PROCEDURE、CREATE ANY PROCEDURE、 ALTER ANY PROCEDURE、DROP ANY PROCEDURE、 EXECUTE ANY PROCEDURE、DEBUG ANY PROCEDURE。

