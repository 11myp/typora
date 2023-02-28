#文件系统监控
from watchdog.observers import Observer
from watchdog.events import *
import time

#重新定一个类FileEventHandler()继承FileSystemEventHandler类，重写四个函数，这四个函数对应文件或者目录的增删改查
#FileSystemEventHandler类含有self.on_moved(event)方法处理DirMovedEvent和FileMovedEvent事件，预设为空.
# watchdog.events.FileMovedEvent() 文件被移动触发该事件。watchdog.events.DirMovedEvent() 目录被移动触发该事件
class FileEventHandler(FileSystemEventHandler):

    def __init__(self):
        FileSystemEventHandler.__init__(self)

    def on_moved(self,event):
        now = time.strftime("%Y-%m-%d %H:%M:%S",time.localtime())
        if event.is_directory:
            print(f"{now} 文件夹 { event.src_path }移动至 {event.dest_path }")
        else:
            print(f"{now} 文件 { event.src_path }移动至 {event.dest_path }")

    def on_created(self,event):
        now = time.strftime("%Y-%m-%d %H:%M:%S",time.localtime())
        if event.is_directory:
            print(f"{now} 文件夹 { event.src_path } 创建")
        else:
            print(f"{now} 文件 { event.src_path } 创建")

    def on_deleted(self,event):
        now = time.strftime("%Y-%m-%d %H:%M:%S",time.localtime())
        if event.is_directory:
            print(f"{now} 文件夹 { event.src_path }删除")
        else:
            print(f"{now} 文件 { event.src_path }删除")

    def on_modified(self,event):
        now = time.strftime("%Y-%m-%d %H:%M:%S",time.localtime())
        if event.is_directory:
            print(f"{now} 文件夹 { event.src_path }修改")
        else:
            print(f"{now} 文件 { event.src_path }修改")

if __name__=="__main__":
    observer=Observer()
    path=r"d:\\tmp"
    event_handler = FileEventHandler()
    #observer.schedule()：监控给定路径并且调用给定的时间处理类event_handler中合适的方法响应对应事件
    observer.schedule(event_handler,path,True)
    print(f"监控目录 {path}")
    #持续监控目录，直到终止指令发出
    #线程调用。
    observer.start()
    #阻塞进程
    observer.join()