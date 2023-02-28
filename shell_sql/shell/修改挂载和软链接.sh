修改10.253.116.181、10.253.116.182挂载和软链接


原始挂载信息：
hohhot-dfs11.cmcc.cn:/share-6083e774-259c-42e1-8d3b-caf46bf37e29  2.0T  839G  1.2T  41% /app/wj_int
hohhot-dfs11.cmcc.cn:/share-bdc35d35-ab93-456f-92d8-99ca43ede2ff   15T  8.9T  6.2T  60% /app/wj_int2
原始链接：
lrwxrwxrwx 1 mcbadm mcbadm    12 Oct 13  2021 nfs -> /app/wj_int2
lrwxrwxrwx 1 mcbadm mcbadm    11 Oct 13  2021 nfs_ext -> /app/wj_int

1、
umount /app/wj_int2
umount /app/wj_int


2、修改目录名字：
mv /app/wj_int2  /app/wj_ext

3、重新挂载：
mount -t nfs -o rw  hohhot-dfs11.cmcc.cn:/share-bdc35d35-ab93-456f-92d8-99ca43ede2ff  /app/wj_int
mount -t nfs -o rw  hohhot-dfs11.cmcc.cn:/share-6083e774-259c-42e1-8d3b-caf46bf37e29  /app/wj_ext



4、并修改软链接
改为：
nfs -> /app/wj_int
nfs_ext -> /app/wj_ext


修改之后的效果:
hohhot-dfs11.cmcc.cn:/share-bdc35d35-ab93-456f-92d8-99ca43ede2ff   15T  8.9T  6.2T  60% /app/wj_int
hohhot-dfs11.cmcc.cn:/share-6083e774-259c-42e1-8d3b-caf46bf37e29  2.0T  839G  1.2T  41% /app/wj_ext