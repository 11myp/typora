import time 
import threading

def task_thread(counter):
    print(f'线程名称：{threading.current_thread().name} 参数：{counter} 开始时间： {time.strftime("%Y-%m-%d %H:%M:%S")}')
    num=counter
    while num:
        time.sleep(3)
        num -= 1
    print(f'线程名称：{threading.current_thread().name} 参数：{counter} 结束时间： {time.strftime("%Y-%m-%d %H:%M:%S")}')



if __name__=="__main__":
    print(f'主线程开始时间：{time.strftime("%Y-%m-%d %H:%M:%S")}')
    #初始化三个线程，传递不同的参数
    t1 = threading.Thread(target=task_thread,args=(3,))
    t2 = threading.Thread(target=task_thread,args=(2,))
    t3 = threading.Thread(target=task_thread,args=(1,))

    #开启三个线程
    t1.start()
    t2.start()
    t3.start()

    #等待运行结束
    t1.join()
    t2.join()
    t3.join()

    print(f'主线程结束时间：{time.strftime("%Y-%m-%d %H:%M:%S")}')