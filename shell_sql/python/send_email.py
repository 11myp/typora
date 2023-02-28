#_*_ coding:utf-8 _*_
import smtplib
from email.mime.text import MIMEText

#simple text email
def sendmail_txt(mail_user, mail_paas, subject):
    mail_host='smtp.163.com'
    # mail_user='maiyp2023'
    # mail_paas='******'
    sender = 'maiyp2023@163.com'
    receivers = ["1437007526@qq.com"]
    #创建一个文本实例
    mseeage=MIMEText("这是正文，邮件正文…… ","plain","utf-8")
    mseeage['From'] = sender
    mseeage['To'] = ','.join(receivers)
    mseeage['subject']= subject

    try:
        smtpObj = smtplib.SMTP()
        smtpObj.connect(mail_host,25)
        smtpObj.login(mail_user,mail_paas)
        smtpObj.sendmail(sender, receivers, mseeage.as_string())
        print("发送成功")
        smtpObj.quit()
    except smtplib.SMTPException as e:
        print(f"发送失败，错误原因：{e}")

if __name__ == "__main__":
    sendmail_txt('1**8','授权码','test')