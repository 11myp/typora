## linux 系统CPU核数，个数和使用率分析

#### CPU个数，核数计算

在linux操作系统中，CPU的信息在启动的过程中被装载到虚拟目录/proc下的cpuinfo文件中。一次记录的完整内容如下所示。

> cat /proc/cpuinfo
>
> processor       : 0
> vendor_id       : GenuineIntel
> cpu family      : 6
> model           : 79
> model name      : Intel(R) Xeon(R) CPU E5-2650 v4 @ 2.20GHz
> stepping        : 1
> microcode       : 0xb00002a
> cpu MHz         : 2200.000
> cache size      : 30720 KB
> physical id     : 0
> siblings        : 24
> core id         : 0
> cpu cores       : 12
> apicid          : 0
> initial apicid  : 0
> fpu             : yes
> fpu_exception   : yes
> cpuid level     : 20
> wp              : yes
> flags           : xxxx
> bogomips        : 4399.91
> clflush size    : 64
> cache_alignment : 64
> address sizes   : 46 bits physical, 48 bits virtual
> power management:

- 比较重要的几个参数


```shell
processor  :0      #系统中逻辑处理核的编号。单核CPU，可认为是CPU的编号。多核CPU则可以是物理核、或者使用超线程技术虚拟的逻辑核
physical id  : 0   #单个CPU的编号
siblings     : 24  # 单个CPU逻辑物理核数
cpu cores    ：12   #该逻辑核所处CPU的物理核数
```

-  /proc/cpuinfo文件记录的是每个逻辑CPU的信息，使用lscpu命令可查看系统的CPU的统计信息

  > Architecture:          x86_64    #架构
  > CPU op-mode(s):        32-bit, 64-bit
  > Byte Order:            Little Endian
  > CPU(s):                160   #CPU总数
  > On-line CPU(s) list:   0-159   #在线的CPU，某些情况下某些CPU可以停止工作
  > Thread(s) per core:    2       #每个CPU核心线程数
  > Core(s) per socket:    20    #CPU核数
  > Socket(s):             4          #物理CPU数量
  > NUMA node(s):          4
  > Vendor ID:             GenuineIntel
  > CPU family:            6
  > Model:                 85
  > Model name:            Intel(R) Xeon(R) Gold 6148 CPU @ 2.40GHz
  > Stepping:              4
  > CPU MHz:               1000.000
  > CPU max MHz:           2401.0000
  > CPU min MHz:           1000.0000
  > BogoMIPS:              4800.00
  > Virtualization:        VT-x
  > L1d cache:             32K
  > L1i cache:             32K
  > L2 cache:              1024K
  > L3 cache:              28160K
  > NUMA node0 CPU(s):     0-19,80-99
  > NUMA node1 CPU(s):     20-39,100-119
  > NUMA node2 CPU(s):     40-59,120-139
  > NUMA node3 CPU(s):     60-79,140-159
  > Flags:             xxx....

- 总逻辑CPU数 = 物理CPU个数 * 每颗物理CPU的核数 * 超线程数。如果cpu cores数量和siblings数量一致，则没有启用超线程，否则超线程被启用。

1. 逻辑CPU总数。

   ```shell
   [maiyp@pod1 ~] grep -c 'processor' /proc/cpuinfo
   48
   ```

2. 物理CPU个数

   ```shell
   [maiyp@pod1 ~]$ cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l
   2
   ```

3. CPU核数

   ```shell
   [maiyp@pod1 ~]$cat /proc/cpuinfo| grep "cpu cores"| uniq
   cpu cores       : 12
   ```

   

   #### 使用top分析CPU使用情况

   > top - 20:23:04 up 578 days,  8:37,  1 user,  load average: 12.42, 12.40, 12.70
   > Tasks: 2955 total,  13 running, 2942 sleeping,   0 stopped,   0 zombie
   > %Cpu(s): 17.1 us,  6.8 sy,  0.0 ni, 68.4 id,  7.0 wa,  0.0 hi,  0.8 si,  0.0 st
   > KiB Mem : 26320456+total, 12478772 free, 23212064 used, 22751372+buff/cache
   > KiB Swap: 33554428 total, 26411356 free,  7143072 used. 11192952+avail Mem 
   >
   >   PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND                                                                                                                  
   > 36573 oracle    20   0  0.098t 5.333g 5.330g R 100.0  2.1   0:32.80 oracle                                                                                                                   
   > 33909 oracle    20   0  0.098t 6.468g 6.464g R  98.6  2.6   1:02.77 oracle                                                                                                                   
   > 37670 oracle    20   0  0.098t 0.010t 0.010t R  97.2  4.2   0:16.83 oracle                                                                                                                   
   > 39081 oracle    20   0 30.273g  73220  40952 R  97.2  0.0   0:06.83 oracle

1. load average ：当前系统负载的平均值，后面的三个值分别为1分钟前、5分钟前、15分钟前进程的平均数。

2. %Cpu(s) ： 17.1 us 用户空间占用CPU百分比， 6.8 sy 内核空间占用CPU百分比，68.4 id 空闲CPU百分比

3. 进程列表栏

   > 　   PID：进程的ID
   > 　   USER：进程所有者
   > 　　PR：进程的优先级别，越小越优先被执行
   > 　　NInice：值
   > 　　VIRT：进程占用的虚拟内存
   > 　　RES：进程占用的物理内存
   > 　　SHR：进程使用的共享内存
   > 　　S：进程的状态。S表示休眠，R表示正在运行，Z表示僵死状态，N表示该进程优先值为负数
   > 　　%CPU：进程占用CPU的使用率
   > 　　%MEM：进程使用的物理内存和总内存的百分比
   > 　　TIME+：该进程启动后占用的总的CPU时间，即占用CPU使用时间的累加值。
   > 　　COMMAND：进程启动命令名称

 