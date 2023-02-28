#!/bin/bash
nowdt=`date +%m`
sqlplus incsdba/Cmit_incs0@incsm <<EOF
    #关闭显示正在执行的语句 
    set echo off
    #关闭输出信息
    set feedback off
    #限制一行的输出字符个数
    set linesize 500
    #输出每页行数
    set pagesize 500
       
EOF
~