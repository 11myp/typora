from multiprocessing import Process
import os,time

#计算密集型任务
def work():
    time.sleep(2)
    print("=====>",file=open("tmp.txt","w"))

if __name__ == "__main__":
    l = []
    print("本机为",os.cpu_count(),"核CPU")
    start = time.time()
    for i in range(400):
        p = Process(target=work)   #多进程，400个进程
        l.append(p)
        p.start()
    #l是记录进程的列表
    for p in l:
        p.join()
    stop = time.time()
    print("I/O密集型任务，多进程耗时 %s" % (stop-start))