#!/usr/bin/ksh
############################################################
#@FileName incs_cdr_file_rename_sms.sh
#@Author   liuyf
#@Date     2018-03-26
#@Desc     rename cdr file name
#@Conf     incs_cdr_file_rename_${inst}.conf
#@Usage    incs_cdr_file_rename_sms.sh inst1
# ##########################################################

chk_in_file() {
    _src_file=$1
    _in_file_pattern=$2

    echo "${_in_file_pattern}" | awk -F"|" '{for(i=1;i<=NF;i++){print $i;}}' | grep -v ^$ | while read v_in_file_pattern; do
        echo "$_src_file" | grep -E "${v_in_file_pattern}"
        if [ $? -eq 0 ]; then
            return 0
        fi
    done
    return 1
}

################main #####################
if [ $# -ne 1 ]; then
    echo "Usage: $0 g_instance"
    exit 1
fi

PROC_NAME=$(basename $0)
g_instance=$1
module=incs_cdr_file_rename
PIDLock=/opt/mcb/${MCB_APPID}/var/tmp/.${module}_${g_instance}.lck

curpid=$$

# 20161012 yangzw. Add while loop to avoid get proc_id wrong.
ps_index=0
while [ $ps_index -le 3 ]; do
    if [ -r $PIDLock ]; then
        cat $PIDLock | read pid
        kill -0 $pid >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            Proc_id=$(ps -ef | grep $PROC_NAME | grep $g_instance | grep -v $curpid | grep -v grep | grep -v mcb_cronjob | awk '{print $2}')
            for pre_pid in $Proc_id; do
                if [ $pid -eq $pre_pid ]; then
                    echo "The same program ${module} ${g_instance} is running now."
                    exit 1
                fi
            done
        fi
    fi
    ps_index=$(($ps_index + 1))
    sleep 1
done

echo $$ >$PIDLock

. ilogger.sh
. cfConfigFile.sh

module=incs_cdr_file_rename
conf_file=${MCB_HOME}/${MCB_APPID}/conf/${module}_${g_instance}.conf
g_tag_file=${MCB_HOME}/${MCB_APPID}/conf/.${module}_${g_instance}.tag

if [ ! -f ${conf_file} ]; then
    echo "conf file [${conf_file}] not exist,exit!"
    exit 1
fi

cfInit ${conf_file} noLock readOnly

log_file=$(cfGetConfigItem common log_file)
guard_time=$(cfGetConfigItem common guard_time)
list_file=$(cfGetConfigItem common list_file)
src_dir=$(cfGetConfigItem common src_dir)
iw_dest_dir=$(cfGetConfigItem common iw_dest_dir)
tj_dest_dir=$(cfGetConfigItem common tj_dest_dir)
arch_dir=$(cfGetConfigItem common arch_dir)
file_pattern=$(cfGetConfigItem common file_pattern)
file_prefix=$(cfGetConfigItem common file_prefix)
prov_cd=$(cfGetConfigItem common prov_cd)
sleep_second=$(cfGetConfigItem common sleep_second)
seq_len=$(cfGetConfigItem common seq_len)
in_file_pattern=$(cfGetConfigItem common in_file_pattern)

if [ -z "${log_file}" ]; then
    "echo [log_file] not exist!"
fi
lgInit ${log_file} "COM" "${module}" "${g_instance}" "Y"
lgWriteLog INFO "" 0 "${module}.sh ${g_instance} start!"

if [ -z "${guard_time}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [guard_time] not set!"
    exit 1
fi
if [ -z "${sleep_second}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [sleep_second] not set!"
    exit 1
fi
if [ -z "${seq_len}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [seq_len] not set!"
    exit 1
fi
if [ -z "${file_prefix}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [file_prefix] not set!"
    exit 1
fi
if [ -z "${file_pattern}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [file_pattern] not set!"
    exit 1
fi
if [ -z "${in_file_pattern}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [in_file_pattern] not set!"
    exit 1
fi
if [ -z "${prov_cd}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [prov_cd] not set!"
    exit 1
fi
if [ -z "${src_dir}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [src_dir] not set!"
    exit 1
fi
if [ ! -d "${src_dir}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [src_dir] is not correct!"
    exit 1
fi
if [ -z "${iw_dest_dir}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [iw_dest_dir] not set!"
    exit 1
fi
if [ ! -d "${iw_dest_dir}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [iw_dest_dir] is not correct!"
    exit 1
fi

if [ -z "${arch_dir}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [arch_dir] not set!"
    exit 1
fi
if [ ! -d "${arch_dir}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [arch_dir] is not correct!"
    exit 1
fi
if [ -z "${list_file}" ]; then
    lgWriteLog SERIOUS "main" -1 "in [common], [list_file] not set!"
    exit 1
fi

proc_dt=$(date '+%Y%m%d')
file_number=0
list_file_by_day=${list_file}.${proc_dt}
if [ -f $list_file_by_day ]; then
    file_number=$(wc -l ${list_file_by_day} | awk '{print $1}')
fi

while [ 1 -eq 1 ]; do
    tag_time=$(getAnyTime -m -${guard_time} | cut -c 1-12)
    touch -t ${tag_time} ${g_tag_file}

    echo "find ${src_dir} -type f -name ${file_pattern} ! -newer ${g_tag_file} | sort"
    find ${src_dir} -type f -name "${file_pattern}" ! -newer ${g_tag_file} | sort | while read path_file; do
        src_file=$(basename ${path_file})
        lgSetProcFileName "${src_file}"

        chk_result=$(chk_in_file "$src_file" "${in_file_pattern}")
        if [ "$chk_result" = "$src_file" ]; then

            cp -p ${path_file} ${arch_dir}/
            if [ $? -ne 0 ]; then
                lgWriteLog SERIOUS "cp File" -1 "file [${src_file} cp to ${arch_dir}/] rename failed!"
                exit 3
            fi

            echo "aaaaaaaaaaaaaaa ${path_file}"
            string_file_number=$(printf "%0${seq_len}d" $file_number)
            #取原始文件名前8位字符
            ori_string=`echo ${path_file:0:8}`
            if [[ ${path_file} == *IWMGA* ]]; then
                echo "bbbbbbbbbbbbbbbb ${path_file}"
                mv ${path_file} ${iw_dest_dir}/${file_prefix}_${prov_cd}_${ori_string}_${proc_dt}_${string_file_number}
                if [ $? -eq 0 ]; then
                    echo "${path_file} ${iw_dest_dir}/${file_prefix}_${prov_cd}_${ori_string}_${proc_dt}_${string_file_number}" >>${list_file_by_day}
                    file_number=$(expr ${file_number} + 1)
                    lgWriteLog SUCC "Rename File" 0 "file [${src_file} rename to ${iw_dest_dir}/${file_prefix}_${prov_cd}_${ori_string}_${proc_dt}_${string_file_number}] re ame successfully!"
                else
                    lgWriteLog SERIOUS "Rename File" -1 "file [${src_file} rename to ${iw_dest_dir}/${file_prefix}_${prov_cd}_${ori_string}_${proc_dt}_${string_file_number}] rename failed!"
                    exit 2
                fi
            elif [[ ${path_file} == *TJIS* ]]; then
                mv ${path_file} ${tj_dest_dir}/${file_prefix}_${prov_cd}_${ori_string}_${proc_dt}_${string_file_number}
                if [ $? -eq 0 ]; then
                    echo "${path_file} ${iw_dest_dir}/${file_prefix}_${prov_cd}_${ori_string}_${proc_dt}_${string_file_number}" >>${list_file_by_day}
                    file_number=$(expr ${file_number} + 1)
                    lgWriteLog SUCC "Rename File" 0 "file [${src_file} rename to ${tj_dest_dir}/${file_prefix}_${prov_cd}_${ori_string}_${proc_dt}_${string_file_number}] re ame successfully!"
                else
                    lgWriteLog SERIOUS "Rename File" -1 "file [${src_file} rename to ${tj_dest_dir}/${file_prefix}_${prov_cd}_${ori_string}_${proc_dt}_${string_file_number}] rename failed!"
                    exit 2
                fi
            fi
        else
            lgWriteLog ALARM "skip File" -1 "file [${src_file} is not in-file!mv to ${arch_dir}/${src_file}.unknown"
            mv ${path_file} ${arch_dir}/${src_file}.unknown
        fi
        lgClrProcFileName
    done
    sleep $sleep_second
    proc_dt_tmp=$(date '+%Y%m%d')
    if [ $proc_dt_tmp -ne $proc_dt ]; then
        file_number=0
        proc_dt=$proc_dt_tmp
        list_file_by_day=${list_file}.${proc_dt}
    fi
done

lgWriteLog INFO "main" 0 "the program end"

# 20161012 yangzw. Only pid itself can delete the PIDLock file
lock_pid=$(cat $PIDLock)
if [ $lock_pid -eq $$ ]; then
    rm -f ${PIDLock}
fi
#end of file
