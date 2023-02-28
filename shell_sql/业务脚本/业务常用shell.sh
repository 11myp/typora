#统计某模块的平均处理时长
grep 处理成功 inter-pre-sorting-inst1.log.2021-07-16 |grep "2021-07-16 00:" |awk '{print $(NF-1)}' |awk -F',' 'BEGIN{
    file_count=0
    user_time_sum=0
}
{
    user_time=$3/1000
    user_time_sum=user_time+user_time_sum;
    file_count++;
}
END{
    print "file_count="file_count" avg="user_time_sum/file_count
}'


#统计校验模块的平均处理时长
cat inter*check*.2021-07-24|grep "Voice:/app"|awk '{gsub(/DECODE.*/,"DECODE");print $0}'|awk '{
y1=substr($1,1,4); 
m1=substr($1,6,2); 
d1=substr($1,9,2);
h1=substr($2,1,2);
M1=substr($2,4,2);
s1=substr($2,7,2);
time1 = strftime("%s",mktime(y1" "m1" "d1" "h1" "M1" "s1));
file_arr[$7]=time1-file_arr[$7];
file_flag[$7]++;
}
END{
        file_cnt=0;
                use_time_sum=0;
                for(file in file_arr)
                {
                        if(file_flag[file]==2 && file_arr[file] > 0)
                        {
                        file_cnt++;
                        use_time_sum=use_time_sum+file_arr[file];
                        }
                }
                print "file_count="file_cnt"  avg="use_time_sum/file_cnt;
}' 


#统计系统吞吐量（TPS）
select 'incss1'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss1 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%'
union 
select 'incss2'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss2 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%'
union 
select 'incss3'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss3 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%'
union 
select 'incss4'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss4 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%'
union 
select 'incss5'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss5 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%'
union 
select 'incss6'||'|'||sum(cdr_count_all) from incsdba.process_state_cdr_file@public.incss6 where process_dt = 20220920 and prcss_tm like '2022-09-20 14:%' 
