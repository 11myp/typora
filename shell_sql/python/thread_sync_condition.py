import threading

class Boy(threading.Thread):
    def __init__(self,cond,name):
        super(Boy,self).__init__()
        self.cond = cond
        self.name = name
    
    def run(self):
        self.cond.acquire()
        print(self.name + ":请求条件1")
        #唤醒一个被挂起的线程，等待响应1
        self.cond.notify()
        #释放掉内部所占用的锁，同时线程被挂起，直至接收到通知被唤醒或超时，等待响应1
        self.cond.wait()
        print(self.name+"追加条件2")
        self.cond.notify()
        self.cond.wait()
        print(self.name + "成立")
        self.cond.release()

class Girl(threading.Thread):
    def __init__(self,cond,name):
        super(Girl,self).__init__()
        self.cond = cond
        self.name = name
    
    def run(self):
        #使用acquire方法可以获得RLock锁
        self.cond.acquire()
        #使用wait方法就会放掉锁并处于阻塞状态，等其他线程中有使用notify方法时，在wait前的acquire方法处继续线程
        self.cond.wait()  #等待请求1
        #请求条件1执行之后，唤醒了Girl类中被挂起的线程。
        print(self.name + "条件1不够，不成立")
        self.cond.notify()
        self.cond.wait()
        print(self.name+"成立！")
        self.cond.notify()
        self.cond.release()

cond = threading.Condition()
boy = Boy(cond,"LiLei")
girl=Girl(cond,"Hanmeimei")
girl.start()
boy.start()

#总体流程：Girl类使用acquire方法可以获得RLock锁,并且使用wait方法就会放掉锁并处于阻塞状态---->Boy类获取RLock锁，执行条件1之后notify()唤醒Girl中被挂起的进程后,使用wait()方法放掉锁并处于阻塞状态
#---->Girl类被唤醒后执行输出“条件1不够，不成立”。并同样使用notify()唤醒Boy中被挂起的进程后,使用wait()方法放掉锁并处于阻塞状态---->Boy类执行"追加条件2"后，使用notify()唤醒Girl中被挂起的进程后,使用wait()方法放掉锁并处于阻塞状态
#---->notify()和wait()不断交替


#condition类里内置了一把RLock锁，有acquire方法和release方法，还有wait，notify，notifyAll方法，使用acquire方法可以获得RLock锁
#使用wait方法就会放掉锁并处于阻塞状态，等其他线程中有使用notify方法时，在wait前的acquire方法处继续线程（注意：而不是紧随wait后面执行）。
#notify会唤醒一个wait，但是不会立即跳转到另一个线程的wait处，必须在notify后使用release才能跳转到正在wait的线程的wait语句处。
# 不然不释放锁，wait就继续不了，必须先确认肯定有一个wait时，才可以notify,否则会报错。