#!/usr/bin/ksh

function lgWriteLog
{
        log_nowtime=$(date +%Y%m%d%H%M%S)
        log_nowdt=$(date +%Y%m%d)
        echo "BL##${1}#${log_nowtime}#`hostname`#${MCB_APPID}#INT#${module}##${2}#00000000#${3}###msg_cont:${4}##LB">>${log_file}.${log_nowdt}
   return
}

module="incs_upload_file.sh"
. ${MCB_HOME}/${MCB_APPID}/conf/incs_upload_file.conf
log_file=${log_path}/incs_upload_file.log


if [ $# -ne 1 ];then
        LogStr="Error! Usage:incs_upload_file.sh [gsm|sms]"
        lgWriteLog SERIOUS "main" 1 "$LogStr"
        exit -1
else
        filetype=$1
fi


pid_lock=/opt/mcb/pcs/var/lock/.${module}_${filetype}.lck
if [ -r $pid_lock ];then
    #cat $pid_lock | read pid
    pid=`cat $pid_lock`
    kill -0 $pid > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        LogStr="The same program  $pid incs_upload_file.sh ${filetype} is running now. please retry later!"
        lgWriteLog "INFO" "main" 1 "$LogStr" 
        exit -1
    fi
fi
echo $$>${pid_lock}


while [ 1 ]
do

cd ${src_path}/${filetype}/
ls | head -n ${batch_num} > ${log_path}/.upload_incs_${filetype}.filelist

count=`cat ${log_path}/.upload_incs_${filetype}.filelist | wc -l`
stock_count=`find ${src_path}/${filetype}/ -type f -mmin +60 | wc -l`
 
if [ $count -lt ${batch_num} ];then
        if [ ${stock_count} -gt 0 ];then
                lgWriteLog "INFO" "main" 1 "start to mv file!"
        else
                sleep 10;
                continue;
        fi
fi

cat ${log_path}/.upload_incs_${filetype}.filelist | while read fn
do
        mv ${src_path}/${filetype}/${fn} ${work_path}/${filetype}/
done

nowtime=$(date +%Y%m%d%H%M%S)
tarfn=${filetype}${nowtime}${prov_cd}.tar
cd ${work_path}/${filetype}/
tar cvf ${dst_path}/.$tarfn *
cd ~ 
if [ $? -eq 0 ];then
        LogStr="tar $tarfn success"
        lgWriteLog INFO "main" 1 "$LogStr"
        chmod 775 ${dst_path}/.$tarfn
        mv ${dst_path}/.$tarfn ${dst_path}/$tarfn
        if [ $? -eq 0 ];then
                LogStr="mv $tarfn success"
                lgWriteLog INFO "main" 1 "$LogStr"
                rm ${work_path}/${filetype}/*
        else
                LogStr="mv $tarfn failed"
                lgWriteLog SERIOUS "main" 1 "$LogStr"
        fi
else
        LogStr="tar $tarfn failed"
        lgWriteLog SERIOUS "main" 1 "$LogStr"
fi

sleep ${tar_interval} 
done