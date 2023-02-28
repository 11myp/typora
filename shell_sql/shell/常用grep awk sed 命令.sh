#常用grep awk sed 命令
#1、提取[]括号中的内容
cat test.txt |  grep  -Po  '\[\K[^]]*'


\[ 匹配左方括号
\K是一个断言
[^]]  匹配非右括号的所有字符
[^]]*  匹配零个或者多个非右括号的所有字符


#2、sed awk 中使用变量
使用变量要用""

#3、awk指定输出拼接分隔符
awk -v OFS='|'


#4、grep使用单词边界
#过滤表名：MCBDBA.ACCESS_NUMBER_351   -o:只输出匹配到的字段
#字段2023-01-11 10:32:51,140 [get-db-to-redis-2] INFO  c.c.i.p.p.d.i.DomLdAreaCdProvDaoImpl - 加载公参内容，rediskey:MCBDBA.ACCESS_NUMBER_371,数据大小是:61
grep -oE '\bMCBDBA.\w+\b' inter-pre-param-pre-param-*2023-01-11 |sort |uniq 

#5、awk统计某个字段次数
awk '{a[$7]++}END{for( i in a )print i,a[i]}'

#6、去掉文件名中的xxx后缀 Vo20220930180938220.tar.DUP  → Vo20220930180938220.tar
find ./ -name "*.tar.DUP" |awk -F'./' '{print $2}' |awk -F'.' '{print $1}'|xargs -i mv {}.tar.DUP {}.tar

#sed注释文本中匹配到某个字符串的行
sed -ri 's/.*swap.*/#&/' /etc/fstab

