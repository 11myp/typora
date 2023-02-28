### 一、IF
#1、判断
#判断变量是否有参数

if [ -n "$1" ]
# 测试是否有命令行参数(非空).
then
  lines=$1
else 
  lines=$LINES # 默认,如果不在命令行中指定.
fi
#判断变量是否为空
if [ ${LINES} ];then  #变量不为空则为真，为空则为假
   echo "SUCESS"
fi



### 二、变量引用
[mcbadm@cmitcsncs-1 /app/mcb/incs/DELETED/maiyp/shell]$ sh test4.sh
1 2 3 4
1 2 3 4
1  2 3     4
$hello
[mcbadm@cmitcsncs-1 /app/mcb/incs/DELETED/maiyp/shell]$ cat test4.sh
#!/bin/bash
hello="1  2 3     4"
echo $hello
echo ${hello}   
echo "$hello"   #双引号会阻止(解释)部分特殊字符
echo '$hello'   #单引号对所有字符做转义，阻止所有特殊字符的解释