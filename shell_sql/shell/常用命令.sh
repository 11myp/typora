#1、统计ftp错误类型的个数
grep ERROR inter-pre-check*2022-01-11 |grep -oE "\bwith replaycode [0-9]{3}\b" |awk '{a[$3]++}END{for (i in a){print i,a[i]}}'
EOOR
#2、统计重复解码的文件个数
grep successfully *rename*20220112 |head |grep  -Po  '\[\K[^]]*'|awk -F'[ |/]' '{a[$NF]++}END{for (i in a){if(a[i]>1){print $0}}}'|head 
#说明： awk -F'[ |/]'：以空格或者/为分隔符

grep successfully *rename*20220112  | grep  -Po  '\[\K[^]]*'|awk -F'[ |/]' '{print$NF}' |sort |uniq -c |awk '{if($1>1){print $0}}'
Vo_ZX_ASN1_931_20220112_00000039



#新增指定uid,gid的用户
groupadd -g 1029 appuser
useradd -u 1029 appuser -g appuser


#pstree -- 查看指定pid的进程树
pstree -p 2 