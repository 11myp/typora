 #########################################################################
#
# File Name: test24.sh
# Author:yangxp
# Mail: 
# Created Time: 2019-04-26 11:21:20
#########################################################################
#!/bin/bash
>dResult.txt

>s1.txt
>s2.txt
>s3.txt
>s4.txt
>s5.txt

time1=`date +%Y%m`
time2=`date -d "-1 month" +%Y%m`

if [[ $1 -ne null ]];then
                time2=$1
fi

#time1用于查询WORKORDER表和UATMIX表
#time2用于查询PROVISION表
cat donecode.txt|while read line
do
	#CO_ID=`echo $line|awk '{print int($0)}'`
	CO_ID=`echo $line`
	PID=`echo $CO_ID|cut -c1-3`
	PI=`echo $CO_ID|cut -c1-2`
	case $PID in
		100|220|240|310|350|370|430|450|470)
		if [[ $PI -eq 31 || $PI -eq 35 || $PI -eq 37 || $PI -eq 43 || $PI -eq 45 || $PI -eq 47 ]];then
				 PID=`echo ''$PI'1'`
		fi
		name=vso1
		passwd=MvnoCrm-123
		db=yyserver1
		dbase=vyydb1
		;;
		210|250|530|550|570)
		if [[ $PI -eq 53 || $PI -eq 55 || $PI -eq 57 ]];then
						PID=`echo ''$PI'1'`
		fi
		name=vso2
		passwd=MvnoCrm-123
		db=yyserver2
		dbase=vyydb2
		;;
		200|590|730|770|790)
		
		if [[ $PI -eq 59 || $PI -eq 73 || $PI -eq 77 || $PI -eq 79 ]];then
						PID=`echo ''$PI'1'`
		fi
		
		name=vso3
		passwd=MvnoCrm-123
		db=yyserver3
		dbase=vyydb3
		;;
		230|270|280|290|850|870|890|930|950|970|990|898)
		if [[ $PI -eq 85 || $PI -eq 87 || $PI -eq 93 || $PI -eq 95 || $PI -eq 97 || $PI -eq 99 ]];then
						PID=`echo ''$PI'1'`
		fi
		name=vso4
		passwd=MvnoCrm-123
		db=yyserver4
		dbase=vyydb4
		;;

    esac
    #T1='I_OPEN_WORKORDER_H_'$PID'_'$time1''
    #T2='I_OPEN_PROVISION_H_'$PID'_'$time2''
	T3='I_OPEN_WORKORDER_'$PID''
    #T4='I_OPEN_UATMIX_H_'$PID'_'$time1''
	T5='I_OPEN_PROVISION_BOSS_'$PID''
	T6='I_BOSS_REPLY_DEPOSITION_'$PID'_err'
	T7='I_BOSS_REPLY_DEPOSITION_'$PID''
	T8='I_OPEN_WORKORDER_'$PID'_ERR'
		
	while (( $time2 <= $time1 ))
	do
        T1='I_OPEN_WORKORDER_H_'$PID'_'$time2''
		time2=`date -d "-1 month ago ${time2}01" +%Y%m`
    	isql -U$name -P$passwd -S$db <<END >dd1.txt
			use $dbase
			go
			select ID from $T1  WHERE CUST_ORDER_ID=$CO_ID
			go
     	END
	
        PS=`sed -n '3p' dd1.txt|grep -oP [0-9].*[0-9]`
        if [ $PS -ne null ];then
            break;
        fi
	done
	
    if [[ $PS -eq null ]];then
		isql -U$name -P$passwd -S$db <<END>dd1.txt
		use $dbase
		go
		select ID from $T3 WHERE CUST_ORDER_ID=$CO_ID
		go
		END
		PS=`sed -n '3p' dd1.txt|grep -oP [0-9].*[0-9]`
    fi
   
    if [[ $PS -eq null ]];then
     	isql -U$name -P$passwd -S$db <<END>dd1.txt
     	use $dbase
     	go
     	select ID from $T8 where CUST_ORDER_ID=$CO_ID
     	go
     	END
        PS=`sed -n '3p' dd1.txt|grep -oP [0-9].*[0-9]`
    fi
   
    PS_ID=\'$PS\'
   
    while (( $time2 <= $time1 ))
    do
		T2='I_OPEN_PROVISION_H_'$PID'_'$time2''
		time2=`date -d "-1 month ago ${time2}01" +%Y%m`
   
     	isql -U$name -P$passwd -S$db <<END>dd1.txt
     	use $dbase
     	go
     	select PS_STATUS from $T2 where PS_ID=$PS
     	go
     	END
   
		STAT=`sed -n '3p' dd1.txt|awk -F ' ' '{print int($0)}'`
		if [[ $STAT -ne 0 ]];then
             break;
		fi
    done
   
   
    isql -U$name -P$passwd -S$db <<END >dd1.txt
		use $dbase
		go
		select count(*) from $T6 where PS_ID=$PS
		go
    END
    flag=`sed -n '3p' dd1.txt|awk -F ' ' '{print int($0)}'`
    TRANS=0
	
	while (( $time2 <= $time1 ))
   #        for date1 in $time1 $time3 $time1
	do
		T4='I_OPEN_UATMIX_H_'$PID'_'$time2''
		time2=`date -d "-1 month ago ${time2}01" +%Y%m`

		isql -U$name -P$passwd -S$db <<END >dd1.txt
		use $dbase
		go
		SELECT TOP 1 I_UATMIX_01+I_UATMIX_02+I_UATMIX_03 FROM $T4 WHERE 1=1
		and OPERATE_OBJECT=$PS_ID
		AND ORG_ID='SYSTEM'
		AND STAFF_ID='SYSTEM'
		order by CREATE_DATE DESC
		go
		END
   
		cp dd1.txt download.txt
		TRANS1=`sed -n '/\<TransIDO\>/,/\<TransIDO\>/p' dd1.txt|head -n1|grep -oP [0-9].*[0-9]`

		isql -U$name -P$passwd -S$db <<END >dd3.txt
		use $dbase
		go
		SELECT TOP 1 rtrim(convert(char,CREATE_DATE,111))+''+(convert(char,CREATE_DATE,108)),I_UATMIX_01+I_UATMIX_02+I_UATMIX_03 FROM $T4 WHERE 1=1
		and OPERATE_OBJECT=$PS_ID
		AND ORG_ID=null
		AND STAFF_ID=null
		order by CREATE_DATE
		go
		END
        #echo $TRANS1
        if [[ $TRANS1 -ne null ]];then
			TRANS=$TRANS1
			cp dd1.txt dd2.txt
			break
        fi
	done
   
   
    #if [[ $STAT -eq 9 ]];then echo $CO_ID,"报竣成功",$TRANS,$PS>>dResult.txt;fi
   
    if [[ $STAT -eq 23 && flag -eq 0  && $2 -eq 1 ]];then 
		isql -U$name -P$passwd -S$db <<END
		use $dbase
		go
		insert into $T5
		select 
		PS_ID,BUSI_CODE,DONE_CODE,EXTERN_ID,PS_TYPE,PRIO_LEVEL,DEAD_LINE,SORT_ID,PS_SERVICE_TYPE,USER_ID,BILL_ID,SUB_BILL_ID,
		PLAN_ID,SUB_VALID_DATE,UPP_CREATE_DATE,CREATE_DATE,START_DATE,END_DATE,RET_DATE,STATUS_UPD_DATE,MON_FLAG,ACTION_ID,
		OLD_PS_PARAM,PS_PARAM,TARGET_PARAM,PS_STATUS,FAIL_NUM,FAIL_REASON,FAIL_CODE,HAND_ID,HAND_OP_ID,HAND_NOTES,RET_OP_ID,
		RET_NOTES,OP_ID,SP_ID,SYS_CODE,PDC_ROUTE_CODE,REGION_CODE,REGION_ID,ORG_ID,STOP_TYPE,OLD_PS_ID,ROLLBACK_FLAG,ASYNC_FLAG,
		ACT_FLAG,PS_NET_CODE,PS_DEVICE_CODE,ACC_ID,SUB_ID,SUB_PASSWD,HAND_DATE,SERVICE_ID,SUB_PLAN_NO,NOTES,RETRY_TIMES,FAIL_LOG,
		ORG_PS_ID,ORDER_DATE,SUSPEND_PS_ID,PS_SERVICE_CODE,SOURCE_ID,PROD_SPEC_ID 
		FROM $T2 WHERE PS_ID=$PS and PS_STATUS in (23)
		go
		END
		sleep 60
		isql -U$name -P$passwd -S$db <<END>dd4.txt
		use $dbase
		go
		select PS_STATUS from $T2 where PS_ID=$PS
		go
		END
			STAT=`sed -n '3p' dd4.txt|awk -F' ' '{print int($0)}'`
	   
		isql -U$name -P$passwd -S$db <<END>dd5.txt
		use $dbase
		go
		SELECT TOP 1 I_UATMIX_01+I_UATMIX_02+I_UATMIX_03 FROM $T4 WHERE 1=1
		and OPERATE_OBJECT=$PS_ID
		AND ORG_ID='SYSTEM'
		AND STAFF_ID='SYSTEM'
		order by CREATE_DATE DESC
		go
		END
			TRANS=`sed -n '/\<TransIDO\>/,/\<TransIDO\>/p' dd5.txt|head -n1|grep -oP [0-9].*[0-9]`
   
		echo "-----------------处理结果---------------------"
            if [[ $STAT -eq 9 ]];then
                     echo $CO_ID,"重下发报竣成功",$TRANS,$PS>>dResult.txt
            elif [[ $STAT -eq 22 ]];then
                     echo $CO_ID,"省侧应答失败请转售商重新发起业务",$TRANS,$PS>>dResult.txt
            elif [[ $STAT -eq -1 ]];then
                     echo $CO_ID,"报竣失败",$TRANS,$PS>>dResult.txt
            else
                     echo $CO_ID,"重下发省侧没有报竣",$TRANS,$PS>>dResult.txt
            fi
             #continue
    fi
   
    if [[ $STAT -eq 23 && flag -ne 0 ]];then 
		 isql -U$name -P$passwd -S$db <<END
		 use $dbase
		 go
		 insert into $T7
		 select PS_ID, USER_ID, OPR_CODE, CREATE_DATE, RSP_CODE, RSP_DESC, XML_BODY, EXT1, EXT2, EXT3, TF_DONE_DATE, REGION_ID, SUCC_TIME 
		 from $T6 where PS_ID=$PS
		 go
		 END
				 sleep 10
		 isql -U$name -P$passwd -S$db <<END>dd1.txt
		 use $dbase
		 go
		 select PS_STATUS from $T2 where PS_ID=$PS
		 go
		 END
             STAT=`sed -n '3p' dd1.txt|awk -F' ' '{print int($0)}'`
             echo "-------------------未报竣处理结果------------------"
            if [[ $STAT -eq 9 ]];then
                    echo $CO_ID,"重处理报竣成功",$TRANS,$PS>>dResult.txt
            else
                    echo $CO_ID,"请自行核查",$TRANS,$PS>>dResult.txt
            fi
             #continue
    fi
   
    T13='I_BOSS_REPLY_DEPOSITION_'$PID'_err'
    isql -U$name -P$passwd -S$db <<END>dd1.txt
    use $dbase
    go
    select err_msg from $T13 where PS_ID=$PS
    go
    END
		msg=`sed -n 3p dd1.txt|cut -c1-80`
		prov_msg=`sed -n '/\<RspCode\>/,/\<RspCode\>/p' dd3.txt|head -n1|cut -c1-80`

		echo "-----------------处理结果---------------------"
   
    if [[ $STAT -eq 23 ]];then 
		echo $CO_ID,"等待报竣",$TRANS,$PS
		echo "省报竣结果："$prov_msg
		echo "沉淀表出错："$msg
    fi
	 
    if [[ $STAT -eq 22 ]];then 
		echo $CO_ID,"省侧应答失败请转售商重新发起业务",$TRANS,$PS
		echo "省报竣结果："$prov_msg
		echo "沉淀表出错："$msg
    fi
	 
    if [[ $STAT -eq -1 ]];then 
		echo $CO_ID,"报竣失败",$TRANS,$PS
		echo "省报竣结果："$prov_msg
		echo "沉淀表出错："$msg
    fi
	 
    if [[ $STAT -eq 0 ]];then 
		 echo $CO_ID,"需要自核",$TRANS,$PS
		 echo "省报竣结果："$prov_msg
		 echo "沉淀表出错："$msg
    fi
	 
	 

done