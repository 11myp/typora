#可以使用Python的smtplib库来实现从163邮箱发送含有附件的邮件到QQ邮箱：

from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header
import smtplib

# 第三方 SMTP 服务
def sendemail_multi(mail_user,mail_pass):
    mail_host="smtp.163.com"      # 设置服务器
    sender = "maiyp2023@163.com"
    receivers = ['1437007526@qq.com']  # 接收邮件，可设置为你的QQ邮箱或者其他邮箱

    # 创建一个带附件的实例
    message = MIMEMultipart()
    message['From'] = Header("{sender}", 'utf-8')
    message['To'] =  Header("{receivers}", 'utf-8')
    subject = 'Python SMTP 邮件测试'
    message['Subject'] = Header(subject, 'utf-8')

    # 邮件正文内容
    message.attach(MIMEText('这是Python 123456发送的邮件', 'plain', 'utf-8'))

    # 构造附件1，传送当前目录下的 test.txt 文件
    att1 = MIMEText(open('test.txt', 'rb').read(), 'base64', 'utf-8')
    att1["Content-Type"] = 'application/octet-stream'
    # 这里的filename可以任意写，写什么名字，邮件中显示什么名字
    att1["Content-Disposition"] = 'attachment; filename="test.txt"'
    message.attach(att1)

    try:
        #实例化 smtplib 模块的 SMTP 对象 smtpObj 来连接到 SMTP 访问
        smtpObj = smtplib.SMTP() 
        smtpObj.connect(mail_host, 25)    # 25 为 SMTP 端口号
        smtpObj.login(mail_user,mail_pass)  
        smtpObj.sendmail(sender, receivers, message.as_string())
        print ("邮件发送成功")
        smtpObj.quit()
    except smtplib.SMTPException as e:
        print (f"Error: 无法发送邮件{e}")
    

if __name__=="__main__":
    sendemail_multi('maiyp2023','AAMBRXGHRTCWMAUK')