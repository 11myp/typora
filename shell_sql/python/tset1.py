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
    local_dir = "D:\\yunwei\\shell_sql\\python\\test1\\"
    remote_dir = "/home/sftpuser/"
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname='192.168.206.99', port=22, username='sftpuser', password='123')
    threads = []
    for file_name in os.listdir(local_dir):
        if not file_name.endswith('.gz'):
            continue
        local_file = os.path.join(local_dir, file_name)
        remote_path = remote_dir + file_name
        # 创建线程并启动
        thread = threading.Thread(target=sftp_upload, args=(local_file, remote_path, ssh))
        thread.start()
        threads.append(thread)
    
    # 等待所有线程完成任务
    for thread in threads:
        thread.join()
    
    ssh.close()
multi_thread_upload()