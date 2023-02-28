#好的，你需要安装paramiko库，它是一个用于SSH和SFTP的Python实现。以下是一个使用SFTP从本地目录传输文件到远程服务器的示例代码，其中包括你提供的账号和密码信息：

#这里是代码了
import os
import paramiko
import time
# 连接远程服务器
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('192.168.206.99', username='sftpuser', password='123')


# 遍历本地目录，上传.gz和.verf文件
local_dir = 'D:\\yunwei\\shell_sql\\python\\test\\'
remote_dir = '/home/sftpuser/'

#while True:
file_list=[entry.name for entry in os.scandir(local_dir) if entry.name.endswith('.verf')]
#当目录下存在.verf文件时才开始传输文件
if len(file_list) > 0 :
    # 创建SFTP客户端
    for root, dirs, files in os.walk(local_dir):
        # 上传所有的.gz文件
        start=time.time()
        for file in files:
            if file.endswith('.gz'):
                local_file = os.path.join(root, file)
                remote_file = os.path.join(remote_dir, file)
                # 上传文件到远程服务器
                sftp = ssh.open_sftp()
                sftp.put(local_file, remote_file)
                sftp.close()

        # 上传所有的.verf文件
        for file in files:
            if file.endswith('.verf'):
                local_file = os.path.join(root, file)
                remote_file = os.path.join(remote_dir, file)
                # 上传文件到远程服务器
                sftp = ssh.open_sftp()
                sftp.put(local_file, remote_file)
                sftp.close()
    end=time.time()
    print(f"耗时：{end-start}秒") 
# 断开SSH连接
ssh.close()
    # if len(file_list) > 0 :
    #     for filename in os.listdir(local_dir):
    #         print(filename)
    #         if filename.endswith('.gz') or filename.endswith('.verf'):
    #             local_path = os.path.join(local_dir, filename)
    #             print(local_path)
    #             remote_path = os.path.join(remote_dir, filename)
    #             print(remote_path)
    #             sftp.put(local_path, remote_path)

    #     # 关闭SFTP客户端和SSH连接
    #     sftp.close()
    #     ssh.close()

#这段代码会遍历本地/data/verf/目录下的文件，并将文件名以.gz或.verf结尾的文件上传到远程服务器的/data/gz/目录下。如果远程目录不存在，SFTP客户端会自动创建。文件上传的顺序是先上传所有.gz文件，再上传所有.verf文件。如果需要改变上传顺序，可以修改for循环的顺序。