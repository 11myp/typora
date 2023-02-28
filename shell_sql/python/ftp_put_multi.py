import os
import threading
import paramiko
# 定义SFTP上传函数
def sftp_upload(local_file, remote_path, ssh):
    sftp = ssh.open_sftp()
    sftp.put(local_file, remote_path)
    sftp.close()
# 定义多线程上传函数
def multi_thread_upload():
    local_dir = "D:\\yunwei\\shell_sql\\python\\test\\"
    remote_dir = "/home/sftpuser/"
    #创建ssh客户端
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    #连接ssh
    ssh.connect(hostname='192.168.206.99', port=22, username='sftpuser', password='123')
    
    #定义线程列表
    threads = []
    thread_num = 5  # 同时上传的线程数量
    count = 0  # 计数器，记录已上传的文件数量
    for file_name in os.listdir(local_dir):
        if not file_name.endswith('.gz'):
            continue
        local_file = os.path.join(local_dir, file_name)
        remote_path = remote_dir + file_name
        # 创建线程并启动
        #创建线程
        thread = threading.Thread(target=sftp_upload, args=(local_file, remote_path, ssh))
        #启动进程
        thread.start()
        #追加进程列表
        threads.append(thread)
        #每上传一个文件，count数量加1
        count += 1
        # 控制同时上传的文件数量
        #当同时上传文件数量为5时，阻塞线程，直至上传完成，再进行下一步
        if count % thread_num == 0:
            for thread in threads:
                #join()方法阻塞线程，主线程等待这些子线程执行直到终止再进行下一步。
                thread.join()
            threads = []
    
    # 等待所有线程完成任务
    # 这一步是防止总的上传文件数量不为5的倍数数，没有设置进程阻塞，直接进行SSH关闭。会导致最后上传的文件没上传成功
    for thread in threads:
        thread.join()
    
    # 所有线程完成传输任务后，关闭SSH连接
    ssh.close()
if __name__=="__main__":
    #该方法没有考虑文件上传失败的情况，需优化
    multi_thread_upload()