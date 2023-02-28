#!/bin/bash


####初始化函数
init()
{
                . ilogger.sh
                lgInit "$MCB_HOME/$MCB_APPID/var/log/monftpTransfer.log" "COM" "ftpTransfer.sh" "" N   
    if [ "$?" -ne "0" ]; then
      echo "Init log file failed!"
     exit 1
    fi          
                        
                lgWriteLog INFO "init" 1  "ftpTransfer.sh init ok."
}

####启动程序
startftpTransfer()
{
    
    _inst=$1 
    _CMD=ftpTransfer.sh
    _tmpfile=$MCB_HOME/$MCB_APPID/var/tmp/monftpTransfertart.tmp
   
    # 进程不存在，启动
    ps -ef |grep -E "$_CMD" |grep -E "$_inst" |grep -v grep |awk '{print $2}' > $_tmpfile
    _cnt=`cat $_tmpfile |wc -l`
    
                if [ ${_cnt} -eq 0 ];then
            cd  /$MCB_HOME/$MCB_APPID/bin/
                    nohup  ${_CMD} ${_inst} &
                                ret=$?

                                if [ "$ret" -ne "0" ]; then
                                  lgWriteLog SERIOUS "startftpTransfer" 1  "启动程序: $MCB_HOME/$MCB_APPID/bin/${_CMD} ${_inst} 失败！"  
                                  return 0
                                else
                                        lgWriteLog INFO "startftpTransfer" 1  "启动程序: $MCB_HOME/$MCB_APPID/bin/${_CMD} ${_inst} 成功！"    
                          return 0
                                fi
    fi
   
}


####检测程序
checkftpTransfer()
{
    
    _inst=$1 
    _times=$2
    _logfile=ftpTransfer_${_inst}_incs.log
    _flagfile=$MCB_HOME/$MCB_APPID/var/tmp/dt.tmp
    _tmpfile=$MCB_HOME/$MCB_APPID/var/tmp/monftpTransferCheck_incs.tmp

    _tmp=`getAnyTime -m -${_times} |awk '{print substr($0,1,12)}'`
    touch -t $_tmp $_flagfile

                _curlogfile=`ls -1 $MCB_HOME/$MCB_APPID/var/log/${_logfile}* |tail -1`
                if [ "X" = "X"${_curlogfile} ];then
                  lgWriteLog SERIOUS "startftpTransfer" 1  "日志${_logfile}不存在，请检查！"
                  return 0 
                fi



    find $MCB_HOME/$MCB_APPID/var/log -newer $_flagfile |grep $_curlogfile >$_tmpfile
    _cnt=`cat $_tmpfile |wc -l`

                if [ ${_cnt} -eq 0 ];then  
                  lgWriteLog SERIOUS "startftpTransfer" 1  "ftpTransfer程序的日志${_curlogfile}已经${_times}分钟没更新，可能僵死！"
                  ps -ef | grep -E ftpTransfer | grep -E ${_inst} | awk '{print $2}' | xargs kill
                  sleep 3
                  startftpTransfer  ${_inst}
                fi

}



####处理逻辑
monftpTransfer_proc()
{
    conf_file=$MCB_HOME/$MCB_APPID/conf/monftpTransfer.conf
        if [ ! -f ${conf_file} ];then
            lgWriteLog INFO "monftpTransfer_proc" 1  "conf file [${conf_file}] not exist,exit!"
            exit 1
        fi

  cat $conf_file |while read _inst _times
  do 
     checkftpTransfer  $_inst $_times
  done
        

}


# main
if [ $# -ne 0  ];then
    echo "usage:$0 "
    exit -1
fi

init
monftpTransfer_proc