import os
from openpyxl import Workbook 
#configfile
config = {}
with open('D:\\yunwei\\shell_sql\\python\\configfile', 'r', encoding='utf-8') as cf:
    for line in cf:
        #line.strip()：移除字符串头尾指定的字符(默认为空格或换行符)或字符序列
        if line.strip():
            k, v = line.strip().split('=')
            config[k] = v
wb = Workbook()
#dirpath
for dirpath, dirnames, filenames in os.walk("D:\\yunwei\\shell_sql\\python\\tmp"):
    for filename in [f for f in filenames if f.endswith(".txt")]:
        # Create an new Excel file and add a worksheet. The explame of worksheet in chinese on config file
        sheetname= config.get(filename)
        wb.create_sheet(f'{sheetname}')     
        # Open txt file 
        with open(filename,'r') as f:
        # Read each line in txt file and write it to excel file
            i=1
            for j in f:
                if i == 1:
                    #获取第一行文件的列数
                    clos_num=len(j.split('|'))
                #如果某行的列数等于第一行的列数，则add进对应sheet表。如此可以筛出不相关行。第一行为表头字段
                if len(j.split('|')) == clos_num:
                    wb[f'{sheetname}'].append(j.split('|'))
                i=i+1                
    # Save the file    
    wb.save("file5.xlsx") 
        
    # Close txt and excel files  
    wb.close()