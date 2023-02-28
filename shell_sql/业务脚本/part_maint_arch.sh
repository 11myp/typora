#!/bin/bash
# @file         part_maint_arch.sh
# @author       LiJianfeng
# @date         2005/12/28
# @version      0.0.1
# @brief        根据配置文件，清理给定表的分区，用于ARCH系统
#
#
# Copyright(c) China-Mobile(SZ) 2005. All rights reserved.
#
# Change log:
# <pre>
#     author      time          version     description
# ----------------------------------------------------------
#     LiJianfeng  2005.12.28    0.0.1       create
#     LiJianfeng  2006.09.11    0.0.2       modify
#     王琦  2021.07.19    0.1.0       modify
# </pre>
#
# 2006.09.11:lijf:修改程序调用expr的错误


myself="part_maint_arch"
process_name="part_maint_arch.sh"
logfile="${MCB_HOME}/${MCB_APPID}/var/log/${myself}.log"
sqlplus_script="${MCB_HOME}/${MCB_APPID}/var/log/${myself}.sql"
sqlplus_script_modify="${MCB_HOME}/${MCB_APPID}/var/log/${myself}_modify.sql"
sqlplus_temp="${MCB_HOME}/${MCB_APPID}/var/log/${myself}.temp.sql"
sqlplus_logfile="${MCB_HOME}/${MCB_APPID}/var/log/${myself}_sqlplus.log"
conffile="${MCB_HOME}/${MCB_APPID}/conf/${myself}.conf"
TMP_DIR="${MCB_HOME}/${MCB_APPID}/var/tmp"
add_month_val=0

#DEBUG标志：如果设置为1，表示输出调试信息，否则不输出调试信息
DEBUG=1
#默认密码开关
DEBUG2=0

