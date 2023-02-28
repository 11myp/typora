from multiprocessing import Pipe, Process
import time


def f(subconn):
    time.sleep(1)
    subconn.send("吃了吗")
    print("一方接收到的消息", subconn.recv())
    subconn.close()


if __name__ == '__main__':
    parent_con, child_con = Pipe()
    p = Process(target=f, args=(child_con,))
    p.start()
    print("另一方接收到的消息", parent_con.recv())
    parent_con.send("发送的消息")