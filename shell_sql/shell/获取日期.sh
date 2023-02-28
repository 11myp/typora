#!/bin/bash
#!/usr/bin/env bash
start_date="20210301"
end_date="20211101"
while [ "$start_date" -le "$end_date" ];
do
  stat_date=`date -d "$start_date" +%Y-%m-%d`
  echo $stat_date
  start_date=$(date -d "$start_date+1days" +%Y%m%d)
done
