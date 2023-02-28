#!/usr/bin/bash
#
# fhousekeep.sh
#
# COPYRIGHT
# COPYRIGHT Hewlett-Packard Company 1999.
#           All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Hewlett-Packard company 1999.
# The program(s) may be used and/or copied with the written permission
# from and Hewlett-Packard Company 1999 or in accordance with the terms 
# and conditions stipulated in the agreement/contract under which the 
# program(s) have been supplied.
#
# Revision 1.1  1999/12/12  03:24:22  wangyh
# Initial revision
#
# Name: fhousekeep.sh
# Description:
#This scripts is a common shell for house keep file
#It should be installed in /opt/mcb/$MCB_APPID/bin
#
# Set PATH to reference the appropriate directories.
#

setCureLine()
{
        log_file_nm=$1
        log_file_nm=`echo $log_file_nm|sed "s/\.\///`
        tmp_pos=`echo "$log_file_nm" | awk -F. '{print match($1,"_")}'`

        if [ tmp_pos -gt 0 ]; then
           tmp_pos_bef=`expr $tmp_pos - 1`
           tmp_pos_bak=`expr $tmp_pos + 1`
        fi

        tmp_point_pos=`echo "$log_file_nm" | awk '{print match($0,"\.")}'`
        tmp_point_pos_bef=`expr $tmp_point_pos - 1`
        if [ $tmp_pos -gt 0 ]; then
        module_name=`echo $log_file_nm|cut -c1-${tmp_pos_bef}`
        inst_name=`echo $log_file_nm|cut -c${tmp_pos_bak}-${tmp_point_pos_bef}`
        else
        module_name=`echo $log_file_nm|cut -c1-${tmp_point_pos_bef}`
        inst_name="0"
        fi

        path_org=`pwd`
        cd $MCB_HOME/$MCB_APPID/conf
        curline_file_nm=`ls $module_name*log*CurLines`
        if [ $? -ne 0 ]; then
        echo "failed to find curline file name of $log_file_nm" >>$TmpFile
        cd $path_org
        return 0
        fi

        cd $path_org
        _confpath=$MCB_HOME/$MCB_APPID/conf/$curline_file_nm
        changline=`cat $_confpath | grep "$log_file_nm"|grep "_CUR_LINES"`
        if [ $? -ne 0 ]; then
        echo "can not find the _CUR_LINES of $log_file_nm" >>$TmpFile
        return 0
        fi

        _curlinevalue=`echo $changline | awk -F'=' '{print $2}'`
        _newline=`cat $_confpath | grep "$log_file_nm"|grep "_CUR_LINES" | sed "s/$_curlinevalue/0000000000/"`
        _newfilename=$MCB_HOME/$MCB_APPID/conf/setcurline.tmp

        sed "s/$changline/$_newline/g" $_confpath >$_newfilename
        if [ $? -ne 0 ];then
                echo "failed to set curline new value!" >>$TmpFile
                return 0
        fi

        mv -f $_newfilename  $_confpath
        if [ $? -ne 0 ];then
     echo "failed to mv $_newfilename to $_filename" >>$TmpFile
     return 0
  fi
}

mvToDir()
{
    subArchDir=$(dirname $line)
    if [ ! -d "$mvDir/$subArchDir" ];then
        mkdir -p $mvDir/$subArchDir
        if [ $? -ne 0 ];then
            echo "failed to mkdir -p $mvDir/$subArchDir" >> $TmpFile
            return 1
        fi
    fi
    echo "mv $dir/$line to $mvDir/$line,and gzip" >> $TmpFile 
    if [ "${line%.gz}" = "${line}" ];then 
    
        mv -f $dir/$line $mvDir/$line
        if [ $? -ne 0 ];then
            echo "failed to mv $dir/$line $mvDir/$line" >>$TmpFile
            return 1
        fi

        gzip -f $mvDir/$line
        if [ $? -ne 0 ];then
            echo "ALARM:failed to gzip -f $mvDir/$line!!!!!!" >> $TmpFile
            return 1
        fi

    else
        mv -f $dir/$line $mvDir/$line 
        if [ $? -ne 0 ];then
            echo "failed $dir/$line $mvDir/$line!!" >>$TmpFile
            return 1
        fi  
    fi
}

