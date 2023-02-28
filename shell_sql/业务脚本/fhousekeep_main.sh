#!/usr/bin/bash
#1.加载变量
PATH=$PATH::/sbin:/usr/bin:/usr/sbin:/etc:/bin:.
export PATH=$PATH:/usr/contrib/bin

MYSELF=fhousekeep.sh

# Set MCB_APPID, This package's name
# This assumes this control script is located under directory 
#                   /etc/cmcluster/$MCB_APPID

# env parameter check
if [ "$MCB_APPID" = "" ];then
    echo "MCB_APPID value is null,please set correct value!!"
    exit 1
fi

CONF=$MCB_HOME/$MCB_APPID/conf/fhousekeep.conf
LOG=$MCB_HOME/$MCB_APPID/var/log/fhousekeep.log
LogFilePath=$MCB_HOME/$MCB_APPID/var/log
LogFile=fhousekeep.log.`date +%y%m%d`

TmpFile=$MCB_HOME/$MCB_APPID/var/tmp/fhousekeep.tmp
if [ -f "$TmpFile" ];then
    rm $TmpFile
fi

#Log message define
HSKP_MSG=00001
HSKP_FILE_ERR=20002
HSKP_DIR_DEFILE_ERR=20003
HSKP_DAY_DEFILE_ERR=20004
HSKP_FILE_WARN=10101

##################Initial log file##############################
#initiate ilogger
. ilogger.sh
lgInit ${LOG} "COM" "Fhousekeep.sh" "" "Y"
if [ "$?" -ne "0" ]; then
    echo "Init log file failed!"
    exit
fi 

Msg="The "$MYSELF" begin!!"
echo "$Msg"
lgWriteLog 1 "" 0 "$HSKP_MSG $MYSELF begin!!"



if [ ! -r $CONF ]
then
    Msg="Can not open config file $CONF !"
    echo "$Msg"
    lgWriteLog 2 "" 1 "$HSKP_FILE_ERR  config $CONF"
    exit 1
fi

grep -v "^#" $CONF | while read dir filePttn days ZipDays mvDir junk
do
    if [ -z "$dir" ];then
        continue
    fi

    if [ ! -d "$dir" ];then
        Msg="Wrong directory $dir defined in $CONF !"
        echo "$Msg"
        lgWriteLog 2 "" 0 "$HSKP_DIR_DEFILE_ERR  $dir $CONF"
        continue
    fi

        #if there is four or three columns,then gzip and clean.
    if [ "$mvDir" = "" ];then
        #ZipDays is valid,then gzip 
        if [ "$ZipDays" != "-" -a "$ZipDays" != "" ];then
            
            if [ $ZipDays -ge $days ];then
                Msg="Wrong zip day and clean day $ZipDays & $days defined in $CONF !"
                echo "$Msg"
                lgWriteLog 2 "" 0 "$HSKP_DAY_DEFILE_ERR $ZipDays & $days $CONF"
                continue
            fi
            
            if [[ "$filePttn" = "-" ]];then
                find $dir -mtime +$ZipDays -type f ! -name "*.gz" |while read line
                do
                    gzip -f $line
                done 
            else
                find $dir -mtime +$ZipDays -type f -name "$filePttn"  ! -name "*.gz" |while read line
                do
                    gzip -f $line
                done 
            fi
            if [ $? -ne 0 ];then
                Msg="Failed to zip files under $dir !"
                echo $Msg
                lgWriteLog 2 "" 0 "$HSKP_FILE_WARN  zip $dir"
            fi
        fi
        
        if [[ "$filePttn" = "-" ]];then
                        #add by xiangjb 2005-8-2;Delete The symbolic Link File And Source File [WT-20050729-172840]
                        find $dir -mtime +$days -type l |while read LINKFILE
                        do
                                rmSymLinkFile 
                        done
            find $dir -mtime +$days -type f -exec rm -f {} \; >>$TmpFile 2>&1
        else
                        find $dir -mtime +$days -type l \( -name "$filePttn" -o -name "${filePttn}.gz" \) |while read LINKFILE
                        do
                                rmSymLinkFile
                        done
            find $dir -mtime +$days -type f \( -name "$filePttn" -o -name "${filePttn}.gz" \) -exec rm -f {} \; >> $TmpFile 2>&1
        fi
        
        if [ $? -ne 0 ];then
            Msg="Failed to delete files under $dir !"
            echo $Msg
            lgWriteLog 2 "" 0 "$HSKP_FILE_WARN delete $dir"
        fi
    #if there is five columns, then mv file to mvDir(col5) 
    else
        if [ ! -d "$mvDir" ];then
        mkdir -p $mvDir
        #Msg="Wrong directory $mvdir defined in $CONF !"
                #echo "$Msg"
                #lgLogFileWrite $HSKP_DIR_DEFINE_ERR "$mvDir" "$CONF"
                #continue
        fi      
        
        cd $dir
        if [ "$filePttn" = "-" ];then
            if [ "$days" = "SIZE" ];then
                (( filesize=1024*1024*$ZipDays ))
                find . -type f -size +${filesize}c |while read line
                do
                    mvToDir_OnTime
                    setCureLine $line  
                done
            else
                find . -mtime +$days -type f |while read line
                do
                    mvToDir
                done
            fi
        else
            if [ "$days" = "SIZE" ];then
                (( filesize=1024*1024*$ZipDays ))
                find . -type f -name "$filePttn" -size +${filesize}c |while read line
                do
                    mvToDir_OnTime
                    setCureLine $line  
                done
            else
                find . -mtime +$days -type f -name "$filePttn" |while read line
                do
                    mvToDir
                done
            fi
        fi  
        if [ $? -ne 0 ];then
            Msg="Failed to mv files to $mvDir !"
            echo $Msg
            lgWriteLog 2 "" 0 "$HSKP_FILE_WARN move $filePttn to  $mvDir"
        fi
    fi  
done

Msg="The "$MYSELF" end!!"
echo "$Msg"
lgWriteLog 1 "" 0 "$HSKP_MSG $Msg"
