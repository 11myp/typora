import csv

with open('process_result_tmp.txt', 'r') as csv_file:
    reader = csv.reader(csv_file, delimiter='|')
    with open('process_result_tmp.xls', 'w', newline='') as xls_file:
        writer = csv.writer(xls_file)
        for row in reader:
            if len(row) == 4:  # 如果某行有错误，则跳过 
                writer.writerow(row)