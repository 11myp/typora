import threading
import time

#同时有5个人在办理
#与常规信号量一样，有界信号量管理一个计数器，该计数器表示release（）调用的次数减去acquired（）调用次数，再加上一个初始值。
# 如果需要，acquire（）方法会阻塞，直到它可以返回而不会使计数器为负值。如果未给定，则值默认为1。
semaphore = threading.BoundedSemaphore(5)

def yewubanli(name):
    #当在没有参数的情况下调用时：如果内部计数器在输入时大于零，则将其减1并立即返回。如果输入时为零，则阻塞，等待其他线程调用release（）使其大于零。
    # 这是通过适当的联锁来完成的，这样，如果多个acquire（）调用被阻止，release（）将正好唤醒其中一个调用。实现可能会随机选择一个，因此不应依赖被阻塞线程被唤醒的顺序。在这种情况下没有返回值。
    semaphore.acquire()
    time.sleep(3)
    print(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {name} 正在办理业务")
    #当进入时计数器为零，而另一个线程正在等待计数器再次大于零时，唤醒该线程。
    semaphore.release()

threading_list=[]
#threading_list：线程列表
#[<Thread(Thread-1, stopped 12916)>, <Thread(Thread-2, stopped 1772)>, <Thread(Thread-3, stopped 22924)>, <Thread(Thread-4, stopped 1292)>, <Thread(Thread-5, stopped 6332)>, 
# <Thread(Thread-6, stopped 18468)>, <Thread(Thread-7, stopped 25936)>,<Thread(Thread-8, stopped 26004)>, <Thread(Thread-9, stopped 26816)>, <Thread(Thread-10, stopped 21908)>, <Thread(Thread-11, stopped 9072)>, <Thread(Thread-12, stopped 2768)>]
#12个线程都执行函数yewubanli，但是信号量限制为5，所以只有等3秒后，信号量release()释放了5个，等待的线程才能执行  
for i in range(12):
    t = threading.Thread(target=yewubanli,args=(i,))
    print(i)
    threading_list.append(t)


for thread in threading_list:
    thread.start()

for thread in threading_list:
    thread.join()

print(threading_list)