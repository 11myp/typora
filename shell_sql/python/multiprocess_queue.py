from multiprocessing import Process,Queue
import time

def ProducerA(q):
    count=1
    while True:
        #put()方法用以插入数据到队列中，还有两个参数。blocked和timeout.如果blocked为True，
        # 并且timeout为正数，则该方法会阻塞timeout指定的时间，直到改队列有剩余的空间
        q.put(f"冷饮{count}")
        print(f"{time.strftime('%H:%M:%S')} A放入: [冷饮{count}]")
        count+=1
        time.sleep(1)

def ConsumerB(q):
    while True:
        print(f"{time.strftime('%H:%M:%S')} B取出: [{q.get()}]")
        time.sleep(5)
if __name__=="__main__":
    #队列最大长度为5
    q = Queue(maxsize=5)
    p = Process(target=ProducerA,args=(q,))
    c = Process(target=ConsumerB,args=(q,))
    #先开启消费者
    #p.start()
    c.start()
    p.start()
    #join()方法阻塞线程
    c.join()
    p.join()

    