import multiprocessing
import time

#多进程数据交换pipe

def task1(pipe):
    for i in range(5):
        #区别输出字符串
        str=f"task1-{i}" 
        print(f"{time.strftime('%H:%M:%S')} task1 发送： {str}")
        #发送
        pipe.send(str)
    time.sleep(2)
    #如果没有消息可接收，recv方法会一直阻塞。如果接收的一端已经关闭连接，则抛出EOFError
    for i in range(5):
        print(f"{time.strftime('%H:%M:%S')} task1 接收： {pipe.recv()}")

def task2(pipe):
    print(pipe)
    for i in range(5):
        print(f"{time.strftime('%H:%M:%S')} task2 接收： {pipe.recv()}")
    time.sleep(1)
    for i in range(5):
        #区别输出字符串
        str=f"task2-{i}" 
        print(f"{time.strftime('%H:%M:%S')} task2 发送： {str}")
        #发送
        pipe.send(str)

if __name__=="__main__":
    #multiprocessing.Pipe()：元组[PipeConnection，PipeConnection]返回由管道连接的两个连接对象
    parent_con, child_con = multiprocessing.Pipe()
    #parent_con.send()发送消息，child_con.recv()接收消息。p1,p2同时运行
    #multiprocessing.Process模块用于创建进程
    #p1.recv()不能接收p1.send()的消息，示例查看test_pipe
    p1 = multiprocessing.Process(target=task1,args=(parent_con,))
    p2 = multiprocessing.Process(target=task2,args=(child_con,))

    #p1,p2同时启动.task1先发送5条消息，再接收。task2先接收消息，再发送。p1先发送5条消息，p2接收到消息。p2 sleep 1s 后发送消息。p1 sleep 2s 后接收消息
    p1.start()
    p2.start()

    p1.join()
    p2.join()   
