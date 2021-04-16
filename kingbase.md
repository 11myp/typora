## kingbase

### ksql常用选项

- -h  hostname  主机IP/hostname
- -p  port   端口
- -U  username   用户名
- -w  关闭口令认证
- -W  password   密码
- -d  dbname       数据名
- -c  'command;'   sql命令
- -A  (-- no-align)  切换到非对齐输出模式
- -f   filename  从文件中读取命令
- -L  filename   将查询输出到文件中
- -q  不打印多余的信息
- -R singal  非对齐输出的记录分隔符
- -t  关闭打印列名和结果行计数页脚

```sql
ksql -h ip -p 54321 -U maiyp -d test -W -c 'select * from mcbdba.db_config_mapping_prov;'
```

```sql
ksql -h ip -p 54321 -U incsdba -d incsm -W -R' ' -A -c 'select * from mcbdba.db_config_mapping_prov where prov_cd=100;'
Password: 
db_host|db_port|db_service_name|db_sid|db_user_nm|prov_cd|db_max_conn_size 10.253.87.225|54321|incss1|incss1|incsdba|100|10 (1 row)
```

```sql
 ksql -h 10.253.87.224 -p 54321 -U incsdba -d incsm -W  -t -c 'select db_service_name from mcbdba.db_config_mapping_prov where prov_cd in ('100','898');'
Password: 
 incss1
 incss4
```

### ksql中含有变量

```shell
  ksql -h ${DB_HOST} -p 54321 -U incsdba -d ${DB_SERVICE_NM} -w -t 2>&1 > /app/mcb/incs/DELETED/maiyp/log/dbMoFilesTmp.${PROV} <<EOF
    select cdr_file_nm from incsdba.process_state_cdr_file where cdr_file_nm like 'M%_${PROV}_${MONTH}_%' and stat = 'C'; 
    #sql语句中的筛选字符含有变量时（如：cdr_file_nm like 'M%_${PROV}_${MONTH}_%'），不能使用-c ,-c也需要单引号‘’,会有冲突导致变量不能解析
  EOF
```

