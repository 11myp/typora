#_*_ coding:utf-8 _*_
import os
import smtplib
import chardet
import codecs
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header
import smtplib

class txtMail(object):
    def init (self,host=None,auth_user=None,auth_password=None):
        self.host="smtp.163.com" if host is None else host
        self.auth_user="maiyp2023" if auth_user is None else auth_user
        self.auth_password="AAMBRXGHRTCWMAUK" if auth_password is None else auth_password

    #msg_str:正文;recipent_list：接收者列表;attachment_list：附件列表
    def send_mail(self,subject,msg_str,recipent_list,attachment_list=None):
        message = MIMEMultipart()
        message["From"] = self.sender
        message["To"]=Header(";".join(recipent_list),"utf-8")
        message["Subject"]=Header(subject,"utf-8")
        message.attach(MIMEText(msg_str,"plain","utf-8"))

        #如果有附件，则添加附件
        if attachment_list:
            for att in attachment_list:
                    attachment = MIMEText(open(att, 'rb').read(), 'base64', 'utf-8')
                    attachment["Content-Type"] = 'application/octet-stream'
                    # 这里的filename可以任意写，写什么名字，邮件中显示什么名字
                    filename=os.path.basename(att)
                    #attachment["Content-Disposition"] = 'attachment; filename="test.txt"'
                    attachment.dd_header(
                        'content-disposition', 
                        'attachment',
                        filename=("utf-8","",filename),
                    )
                    message.attach(attachment)
                    try:
                        #实例化 smtplib 模块的 SMTP 对象 smtpObj 来连接到 SMTP 访问
                        smtpObj = smtplib.SMTP_SSL() 
                        smtpObj.connect(self.host, smtplib.SMTP_SSL_PORT)    # 
                        smtpObj.login(self.auth_user,self.auth_password)  
                        smtpObj.sendmail(self.sender, recipent_list, message.as_string())
                        smtpObj.quit()
                        print ("邮件发送成功")
                    except smtplib.SMTPException as e:
                        print (f"Error: 无法发送邮件{e}")
    
    def guess_chardet(self,filename):
        """
        :param filename:传入一个文本文件
        :return：返回文本文件的编码格式
        """
        encoding = None
        try:
            #小文件一次性读入内存，大文件则读取固定字节数
            raw=open(filename,"rb").read()
            if raw.startswith(codecs.BOM_UTF8):
                encoding="utf-8-sig"
            else:
                result=chardet.detect(raw)
                encoding=result["encoding"]
        except:
            pass
        return encoding

    def txt_send_mail(self,filename):
        '''
        :param filename:
        :return:
        将指定格式的txt文件发送到邮箱，txt文件样例：
        someone1@xxx.com,someone2@xxx.com #收件人，以逗号分隔
        xxx程序报警 #邮件主题
        程序xxx报错详情  #邮件正文，可有多行
        详细信息请看附件 #邮件正文
        file1,file2    #附件，逗号分隔，可有可无
        '''

        with open(filename,encoding=self.guess_chardet(filename)) as f:
            lines=f.readlines()
        recipent_list=lines[0].strip().split(",")
        msg_str="".join(lines[2:])
        attachment_list=[]
        for file in lines[-1].strip().split(","):
            if os.path.isfile(file):
                attachment_list.append(file)
            
        #如果没有附件 
        if attachment_list == []:
            attachment_list = None
        self.send_mail(
            subject=subject,
            msg_str=msg_str,
            recipent_list=recipent_list,
            attachment_list=attachment_list,
        )

if __name__ == "__main__":
    mymail= txtMail()
    mymail.txt_send_mail(filename="./test.txt")