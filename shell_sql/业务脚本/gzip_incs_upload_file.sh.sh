#!/usr/bin/ksh
#调用方式：
# cat gzip_incs_upload_file.conf  #配置文件内容
# prov_cd=971
# src_path=/opt/mcb/pcs/arch/incs/upload
# work_path=/opt/mcb/pcs/arch/incs/upload/work/
# dst_path=/opt/mcb/pcs/data/incs/outgoing_source
# log_path=/opt/mcb/pcs/var/log
# tar_interval=20
# batch_num=100


function lgWriteLog
{
        log_nowtime=$(date +%Y%m%d%H%M%S)
        log_nowdt=$(date +%Y%m%d)
        echo "BL##${1}#${log_nowtime}#`hostname`#${MCB_APPID}#INT#${module}##${2}#00000000#${3}###msg_cont:${4}##LB">>${log_file}.${log_nowdt}
   return
}

module="gzip_incs_upload_file.sh"
#引用配置文件里的变量
. ${MCB_HOME}/${MCB_APPID}/conf/gzip_incs_upload_file.conf
log_file=${log_path}/gzip_incs_upload_file.log


if [ $# -ne 1 ];then
        LogStr="Error! Usage:gzip_incs_upload_file.sh [gsm|sms]"
        lgWriteLog SERIOUS "main" 1 "$LogStr"
        exit -1
else
        filetype=$1
fi


pid_lock=/opt/mcb/pcs/var/lock/.${module}_${filetype}.lck
if [ -r $pid_lock ];then
    cat $pid_lock | read pid
    kill -0 $pid > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        LogStr="The same program  $pid gzip_incs_upload_file.sh ${filetype} is running now. please retry later!"
        lgWriteLog "INFO" "main" 1 "$LogStr" 
        exit -1
    fi
fi
echo $$>${pid_lock}


while [ 1 ]
do

cd ${src_path}/${filetype}/
ls | grep -v "gz$" | head -n ${batch_num} > ${log_path}/.upload_incs_${filetype}.filelist

count=`cat ${log_path}/.upload_incs_${filetype}.filelist | wc -l`
stock_count=`find ${src_path}/${filetype}/ -type f -mmin +60 | wc -l`
 
if [ $count -lt ${batch_num} ];then
        if [ ${stock_count} -gt 0 ];then
                lgWriteLog "INFO" "main" 1 "start to gzip file!"
        else
                sleep 10;
                continue;
        fi
fi

cat ${log_path}/.upload_incs_${filetype}.filelist | while read fn
do
        gzip ${src_path}/${filetype}/$fn
        if [ $? -eq 0 ];then
                LogStr="gzip $fn success"
                lgWriteLog INFO "main" 1 "$LogStr"
                mv ${src_path}/${filetype}/${fn}.gz ${work_path}/${filetype}/
        else
                LogStr="gzip $fn failed"
                lgWriteLog SERIOUS "main" 1 "$LogStr"
        fi
done

nowtime=$(date +%Y%m%d%H%M%S)
tarfn=${filetype}${nowtime}${prov_cd}.tar
cd ${work_path}/${filetype}/
tar cvf ${dst_path}/.$tarfn *gz
cd ~ 
if [ $? -eq 0 ];then
        LogStr="tar $tarfn success"
        lgWriteLog INFO "main" 1 "$LogStr"
        chmod 775 ${dst_path}/.$tarfn
        mv ${dst_path}/.$tarfn ${dst_path}/$tarfn
        if [ $? -eq 0 ];then
                LogStr="mv $tarfn success"
                lgWriteLog INFO "main" 1 "$LogStr"
                rm ${work_path}/${filetype}/*gz
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