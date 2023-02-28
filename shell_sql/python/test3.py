import os
import threading
import paramiko
# 定义SFTP上传函数
def sftp_upload(local_file, remote_path, sftp):
    if local_file.endswith('.gz'):
        sftp.put(local_file, remote_path)
    
# 定义多线程上传函数
def multi_thread_upload():
    # local_dir = "D:\\yunwei\\shell_sql\\python\\test\\"
    # remote_dir = "/home/sftpuser/"
    # ssh = paramiko.SSHClient()
    # ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    # ssh.connect(hostname='remote_host', port=22, username='11111', password='222222')
    local_dir = 'D:\\yunwei\\shell_sql\\python\\test\\'
    remote_dir = '/home/sftpuser/'
    username = 'sftpuser'
    password = '123'
    server_ip = '192.168.206.99'
    port = 22

    # Create SFTP client and connect to remote server
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(server_ip, port=port, username=username, password=password)
    sftp = ssh.open_sftp()
    # 检查远程目录是否存在.verf文件
    # if ".verf" not in sftp.listdir(local_dir):
    #     print("No .verf file found in remote directory!")
    #     return
    verf_list = [entry.name for entry in os.scandir(local_dir) if entry.name.endswith('.verf')]
    if len(verf_list) > 0:
    # 遍历本地目录中的文件并上传到远程服务器
        file_list = [entry.name for entry in os.scandir(local_dir) if entry.name.endswith('.gz')]
        for file_name in file_list:
            local_file = os.path.join(local_dir, file_name)
            remote_path = os.path.join(remote_dir, file_name)
            print(local_file,remote_path)
            # 创建线程并启动
            thread = threading.Thread(target=sftp_upload, args=(local_file, remote_path, sftp))
            thread.start()
        for file in verf_list:
            local_file = os.path.join(local_dir, file_name)
            remote_path = os.path.join(remote_dir, file_name)
            sftp.put(local_file, remote_path)
# 调用多线程上传函数
multi_thread_upload()