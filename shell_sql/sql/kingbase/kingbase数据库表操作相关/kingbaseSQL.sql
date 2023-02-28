--创建DBLINK，需要在配置文件中新增
create database link incss1 connect to 'incss1' identified by '********' using 'kingbaseV8R6_TEST';

--网间
create database link incss1 connect to 'incss1' identified by '********' using  'kingbaseV8R6_incss1';   

--查看所有dblink
select * from sys_dblink;
select * from dba_db_links;

--删除dblink
drop database link  incss1

--表空间
--查看当前登录用户下所有表空间
select * from sys_tablespace;

--查看表空间占用内存大小
select pg_size_pretty(pg_tablespace_size('sys_default'));
select pg_size_pretty(pg_tablespace_size('tbs_detailcdr'));
select pg_size_pretty(pg_tablespace_size('tbs_dupcdr'));
select pg_size_pretty(pg_tablespace_size('tbs_fileaudit'));
select pg_size_pretty(pg_tablespace_size('tbs_incsdba'));
select pg_size_pretty(pg_tablespace_size('tbs_sttlcdr'));



--查看数据库最大连接数
show max_connections;
--查看当前连接总数
select count(*) from sys_stat_activity;
--查看数据库当前连接情况
select * from sys_stat_activity;
select * from sys_stat_activity where query='show database_mode' order by client_addr;

--查看数据库版本


--统计连接数
select count(*) from sys_stat_activity

--查看分区数据
select *  from  cdr_rmm_100_p20211202

--删除分区数据
alter table tableName DROP PARTITION partionName;  
--创建分区
CREATE TABLE ERR_VOICE_FILE_AUDIT_P20220102 PARTITION OF incsdba.ERR_VOICE_FILE_AUDIT FOR VALUES FROM (20220102) TO (20220103) TABLESPACE TBS_INCSDBA

--导入导出dmp文件
--——————————导出exp和expdp——————————————--
--1、指定表
exp incsdba/********@incsm file=/app/mcb/incs/DELETED/maiyp/database/file/business_area_fixed_prov.dmp log=/app/mcb/incs/DELETED/maiyp/database/log/incsm.log tables=mcbdba.business_area_fixed_prov

--2、指定表空间

--3、限制条件
[mcbadm@cmitcsncs-1 /app/mcb/incs/DELETED/maiyp/database/shell]$ cat exp_incss2.sh
#!/usr/bin/bash
exp incsdba/********@incss2 file=/app/mcb/incs/DELETED/maiyp/ckdup_ks_vo_351_202010.dmp  log=/app/mcb/incs/DELETED/maiyp/incss2.log tables=incsdba.ckdup_ks_vo_351 parfile=exp.par
[mcbadm@cmitcsncs-1 /app/mcb/incs/DELETED/maiyp/database/shell]$ cat exp.par 
query=" where sttl_month in (202008,202009,202010)"

--4、exp $connStr tables=${TAB_NM}:${partName} file=${DBArchDir}/${partName}_${DB_USER}_${TAB_NM}.dmp


--——————————导入——————————————--
--1、例子：将D:\example.dmp文件中的库导入到mydb下的system用户中
sys_dump
--备份
 sys_dump -h 10.253.87.224 -U mcbdba -d incsm -p 54321 -Fd -t IMSI_LD_CD -f /app/mcb/incs/var/tmp/table.dmp   
 --导出来是一个gz文件和dat文件

 --备份，导出以insert语句的sql
 --sys_dump -h 数据库ip地址 -Umcbdba -dincsm -Fp -a --column-inserts -t 表名(如，mcbdba.business_area_fixed_prov) -f 目录/sql文件名
"sys_dump -h 10.253.87.224 -Umcbdba -dincsm -Fp -a --column-inserts -t mcbdba.sms_config,mcbdba.new_sttl_rule -f /home/kingbase/five.sql"


--导入
sys_restore  -f  /app/mcb/incs/nfs/arch/DB/incsPart/P20211120_incsdba_CDR_RMM_591.dmp -d incss4 -F c  -N incsdba -h 10.253.87.228


 sys_restore /app/mcb/incs/nfs/arch/DB/incsPart/P20211120_incsdba_CDR_RMM_591.dmp -Uincsdba -d incss4  -n incsdba -h 10.253.87.228

--分区不存在
 sys_restore /app/mcb/incs/nfs/arch/DB/incsPart/P20211103_incsdba_CDR_RMM_200.dmp -Uincsdba -d incss1 -n incsdba -h 10.253.87.225 -C
 --分区存在,则不需要通过-C创建
  sys_restore /app/mcb/incs/nfs/arch/DB/incsPart/P20211103_incsdba_CDR_RMM_200.dmp -Uincsdba -d incss1 -n incsdba -h 10.253.87.225 
--sys_restore —从一个由 sys_dump 创建的归档文件恢复一个 KingbaseES 数据库
 sys_restore [“connection-option“...] [“option“...] [“filename“]

 -a 只恢复数据，不恢复模式（数据定义）。
 -c  --clean 在重新创建数据库对象之前清除（丢弃）它们（除非使用了--if-exists，如果有对象在目标数据库中不存在，这可能会生成一些无害的错误消息）。
 -C  在恢复一个数据库之前先创建它。如果还指定了--clean，在连接到目标数据库之前丢弃并且重建它。
 -h  指定服务器正在运行的机器的主机名
 -n   指定模式名
 -U    指定用户


--查看当前执行的sql
select * from sys_stat_activity where query like '%NP_IN_MSISDN%'

--插入表数据，日期数据用''，字符串也用'',数字类型的数据不需要括号
insert into mcbdba.UNICOM_MSISDN_LD_CD values(020,1533788,'2021/11/12','2999/12/31','',02,'广州','','2021/11/12')

--登录

ksql -h 10.253.87.224 -p 54321 -U incsdba  -W  dbname=incsm -q -c 'select * from mcbdba.db_config_mapping_prov;'
select * from mcbdba.db_config_mapping_prov
ksql -h 10.253.87.225 -p 54321 -U incsdba -d incss1


----根据被锁表的表名，查询出oid(表名区分大小写)
select oid from sys_class where relname = '表名';
--根据查询出的oid，查询出pid
select pid from sys_locks where relation = 'oid';
--根据pid，强制结束该进程
select sys_terminate_backend(pid);



