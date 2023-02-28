#在单核CPU中，在同一时刻，只能运行单个进程。虽然可以同时运行多个程序，但是进程之间是通过轮流占用CPU来执行的
import os 
from multiprocessing import Process
import time


def task_process(delay):
    num=0
    for i in range(delay*100000000):
        num+=i
    print(f"进程pid为 {os.getpid()} , 执行完成")

if __name__=="__main__":
    print( '父进程pid为 %s.' % os.getpid() )
    t0=time.time()
    task_process(3)
    task_process(3)
    t1=time.time()
    print(f"执行耗时 {t1-t0} ")
    p0 = Process(target=task_process,args=(3,))
    p1 = Process(target=task_process,args=(4,))
    t2=time.time()
    p0.start();p1.start()
    p0.join();p1.join()
    t3=time.time()
    print(f"多进程并发执行耗时 {t3-t2} ")