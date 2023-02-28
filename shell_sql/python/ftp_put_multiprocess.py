import os
import threading
import paramiko
import time

local_dir = 'D:\\yunwei\\shell_sql\\python\\test\\'
remote_dir = '/home/sftpuser/'
username = 'sftpuser'
password = '123'
server_ip = '192.168.206.99'
port = 22

# Create SFTP client and connect to remote server
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(server_ip, port=port, username=username, password=password)
sftp = client.open_sftp()

# Check if the remote directory exists, create it if it doesn't
try:
    sftp.stat(remote_dir)
except FileNotFoundError:
    sftp.mkdir(remote_dir)

# Define a function to upload a file
def upload_file(local_path, remote_path):
    print(f'Uploading {local_path} to {remote_path}...')
    sftp.put(local_path, remote_path)
    print(f'{local_path} uploaded successfully!')

# Get a list of files to upload
file_list = [entry.name for entry in os.scandir(local_dir) if entry.name.endswith('.verf')]
if len(file_list) > 0:
    start=time.time()
    files_to_upload = []
    for filename in os.listdir(local_dir):
        local_path = os.path.join(local_dir, filename)
        remote_path = os.path.join(remote_dir, filename)

        # if   filename.endswith('.verf') or filename.endswith('.gz') :
        files_to_upload.append((local_path, remote_path))
    # Upload files using multiple threads
    threads = []
    for local_path, remote_path in files_to_upload:
        print(local_path,remote_path)
        thread = threading.Thread(target=upload_file, args=(local_path, remote_path))
        thread.start()
        threads.append(thread)

    # Wait for all threads to finish
    for thread in threads:
        thread.join()
    end=time.time()

    print(f"耗时：{end-start}秒")
    # Close the SFTP client and SSH connection
    sftp.close()
    client.close()