#
#@brief:输出调试信息的函数
#@param1:调试信息，只有DEBUG=1的时候，调试信息才显示
function DBMSG
{
	if [ ${DEBUG} -ne 1 ];then
		return 0
	fi

	if [ $# -lt 1 ];then
		echo "SERIOUS:DBMSG need 1 argument: DEBUGMSG"
		return 1
	fi
	echo $1
	return 0
}


#@brief:写日志函数
#@param1:告警级别，<INFO|WARNING|ALARM|SERIOUS>
#@message:日志内容，如果DEBUG=1，日志信息将在终端显示
#@logfile:日志文件名称
function write_log
{
	if [ $# -ge 2 ];then
		message="$2"
	fi
	
	DBMSG "[LOG:$1]${message}"
	lgWriteLog "$1" "" -1 "${message}"
	return 0
}

#
#@brief:从SQLPLUS的日志文件中获取出错信息
#@message:日志信息
#@sqlplus_logfile:SQLPLUS的日志文件
#@return: 0:表示正常，1:表示SQLPLUS运行出错
function get_sqlplus_err
{
	grep -E "ERROR" ${sqlplus_logfile} >>/dev/null
	if [ $? -ne 1 ]; then
		message="PL/SQL is wrong!"
		write_log "SERIOUS"

		grep "ERROR" ${sqlplus_logfile} | while read message
		do
			write_log "SERIOUS"
		done

#		grep -E "ORA-|PLS-|PL/SQL:" ${sqlplus_logfile}| while read message
#		do
#			write_log "SERIOUS"
#		done
		return 1
	fi
	grep "sql_ret_err" ${sqlplus_logfile}>>/dev/null
	if [ $? -ne 1 ]; then
		message="PL/SQL executing result is wrong!"
		write_log "SERIOUS"
		return 1
	fi
	return 0
}


#
#@brief:检查读取的配置信息是否正确
#@param1:ptype分区依据
#@param2:lowday分区保留天数
#@param3:advcycles创建分区的天数
#@param4:vtype分区的数据类型
function check_conf
{
	if [ $# -lt 4 ];then
		write_log "SERIOUS" "check_conf() should have 4 param: ptype lowday advcycles vtype"
		return 1
	fi
	ck_ptype=$1
	ck_lowday=$2
	ck_advcycles=$3
	ck_vtype=$4
	ck_tstype=$5

	DBMSG "check_conf ck_ptype=[${ck_ptype}] ck_lowday=[${ck_lowday}] ck_advcycles=[${ck_advcycles}] ck_vtype=[${ck_vtype}]"

	#ptype必须是DAY_PROV或DAY
	if [ "${ck_ptype}" != "DAY_PROV" -a "${ck_ptype}" != "DAY" -a "${ck_ptype}" != "DAY_PROV_SUB" -a "${ck_ptype}" != "MONTH" ]; then
		write_log "SERIOUS" "PARTITON should be DAY_PROV DAY  DAY_PROV_SUB or MONTH, please check the conffile"
		return 1
	fi

	#vtype必须是DATE或NODATE
	if [ "${ck_vtype}" != "DATE" -a "${ck_vtype}" != "NODATE" ]; then
		write_log "SERIOUS" "VALUE_TYPE should be DATE or NODATE, please check the conffile"
		return 1
	fi

	#lowday必须是数字，并且大于0
	if [ ${ck_lowday} -lt 1 ]; then
		write_log "SERIOUS" "LOWDAY should be NUMBER and >0, please check the conffile"
		return 1
	fi

	#advcycles必须是数字，并且大于0
	if [ ${ck_advcycles} -lt 1 ]; then
		write_log "SERIOUS" "ADVCYCLES should be NUMBER and >0, please check the conffile"
  
		return 1
	fi

    #_tstype must be number, 0/1fp
	if [ ${ck_tstype} -ne "0" -a ${ck_tstype} -ne "1" ]; then
		write_log "SERIOUS" "tstype should be NUMBER 0/1, please check the conffile"
		return 1
	fi
	return 0
}


function Add_Months
{
	_date_month=$1
	_date_add=$2
	_schem=$3
	_pwd=$4
	_appid=$5
	
  >${sqlplus_temp}
  echo "SELECT to_char(add_months(to_date('$_date_month','YYYYMM'), $_date_add),'YYYYMM') FROM dual;">>${sqlplus_temp}
	
  write_log "INFO" "Add_Months params are host:[${mp_dburl}],port:[${mp_dbport}],user:[${mp_schema}],password:[***],dbname:[${mp_appid}]"
  ksql "host=${mp_dburl} port=${mp_dbport} user=${mp_schema} password=${mp_dbpwd} dbname=${mp_appid}" -f ${sqlplus_temp} >${sqlplus_logfile} 2>&1

	if [ $? -ne 0 ] ;then
		write_log "SERIOUS" "Can not access db or Can not write to ${sqlplus_logfile}, qurey add_months failed"
		#return 1
		exit 1
	fi

	get_sqlplus_err
	if [ $? -ne 0 ]; then
		write_log "SERIOUS" "Get add_months failed, please check script:${sqlplus_temp}"
		#return 1
		exit 1
	fi
	
	add_month_val=$(cat $sqlplus_logfile|grep "2"|sed -e 's/^[ \t]*//g')

#	rm ${sqlplus_temp}
	
	return 0
}

function loadPassowrd(){
  mp_schema=$1   #模式名
  mp_appid=$2   #数据库
  mp_pwdurl=$3  #数据库访问地址

  ###根据数据库用户名查询密码
  echo $mp_appid $mp_schema $mp_pwdurl
#  echo $mp_pwdurl | ${MCB_HOME}/${MCB_APPID}/bin/PwdClient getdbpwd ${mp_appid} ${mp_schema} |&>${TMP_FILE} 2>&1
#  mp_dbpwd=`grep "sPasswd :" ${TMP_FILE}|awk -F: '{print $2}'`
  echo $mp_pwdurl | ${MCB_HOME}/${MCB_APPID}/bin/PwdClient getdbpwd ${mp_appid} ${mp_schema} |& iconv -f gbk -t utf8
  mp_dbpwd=`echo $mp_pwdurl | ${MCB_HOME}/${MCB_APPID}/bin/PwdClient getdbpwd ${mp_appid} ${mp_schema} |&  iconv -f gbk -t utf8 | grep "sPasswd :" ${TMP_FILE} | awk -F: '{print $2}'`

  if [ ${DEBUG2} -eq 1 ];then
    mp_dbpwd=$mp_schema
  fi

  if [ -z "${mp_dbpwd}" ];then
    lgWriteLog SERIOUS "${INST_NAME}" W102-0901 "错误: 获取数据库用户密码失败!"
   exit 1
  fi

  DBMSG "mp_dbpwd=[***]";
}

function removePartition   #删除分区
{
	if [ $# -lt 12 ];then
		write_log "SERIOUS" "MaintainPartition() should have 11 param: ptype tabnm tsnm schema lowday advcycles vtype appid tstype pwdurl dburl dbport"
		return 1
	fi

	mp_ptype=$1
	mp_tabnm=$2
	mp_tsnm=$3
	mp_schema=$4
	mp_lowday=$5
	mp_advcycles=$6
	mp_vtype=$7
	mp_appid=$8
	mp_tstype=$9
	mp_pwdurl=${10}
	mp_dburl=${11}
	mp_dbport=${12}
	#获取访问数据库密码
	#mp_dbpwd=$(getdbpwd ${mp_schema})
	#if [ $? -ne 0 ]; then
	#	write_log "SERIOUS" "getdbpwd failed, schema=[${mp_schema}]"
	#	return 1
	#fi
	
	
	cur_month=$(date "+%Y%m")

	#检查SQL脚本是否可写
	if [ ! -f ${sqlplus_script} ]; then
		touch ${sqlplus_script}
	fi
	if [ ! -w ${sqlplus_script} ]; then
		write_log "SERIOUS" "SQLPLUS file can not write, sqlplus_script:[${sqlplus_script}]"
		return 1
		#exit 1
	fi

	#开始清理分区
	#清空脚本内容	
	>${sqlplus_script}
  if [ "$mp_ptype" = "MONTH" ];then
    DBMSG "cur_month=[${cur_month}]"
    Add_Months "$cur_month" "-$mp_lowday" "$mp_schema" "$mp_dbpwd" "$mp_appid"
    mp_dt=$add_month_val
    Add_Months "$mp_dt" "-1" "$mp_schema" "$mp_dbpwd" "$mp_appid"
    mp_dt2=$add_month_val
    DBMSG "mp_dt=[${mp_dt}]"
  else
    DBMSG "Start to drop partitions..."
    mp_dt=$(date -d ${mp_lowday}" days ago"  "+%Y%m%d")
    mp_dt2=$(date -d ${mp_dt}" 1 days ago"  "+%Y%m%d")
    DBMSG "mp_dt=[${mp_dt}]"
	fi
	
#	echo "SET HEAD OFF">>${sqlplus_script}
#   在kingbase下查询分区表名为小写，例如sttl_voice_daily_jyp_p20201103
#	mp_tabnmt_mp=$(echo ${mp_tabnm}|awk -F'.' '{print $NF}'|tr '[A-Z]' '[a-z]')
	mp_tabnmt_mp=$(echo ${mp_tabnm}|tr '[A-Z]' '[a-z]')
	echo "SELECT child.relname AS partition_name">>${sqlplus_script}
	echo "	FROM
				pg_inherits JOIN pg_class parent
			ON pg_inherits.inhparent = parent.oid JOIN pg_class child
			ON pg_inherits.inhrelid = child.oid JOIN pg_namespace nmsp_parent
			ON nmsp_parent.oid = parent.relnamespace JOIN pg_namespace nmsp_child
			ON nmsp_child.oid = child.relnamespace">>${sqlplus_script}
	echo "	WHERE child.relname < '${mp_tabnmt_mp}_p${mp_dt}' AND parent.relname='${mp_tabnmt_mp}';">>${sqlplus_script}
#	echo "exit;">>${sqlplus_script}

  if [ ${DEBUG} -eq 1 ];then
    echo "==QUERY PARTITION NAME SQL SCRIPT=============================================="
    cat ${sqlplus_script}
    echo ""
  fi

  echo ${mp_dburl} ${mp_dbport} ${mp_schema} *** ${mp_appid}
  write_log "INFO" "QUERY PARTITION NAME params are host:[${mp_dburl}],port:[${mp_dbport}],user:[${mp_schema}],password:[***],dbname:[${mp_appid}]"
  ksql "host=${mp_dburl} port=${mp_dbport} user=${mp_schema} password=${mp_dbpwd} dbname=${mp_appid}" -f ${sqlplus_script} >${sqlplus_logfile} 2>&1

	if [ $? -ne 0 ] ;then
		message="Can not access db or Can not write to ${sqlplus_logfile}, qurey partition_name failed"
		write_log "SERIOUS"
		return 1
		#exit 1
	fi

	get_sqlplus_err
	if [ $? -ne 0 ]; then
		write_log "SERIOUS" "Get partition_name failed, please check script:${sqlplus_script}"
		return 1
		#exit 1
	fi

	>${sqlplus_script}
	#cat ${sqlplus_logfile}
	#在kingbase下查询分区表名为小写，例如sttl_voice_daily_jyp_p20201103
#	mp_tabnmt_mp=$(echo ${mp_tabnm}|awk -F'.' '{print $NF}'|tr '[A-Z]' '[a-z]')
	mp_tabnmt_mp=$(echo ${mp_tabnm}|tr '[A-Z]' '[a-z]')
	echo ${mp_tabnmt_mp}
	cat ${sqlplus_logfile} | grep "${mp_tabnmt_mp}_p20" | while read mp_pname
	do
		echo "DROP TABLE ${mp_schema}.${mp_pname};">>${sqlplus_script}
	done
	#echo "exit;">>${sqlplus_script}


  if [ ${DEBUG} -eq 1 ];then
    echo "==DROP PARTITIONS SQL SCRIPT==================================================="
    cat ${sqlplus_script}
    echo ""
  fi

  write_log "INFO" "DROP PARTITIONS params are host:[${mp_dburl}],port:[${mp_dbport}],user:[${mp_schema}],password:[***],dbname:[${mp_appid}]"
  ksql "host=${mp_dburl} port=${mp_dbport} user=${mp_schema} password=${mp_dbpwd} dbname=${mp_appid}" -f ${sqlplus_script} >${sqlplus_logfile} 2>&1

  if [ $? -ne 0 ] ;then
    message="Can not access db or Can not write to ${sqlplus_logfile}, drop partitions failed"
    write_log "SERIOUS"
    return 1
  fi

  get_sqlplus_err
  if [ $? -ne 0 ]; then
    write_log "SERIOUS" "Drop partitions failed, please check script:${sqlplus_script}"
#    cat ${sqlplus_script} >> /home/mcbadm/incs/err.txt
    return 1
  fi

  return 0
}

function createPartition
{
	if [ $# -lt 12 ];then
		write_log "SERIOUS" "MaintainPartition() should have 11 param: ptype tabnm tsnm schema lowday advcycles vtype appid tstype pwdurl dburl dbport"
		return 1
	fi

	mp_ptype=$1
	mp_tabnm=$2
	mp_tsnm=$3
	mp_schema=$4
	mp_lowday=$5
	mp_advcycles=$6
	mp_vtype=$7
	mp_appid=$8
	mp_tstype=$9
	mp_pwdurl=${10}
	mp_dburl=${11}
	mp_dbport=${12}
	#获取访问数据库密码
	#mp_dbpwd=$(getdbpwd ${mp_schema})
	#if [ $? -ne 0 ]; then
	#	write_log "SERIOUS" "getdbpwd failed, schema=[${mp_schema}]"
	#	return 1
	#fi
	

	
	cur_month=$(date "+%Y%m")


	>${sqlplus_script}
#	echo "SET HEAD OFF">>${sqlplus_script}
	mp_tabnmt_mp=$(echo ${mp_tabnm}|tr '[A-Z]' '[a-z]')
	echo "SELECT MAX(child.relname) AS partition_name">>${sqlplus_script}
	echo "	FROM
				pg_inherits JOIN pg_class parent
			ON pg_inherits.inhparent = parent.oid JOIN pg_class child
			ON pg_inherits.inhrelid = child.oid JOIN pg_namespace nmsp_parent
			ON nmsp_parent.oid = parent.relnamespace JOIN pg_namespace nmsp_child
			ON nmsp_child.oid = child.relnamespace">>${sqlplus_script}
	echo "	WHERE child.relname < '${mp_tabnmt_mp}_p21' AND parent.relname='${mp_tabnmt_mp}';">>${sqlplus_script}
#	echo "exit;">>${sqlplus_script}

if [ ${DEBUG} -eq 1 ];then
	echo "==QUREY MAX PARTITION NAME SQL SCRIPT=========================================="
	cat ${sqlplus_script}
	echo ""
fi

  write_log "INFO" "QUREY MAX PARTITION NAME params are host:[${mp_dburl}],port:[${mp_dbport}],user:[${mp_schema}],password:[***],dbname:[${mp_appid}]"
  ksql "host=${mp_dburl} port=${mp_dbport} user=${mp_schema} password=${mp_dbpwd} dbname=${mp_appid}" -f ${sqlplus_script} >${sqlplus_logfile} 2>&1

	if [ $? -ne 0 ] ;then
		message="Can not access db or Can not write to ${sqlplus_logfile}, qurey max partition_name failed"
		write_log "SERIOUS"
		return 1
		#exit 1
	fi

	get_sqlplus_err
	if [ $? -ne 0 ]; then
		write_log "SERIOUS" "Get max partition_name failed, please check script:${sqlplus_script}"
#		cat ${sqlplus_script} >> /home/mcbadm/incs/err.txt
		return 1
		#exit 1
	fi

	>${sqlplus_script}
	#cat ${sqlplus_logfile}|grep "^${mp_tabnm}_P20"|read mp_cur_lastpname
	cat ${sqlplus_logfile}
	mp_tabnmt_mp=$(echo ${mp_tabnm}|tr '[A-Z]' '[a-z]')
	mp_cur_lastpname=`cat ${sqlplus_logfile}|grep "${mp_tabnmt_mp}_p20"`
	if [ -z "${mp_cur_lastpname}" ]; then
		write_log "ALARM" "The current last partition name is NULL!"	
		if [ "$mp_ptype" = "MONTH" ];then
      Add_Months "$cur_month" "-1" "$mp_schema" "$mp_dbpwd" "$mp_appid"
      mp_cur_lastpname="${mp_tabnm}_P$add_month_val"
		else
      mp_cur_lastpname="${mp_tabnm}_P$(date -d "1 days ago" "+%Y%m%d")"
		fi
	fi

	mp_cur_lastpdate=$(echo ${mp_cur_lastpname}|awk -F'_' '{print $NF}')
	if [ "$mp_ptype" = "MONTH" ];then	
    mp_cur_lastpdate=$(echo ${mp_cur_lastpdate}|cut -c2-7)
	else
    mp_cur_lastpdate=$(echo ${mp_cur_lastpdate}|cut -c2-9)
	fi
	

	DBMSG "mp_cur_lastpname=[${mp_cur_lastpname}] mp_cur_lastpdate=[${mp_cur_lastpdate}]"



  echo "drop table if exists ${mp_tabnm}_plowet;">>${sqlplus_script}
  echo "drop table if exists ${mp_tabnm}_plowert;">>${sqlplus_script}
  echo "drop table if exists ${mp_tabnm}_plowest;">>${sqlplus_script}
  echo "drop table if exists ${mp_tabnm}_default;">>${sqlplus_script}
  #添加特殊分区
  if [ "$mp_ptype" = "DAY" ];then
    DBMSG "Start to create special partition..."
    mp_dt=$(date -d ${mp_lowday}" days ago"  "+%Y%m%d")
    mp_dt2=$(date -d ${mp_dt}" 1 days ago"  "+%Y%m%d")
    DBMSG "mp_dt=[${mp_dt}]"

    echo "CREATE TABLE ${mp_tabnm}_default PARTITION OF ${mp_schema}.${mp_tabnm}">>${sqlplus_script}
    if [ "${mp_vtype}" = "DATE" ]; then
      echo "	FOR VALUES FROM (TO_DATE('20000101','YYYYMMDD')) TO (TO_DATE('${mp_dt2}','YYYYMMDD'))">>${sqlplus_script}
    else
      echo "	FOR VALUES FROM (MINVALUE) TO (${mp_dt2})">>${sqlplus_script}
    fi
    echo "	TABLESPACE ${mp_tsnm};">>${sqlplus_script}
    echo "">>${sqlplus_script}
    
  elif [ "$mp_ptype" = "MONTH" ];then
    DBMSG "cur_month=[${cur_month}]"
    Add_Months "$cur_month" "-$mp_lowday" "$mp_schema" "$mp_dbpwd" "$mp_appid"
    mp_dt=$add_month_val
    Add_Months "$mp_dt" "-1" "$mp_schema" "$mp_dbpwd" "$mp_appid"
    mp_dt2=$add_month_val
    DBMSG "mp_dt=[${mp_dt}]"

    echo "CREATE TABLE ${mp_tabnm}_default PARTITION OF ${mp_schema}.${mp_tabnm}">>${sqlplus_script}
    if [ "${mp_vtype}" = "DATE" ]; then
      echo "	FOR VALUES FROM (TO_DATE('200001','YYYYMM')) TO (TO_DATE('${mp_dt2}','YYYYMM'))">>${sqlplus_script}
    else
      echo "	FOR VALUES FROM (MINVALUE) TO (${mp_dt2})">>${sqlplus_script}
    fi
    echo "	TABLESPACE ${mp_tsnm};">>${sqlplus_script}
    echo "">>${sqlplus_script}

  else
    message="Not implemented."
    write_log "INFO"
  fi




	if [ "$mp_ptype" = "MONTH" ];then
    Add_Months "$mp_cur_lastpdate" "1" "$mp_schema" "$mp_dbpwd" "$mp_appid"
    mp_pstartdate=$add_month_val
    Add_Months "$cur_month" "$mp_advcycles" "$mp_schema" "$mp_dbpwd" "$mp_appid"
    mp_penddate=$add_month_val
	else
    mp_pstartdate=$(date -d ${mp_cur_lastpdate}" 1 days"  "+%Y%m%d")
    mp_penddate=$(date -d ${mp_advcycles}" days"  "+%Y%m%d")
	fi

    DBMSG "mp_pstartdate=[${mp_pstartdate}] mp_penddate=[${mp_penddate}]"

	while [ ${mp_pstartdate} -le ${mp_penddate} ]
	do
		if [ "$mp_ptype" = "DAY_PROV" ]; then
			mp_pmaxval="${mp_pstartdate}"
			for mp_prov in 100 200 210 220 230 240 250 270 280 290 311 351 371 431 451 471 531 551 571 591 731 771 791 851 871 891 898 931 951 971 991
			do
				mp_provmaxval=$(expr ${mp_prov} + 1)
				echo "CREATE TABLE ${mp_tabnm}_P${mp_pstartdate}_${mp_prov} PARTITION OF ${mp_schema}.${mp_tabnm}">>${sqlplus_script}
				message="CREATE TABLE ${mp_tabnm}_P${mp_pstartdate}_${mp_prov} PARTITION OF ${mp_schema}.${mp_tabnm}"
				if [ "${mp_vtype}" = "DATE" ];then
					echo "	FOR VALUES FROM (TO_DATE('${mp_pmaxval}','YYYYMMDD'),${mp_prov}) TO (TO_DATE('${mp_pmaxval}','YYYYMMDD'),${mp_provmaxval})">>${sqlplus_script}
					message="${message} 	FOR VALUES FROM (TO_DATE('${mp_pmaxval}','YYYYMMDD'),${mp_prov}) TO (TO_DATE('${mp_pmaxval}','YYYYMMDD'),${mp_provmaxval})"
				else
					echo "	FOR VALUES FROM (${mp_pmaxval},${mp_prov}) TO (${mp_pmaxval},${mp_provmaxval})">>${sqlplus_script}
					message="${message}	FOR VALUES FROM (${mp_pmaxval},${mp_prov}) TO (${mp_pmaxval},${mp_provmaxval})"
				fi

				if [ "${mp_tstype}" = "0"  ];then
					echo "	TABLESPACE ${mp_tsnm};">>${sqlplus_script}
					message="${message} TABLESPACE ${mp_tsnm};"
				else	
					echo "	TABLESPACE ${mp_tsnm}${mp_prov};">>${sqlplus_script}
					message="${message} TABLESPACE ${mp_tsnm}${mp_prov};"
				fi
				echo "">>${sqlplus_script}
				write_log "INFO"
			done

		elif [ "$mp_ptype" = "DAY_PROV_SUB" ]; then
			mp_pmaxval=$(date -d ${mp_pstartdate}" 1 days"  "+%Y%m%d")
			echo "CREATE TABLE ${mp_tabnm}_P${mp_pstartdate} PARTITION OF ${mp_schema}.${mp_tabnm}">>${sqlplus_script}
			message="CREATE TABLE ${mp_tabnm}_P${mp_pstartdate} PARTITION OF ${mp_schema}.${mp_tabnm}"
			
			#说明:此处写死了PARTITION BY LIST(PROV_CD)，需要通过参数传入这个字段，例如:PROV_CD
			if [ "${mp_vtype}" = "DATE" ]; then
				echo "  FOR VALUES FROM (TO_DATE('${mp_pstartdate}','YYYYMMDD')) TO (TO_DATE('${mp_pmaxval}','YYYYMMDD')) PARTITION BY LIST(PROV_CD)">>${sqlplus_script}
				message="${message} FOR VALUES FROM (TO_DATE('${mp_pstartdate}','YYYYMMDD')) TO (TO_DATE('${mp_pmaxval}','YYYYMMDD')) PARTITION BY LIST(PROV_CD)"
			else
				echo "	FOR VALUES FROM (${mp_pstartdate}) TO (${mp_pmaxval}) PARTITION BY LIST(PROV_CD)">>${sqlplus_script}
				message="${message} FOR VALUES FROM (${mp_pstartdate}) TO (${mp_pmaxval}) PARTITION BY LIST(PROV_CD)"
			fi
			
			echo "	TABLESPACE ${mp_tsnm};">>${sqlplus_script}
			message="${message} TABLESPACE ${mp_tsnm};"
			echo "">>${sqlplus_script}
#				message="${message} ("
			
			for mp_prov in 100 200 210 220 230 240 250 270 280 290 311 351 371 431 451 471 531 551 571 591 731 771 791 851 871 891 898 931 951 971 991
			do
				mp_provmaxval=${mp_prov}
				
				if [ "${mp_tstype}" = "0"  ];then
				    echo " CREATE TABLE ${mp_tabnm}_P${mp_pstartdate}_${mp_prov} PARTITION OF ${mp_schema}.${mp_tabnm}_P${mp_pstartdate} FOR VALUES IN (${mp_prov}) tablespace ${mp_tsnm};">>${sqlplus_script}
				    message="${message} CREATE TABLE ${mp_tabnm}_P${mp_pstartdate}_${mp_prov} PARTITION OF ${mp_schema}.${mp_tabnm}_P${mp_pstartdate} FOR VALUES IN (${mp_prov}) tablespace ${mp_tsnm};"
				else
				    echo " CREATE TABLE ${mp_tabnm}_P${mp_pstartdate}_${mp_prov} PARTITION OF ${mp_schema}.${mp_tabnm}_P${mp_pstartdate} FOR VALUES IN (${mp_prov}) tablespace ${mp_tsnm}${mp_prov};">>${sqlplus_script}
				    message="${message} CREATE TABLE ${mp_tabnm}_P${mp_pstartdate}_${mp_prov} PARTITION OF ${mp_schema}.${mp_tabnm}_P${mp_pstartdate} FOR VALUES IN (${mp_prov}) tablespace ${mp_tsnm}${mp_prov};"
				fi
			done

#			echo " );">>${sqlplus_script}
			echo "">>${sqlplus_script}
#			message="${message}  );"
			write_log "INFO"

		elif [ "$mp_ptype" = "DAY" ];then
			mp_pmaxval=$(date -d ${mp_pstartdate}" 1 days"  "+%Y%m%d")
			echo "CREATE TABLE ${mp_tabnm}_P${mp_pstartdate} PARTITION OF ${mp_schema}.${mp_tabnm}">>${sqlplus_script}
			message="CREATE TABLE ${mp_tabnm}_P${mp_pstartdate} PARTITION OF ${mp_schema}.${mp_tabnm}"
			if [ "${mp_vtype}" = "DATE" ]; then
				echo "	FOR VALUES FROM (TO_DATE('${mp_pstartdate}','YYYYMMDD')) TO (TO_DATE('${mp_pmaxval}','YYYYMMDD'))">>${sqlplus_script}
				message="${message} FOR VALUES FROM (TO_DATE('${mp_pstartdate}','YYYYMMDD')) TO (TO_DATE('${mp_pmaxval}','YYYYMMDD'))"
			else
				echo "	FOR VALUES FROM (${mp_pstartdate}) TO (${mp_pmaxval})">>${sqlplus_script}
				message="${message} FOR VALUES FROM (${mp_pstartdate}) TO (${mp_pmaxval})"
			fi
			echo "	TABLESPACE ${mp_tsnm};">>${sqlplus_script}
			message="${message} TABLESPACE ${mp_tsnm};"
			echo "">>${sqlplus_script}
			write_log "INFO"
			
		elif [ "$mp_ptype" = "MONTH" ];then
		  Add_Months "$mp_pstartdate" "1" "$mp_schema" "$mp_dbpwd" "$mp_appid"
		  mp_pmaxval=$add_month_val
			echo "CREATE TABLE ${mp_tabnm}_P${mp_pstartdate} PARTITION OF ${mp_schema}.${mp_tabnm}">>${sqlplus_script}
			message="CREATE TABLE ${mp_tabnm}_P${mp_pstartdate} PARTITION OF ${mp_schema}.${mp_tabnm}"
			if [ "${mp_vtype}" = "DATE" ]; then
				echo "	FOR VALUES FROM (TO_DATE('${mp_pstartdate}','YYYYMMDD')) TO (TO_DATE('${mp_pmaxval}','YYYYMMDD'))">>${sqlplus_script}
				message="${message} FOR VALUES FROM (TO_DATE('${mp_pstartdate}','YYYYMMDD')) TO (TO_DATE('${mp_pmaxval}','YYYYMMDD'))"
			else
				echo "	FOR VALUES FROM (${mp_pstartdate}) TO (${mp_pmaxval})">>${sqlplus_script}
				message="${message} FOR VALUES FROM (${mp_pstartdate}) TO (${mp_pmaxval})"
			fi
			echo "	TABLESPACE ${mp_tsnm};">>${sqlplus_script}
			message="${message} TABLESPACE ${mp_tsnm};"
			echo "">>${sqlplus_script}
			write_log "INFO"
		else
			message="ptype[${mp_ptype}] is not valid,should be DAY DAY_PROV DAY_PROV_SUB or MONTH, MCB_APPID[${MCB_APPID}] TABLE_NM[${mp_tabnm}] SCHEMA[${mp_schema}]"
			write_log "SERIOUS"
		fi
		
		if [ "$mp_ptype" = "MONTH" ];then
      Add_Months "$mp_pstartdate" "1" "$mp_schema" "$mp_dbpwd" "$mp_appid"
      mp_pstartdate=$add_month_val
		else
      mp_pstartdate=$(date -d ${mp_pstartdate}" 1 days"  "+%Y%m%d")
		fi
	done
#	echo "exit;">>${sqlplus_script}

  if [ ${DEBUG} -eq 1 ];then
    echo "==CREATE NEW PARTITIONS SQL SCRIPT============================================="
    cat ${sqlplus_script}
    echo ""
  fi

  ksql "host=${mp_dburl} port=${mp_dbport} user=${mp_schema} password=${mp_dbpwd} dbname=${mp_appid}" -f ${sqlplus_script} >${sqlplus_logfile} 2>&1

	if [ $? -ne 0 ] ;then
		message="Can not access db or Can not write to ${sqlplus_logfile}, Create partitions failed"
		write_log "SERIOUS"
		return 1
	fi

	get_sqlplus_err
	if [ $? -ne 0 ]; then
#    cat ${sqlplus_script} >> /home/mcbadm/incs/errsqlplus.txt
		write_log "SERIOUS" "Create partitions failed, please check script:${sqlplus_script}"
		return 1
	fi

	return 0
}

function translateAndExecute(){
  while read _appid _pwdurl _ptype _tabnm _tsnm _schema _lowday _advcycles _vtype _tstype _dburl _dbport
  do
    DBMSG "confline:[appid=${_appid} ptype=${_ptype} tabnm=${_tabnm} tsnm=${_tsnm} schema=${_schema} lowday=${_lowday} advcycles=${_advcycles} vtype=${_vtype} dburl=${_dburl} dbport=${_dbport}]"
    check_conf "$_ptype" "$_lowday" "$_advcycles" "$_vtype" "$_tstype"
    if [ $? -ne 0 ]; then
      write_log "SERIOUS" "SERIOUS: check_conf() failed, confline:[${_appid} ${_ptype} ${_tabnm} ${_tsnm} ${_schema} ${_lowday} ${_advcycles} ${_vtype} ${_dburl} ${_dbport}]"
      exit 1
    fi

    _ptype=$(echo "${_ptype}"|tr [:lower:] [:upper:])   #tr [:lower:] [:upper:] 将字符中的小写字母转换成大写字母
    _tabnm=$(echo "${_tabnm}"|tr [:lower:] [:upper:])
    _tsnm=$(echo "${_tsnm}"|tr [:lower:] [:upper:])
    _vtype=$(echo "${_vtype}"|tr [:lower:] [:upper:])
    #_schema=$(echo "${_schema}"|tr [:upper:] [:lower:])
    #_appid=$(echo "${_appid}"|tr [:upper:] [:lower:])

    loadPassowrd "${_schema}" "${_appid}" "${_pwdurl}"
    if [ $? -ne 0 ]; then
      write_log "SERIOUS" "SERIOUS: MaintainPartition() failed]"
      exit 1
    fi

    removePartition "${_ptype}" "${_tabnm}" "${_tsnm}" "${_schema}" "${_lowday}" "${_advcycles}" "${_vtype}" "${_appid}" "${_tstype}" "${_pwdurl}" "${_dburl}" "${_dbport}"
    if [ $? -ne 0 ]; then
      write_log "SERIOUS" "SERIOUS: MaintainPartition() failed]"
#      exit 1
    fi
    
    createPartition "${_ptype}" "${_tabnm}" "${_tsnm}" "${_schema}" "${_lowday}" "${_advcycles}" "${_vtype}" "${_appid}" "${_tstype}" "${_pwdurl}" "${_dburl}" "${_dbport}"
    if [ $? -ne 0 ]; then
      write_log "SERIOUS" "SERIOUS: MaintainPartition() failed]"
#      exit 1
    fi
    
  done
}

function main(){
  #初始化日志文件
  lgInit $logfile "COM" "part_maint_arch" "" "Y"
  if [ $? -ne 0 ]; then
    echo "SERIOUS: Failed to init logfile [${logfile}], please check the logfile"
    exit 1
  fi

  write_log "INFO" "Start at $(date '+%Y-%m-%d %H:%M:%S')"

  #检查环境变量MCB_HOME和MCB_APPID
  if [ -z "${MCB_HOME}" -o -z "${MCB_APPID}" ]; then
    write_log "SERIOUS" "The env MCB_HOME or MCB_APPID is not exist, please check the env"
    exit 1
  fi

  #检测配置文件是否可读
  if [ ! -r "${conffile}" ]; then
    write_log "SERIOUS" "The conffile [${conffile}] is not readable, please check the conffile"
    exit 1
  fi

  if [ ! -f ${MCB_HOME}/${MCB_APPID}/bin/PwdClient ];then
    lgWriteLog SERIOUS "${INST_NAME}" -1 "错误: 获取用户密码程序不存在!---${MCB_HOME}${MCB_APPID}/bin/PwdClient"
    exit 1
  fi

  cat $conffile | grep -v "^#" | translateAndExecute
  
  write_log "INFO" "Process finished at $(date '+%Y-%m-%d %H:%M:%S')"
}


# 加载依赖
. ilogger.sh

# 入口
main
