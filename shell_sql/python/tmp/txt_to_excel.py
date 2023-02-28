import xlwt

# 创建excel文件
workbook = xlwt.Workbook(encoding='utf-8')
sheet1 = workbook.add_sheet('非ims文件处理情况')
sheet2 = workbook.add_sheet('ims错单')

# 写入表头,直接在txt中输出标题，就不用写表头
# sheet1.write(0, 0, 'prov_cd')
# sheet1.write(0, 1, 'cdr_file_type')
# sheet1.write(0, 2, 'stat')
# sheet1.write(0, 3, 'count')

#写入表头，ims错单
sheet2.write(0, 0, 'PROV_CD')
sheet2.write(0, 1, 'ERR_CODE')
sheet2.write(0, 2, 'COUNT')

# 读取txt文件
with open('process_result_tmp.txt','r') as f:
    content = f.readlines()
# 写入数据info
i = 1
for line in content:
    info = line.split('|')
    if len(info) == 4:
        sheet1.write(i, 0, info[0].strip())
        sheet1.write(i, 1, info[1].strip())
        sheet1.write(i, 2, info[2].strip())
        sheet1.write(i, 3, info[3].strip())
        i = i + 1
# 读取txt文件
with open('err_result_ims.txt','r') as t:
    err_result_ims = t.readlines()
# 写入数据info
j = 1
for line in err_result_ims:
    info = line.split('|')
    if len(info) == 3:
        sheet2.write(j, 0, info[0].strip())
        sheet2.write(j, 1, info[1].strip())
        sheet2.write(j, 2, info[2].strip())
        j = j + 1
# 保存excel文件
workbook.save('1.xls')