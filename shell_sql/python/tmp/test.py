import os
from openpyxl import Workbook 
#首先，要使用Python循环读取目录下的txt文件，可以使用os.walk()函数：
i=1
wb = Workbook() 
for  filename in os.walk("D:\\yunwei\\shell_sql\\python\\tmp\\*txt"):
    #for filename in [f for f in filenames if f.endswith(".txt")]:
    #然后，使用Python将txt文件转换成excel格式的不同sheet文件。可以使用openpyxl库：
    # Create an new Excel file and add a worksheet. 
    wb.create_sheet(f'sheet{i}')
    # Get the current active worksheet 
    #ws = wb.active 
    
    # Open txt file 
    f = open(filename, "r") 
    # Read each line in txt file and write it to excel file 
    for j in f: 
        wb[f'sheet{i}'].append(j.split('|')) 
    f.close()
    i=i+1
    
    
# Save the file    
wb.save("file4.xlsx") 
    
    # Close txt and excel files  
wb.close()