#coding:utf-8
#线程池
import multiprocessing
import time

def task(name):
    print(f"{time.strftime('%H:%M:%S')}: {name}开始执行")
    time.sleep(3)

if __name__=="__main__":
    #设置线程池大小
    pool=multiprocessing.Pool(processes=3)
    for i in range(10):
        #维持执行的进程总数为processes,当一个进程执行完毕后添加新的进程进去
        pool.apply_async(func=task,args=(i,))
    pool.close()
    pool.join()
    print("Hello")