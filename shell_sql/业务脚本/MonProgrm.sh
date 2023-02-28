#!/bin/bash
#author:maiyp(copy from others)
#date:2021-08-10
#Dictionary:monitor the process。
#myself:MonProgrm.sh
#conf: FileDecode inst1 30 

####初始化函数
init() {
  . ilogger.sh
  lgInit "$MCB_HOME/$MCB_APPID/var/log/mon_incs.log" "COM" "MonProgrm.sh" "" N
  if [ "$?" -ne "0" ]; then
    echo "Init log file failed!"
    exit 1
  fi
  lgWriteLog INFO "init" 1 "init log file of MonProgrm.sh is success."
}

####启动程序
startProgram() {
  _CMD=$1
  _inst=$2
  _tmpfile=$MCB_HOME/$MCB_APPID/var/tmp/MonProgrm.tmp

  # 进程不存在，启动
  ps -ef | grep  "$_CMD" | grep "$_inst"  >$_tmpfile
  _cnt=$(cat $_tmpfile | wc -l)
 
  if [ ${_cnt} -eq 0 ]; then
    #cd /$MCB_HOME/$MCB_APPID/bin/
    #nohup ${_CMD} ${_inst} &
    re_cmd=`crontab  -l |grep ${_CMD} |grep ${_inst} |grep -v '^#' |awk -F'/app/mcb/incs/bin/mcb_cronjob.sh' '{print "/app/mcb/incs/bin/mcb_cronjob.sh",$2}'`
    echo ${re_cmd}
    #nohup ${re_cmd} &
    ret=$?
    if [ "$ret" -ne "0" ]; then
      lgWriteLog SERIOUS "startProgram" 1 "启动程序: $MCB_HOME/$MCB_APPID/bin/${_CMD} ${_inst} 失败！"
      return 0
    else
      lgWriteLog INFO "startProgram" 1 "启动程序: $MCB_HOME/$MCB_APPID/bin/${_CMD} ${_inst} 成功！"
      return 0
    fi
  fi
}

####检测程序
checkProgram() {
  _CMD=$1
  _inst=$2
  _times=$3
  _logfile=${_CMD}_${_inst}.log
  _flagfile=$MCB_HOME/$MCB_APPID/var/tmp/dt_incs.tmp
  _tmpfile=$MCB_HOME/$MCB_APPID/var/tmp/MonProgrmCheckIncs.tmp
  #获取30分钟前的时间
  _tmp=$(getAnyTime -m -${_times} | awk '{print substr($0,1,12)}')
  touch -t $_tmp $_flagfile

  _curlogfile=$(ls -1 $MCB_HOME/$MCB_APPID/var/log/${_logfile}* | tail -1)
  if [ "X" = "X"${_curlogfile} ]; then
    lgWriteLog SERIOUS "startProgram" 1 "日志${_logfile}不存在，请检查！"
    return 0
  fi

  if [ $_flagfile -nt $_curlogfile ]; then
    lgWriteLog SERIOUS "startProgram" 1 "${_CMD}程序的日志${_curlogfile}已经${_times}分钟没更新，可能僵死！"
    ps -ef |grep ${_CMD}|grep ${_inst} | awk '{print $2}' | xargs kill -9
    #if [ $? -ne 0 ];then
    #  lgWriteLog SERIOUS "startProgram" 1 "MonProgrm无法重启${_CMD},请核查！"
    #  exit 1
    #fi  
    sleep 3
    startProgram ${_CMD} ${_inst}
  fi
}

####处理逻辑
monProgram() {
  conf_file=$MCB_HOME/$MCB_APPID/conf/MonProgrm.conf
  if [ ! -f ${conf_file} ]; then
    lgWriteLog INFO "monProgram" 1 "conf file [${conf_file}] not exist,exit!"
    exit 1
  fi

  cat $conf_file | while read _CMD _inst _times ; do
    checkProgram  $_CMD $_inst $_times
  done
}

# main
if [ $# -ne 0 ]; then
  echo "usage:$0 "
  exit -1
fi
init
monProgram