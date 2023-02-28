#进程并发控制——semaphore，用来控制对共享资源的访问数量，可以控制同一时刻并发的进程数
import multiprocessing
import time

def worker(s,i):
    #acquire():方法用于获取锁定，无论是锁定还是非锁定。 在不带参数的情况下调用它时，它将阻塞调用线程，直到当前使用它的线程将锁解锁。
    s.acquire()
    print(time.strftime('%H:%M:%S'),multiprocessing.current_process().name+"获得锁运行");
    time.sleep(i)
    print(time.strftime('%H:%M:%S'),multiprocessing.current_process().name+"释放锁结束");
    #release()方法用于释放由调用线程获取的锁
    s.release()

if __name__=="__main__":
    #开启两个线程
    s = multiprocessing.Semaphore(2)
    for i in range(6):
        p=multiprocessing.Process(target=worker,args=(s,2))
        p.start()