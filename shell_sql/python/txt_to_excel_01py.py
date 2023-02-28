import pandas as pd
 
# Read in 1.txt
df1 = pd.read_csv('1.txt', delimiter='|')
 
# Write 1.txt to first sheet of excel
excel_writer = pd.ExcelWriter('data.xlsx')
df1.to_excel(excel_writer, 'Sheet1')
 
# Read in 2.txt
df2 = pd.read_csv('2.txt', delimiter='|')
 
# Write 2.txt to second sheet of excel
df2.to_excel(excel_writer, 'Sheet2')
 
# Save the Excel file
excel_writer.save()