mvToDir_OnTime()
{
    mvTime=`date +%Y%m%d%H%M`  
    subArchDir=$(dirname $line)
    if [ ! -d "$mvDir/$subArchDir" ];then
        mkdir -p $mvDir/$subArchDir
        if [ $? -ne 0 ];then
            echo "failed to mkdir -p $mvDir/$subArchDir" >> $TmpFile
            return 1
        fi
    fi
    
    ######## modified by liuwei 20091021 for KR-20091023-000217 begin ####################
    if [ "${line%.gz}" = "${line}" ];then 
                archFileName=`basename $line`

        #if the last backup logfile (such as:logfilename.yyyymmddHHMM)
        #which have been  moved to arch dir , skip to process it
        if [ `find $mvDir -type f -name "${archFileName}.gz" | wc -l ` -ne 0 ]; then
                        return 0
        fi
        
        if [ `find $subArchDir -mtime -1 -name "$archFileName" |wc -l` -ne 0 ];then
            today_file_flag=1
        else
            today_file_flag=0
        fi

        #if the file is a logfile, then backup this file and move last backup file to arch dir   
                find . -type f -name "*.log*" | grep "$archFileName" | while read logFileName
                do
                        if [ "$line" = "$logFileName" ];then

                                #move last backup logfile to arch dir
                                echo $archFileName | awk -F. '{print $NF}' | wc -c | read charlen
                                if [ $charlen -eq 13 ];then
                                        return 0
                                else
                                        find . -type f -name "${archFileName}.*" | while read lastLogFile
                                        do

                                                if [ "${lastLogFile}X" != "X" ];then
                                                    echo "mv large $dir/$lastLogFile to $mvDir/$lastLogFile, and gzip" >> $TmpFile 
                                                mv -f $dir/$lastLogFile $mvDir/$lastLogFile
                                                if [ $? -ne 0 ];then
                                                    echo "ALARM:Failed to mv -f $dir/$lastLogFile $mvDir/$lastLogFile" >> $TmpFile
                                                    return 1
                                                fi

                                                gzip -f $mvDir/$lastLogFile
                                                if [ $? -ne 0 ];then
                                                    echo "ALARM:failed to gzip -f $mvDir/$lastLogFile!!!!!!" >> $TmpFile
                                                    return 1
                                                fi                                      
                                                fi
                                        done

                                fi

                                #backup the file as logfilename.yyyymmddHHMM
                                echo "mv large $dir/$line to $dir/$line.$mvTime" >> $TmpFile 
                                mv -f $dir/$line $dir/$line.$mvTime
                                if [ $? -ne 0 ];then
                                        echo "failed to mv $dir/$line $dir/$line.$mvTime" >>$TmpFile
                                        return 1
                                fi

                        if [ $today_file_flag = 1 ];then
                            touch $dir/$line
                            if [ $? -ne 0 ];then
                                echo "failed to touch $dir/$line" >>$TmpFile
                                return 1
                            fi
                        fi
                        return 0
                fi
                done

        echo "mv large $dir/$line to $mvDir/$line.$mvTime, and gzip" >> $TmpFile 
        mv -f $dir/$line $mvDir/$line.$mvTime
        if [ $? -ne 0 ];then
            echo "ALARM:Failed to mv -f $dir/$line $mvDir/$line.$mvTime" >> $TmpFile
            return 1
        fi
        
        if [ $today_file_flag = 1 ];then
            touch $dir/$line
            if [ $? -ne 0 ];then
                echo "failed to touch $dir/$line" >>$TmpFile
                return 1
            fi
        fi

        gzip -f $mvDir/$line.$mvTime
        if [ $? -ne 0 ];then
            echo "ALARM:failed to gzip -f $mvDir/$line.$mvTime!!!!!!" >> $TmpFile
            return 1
        fi
            
    else
        echo "mv large $dir/$line to $mvDir/$line.$mvTime, and gzip" >> $TmpFile 
        mv -f $dir/$line $mvDir/${line%.gz}.$mvTime.gz 
        if [ $? -ne 0 ];then
            echo "failed $dir/$line $mvDir/${line%.gz}.$mvTime.gz!!" >>$TmpFile
            return 1
        fi  
    fi
    ########## modified by liuwei 20091021 for KR-20091023-000217 end ###################
    
}
rmSymLinkFile()
{
        SRCFILE=`ls -l $LINKFILE|awk {'print $11'}`
        rm -f $LINKFILE
        rm -f $SRCFILE
}

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
HSKP_DIR_DEFINE_ERR=20003
HSKP_DAY_DEFINE_ERR=20004
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
