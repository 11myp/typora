import os
import xlwt
from openpyxl import Workbook 

# workbook = xlwt.Workbook(encoding='utf-8')
# sheet1 = workbook.add_sheet('非ims文件处理情况')
# sheet2 = workbook.add_sheet('ims错单')
j=1

for dirpath, dirnames, filenames in os.walk("D:\\yunwei\\shell_sql\\python\\tmp"):
    for filename in [f for f in filenames if f.endswith(".txt")]:
        # Create an new Excel file and add a worksheet. 
        workbook = xlwt.Workbook(encoding='utf-8')
         = workbook.add_sheet(filename)
        # Get the current active worksheet 
        # Open txt file 
        f = open(filename, "r") 
        # Read each line in txt file and write it to excel file 
        for i in f: 
            ws.append(i.split('|')) 
        
        # Save the file 
        wb.save("file.xlsx") 
        
        # Close txt and excel files 
        f.close() 
        wb.close()


  
