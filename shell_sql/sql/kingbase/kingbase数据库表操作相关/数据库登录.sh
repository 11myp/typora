####数据库登录

#!/bin/bash
DB_HOST
DB_PASSWORD=`getdbpwd incsdba`
DB_USER=incsdba
PROV=$1
PRE_DAY=`preday 1 date`

ksql "host=10.253.87.224 port=54321 user=incsdba password=$DB_PASSWORD dbname=incsm"   >/app/mcb/incs/DELETED/maiyp/kingbase.txt 2>&1   << EOF
  select db_host,db_service_name from mcbdba.db_config_mapping_prov where prov_cd =${PROV};
EOF

DB_SERVICE_NM=`grep incs /app/mcb/incs/DELETED/maiyp/kingbase.txt|awk '{print $2}' `
DB_HOST=`grep incs /app/mcb/incs/DELETED/maiyp/kingbase.txt|awk '{print $2}' 

#查看是否有处理失败状态不为C的文件，清理数据
sqlplus incsdba/Cmit_incs0@${db_service_nm} 2>&1 > /app/mcb/incs/DELETED/zengtf/log/voCleanTmp.${prov} <<EOF
set feedback off
set echo off
set linesize 500
set pagesize 500
select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'V%_${prov}_${month}_%' and stat != 'C';
EOF


ksql -h $DB_HOST -p 54321 -u incsdba -p $DB_PASSWORD dbname=$DB_SERVICE_NM  >>  /app/mcb/incs/DELETED/maiyp/kingbase.txt 2>&1   <<EOF
  select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'V%_${prov}_${PRE_DAY}_%' and stat != 'C';
EOF





ksql -h 10.253.87.224 -p 54321 -U incsdba  -W  dbname=incsm -q -c 'select * from mcbdba.db_config_mapping_prov;'

select * from mcbdba.db_config_mapping_prov


 ksql -h 10.253.87.225 -p 54321 -U incsdba -d incss1