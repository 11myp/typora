# # f=open("computer.txt",encoding="utf-8")
# # data_list=f.readlines()
# # data_list.insert(1,"123\n")
# # #data=str(data_list)
# # data=''.join(data_list)

# # f = open("computer.txt",encoding="utf-8",mode="w")
# # f.write(data)

# # f.seek
# # f.flush()
# # f.close()
# a = 2
# def func():
#     global b
#     b = 3
# func()
# print(a)
# print(b)
num = range(1,11)
def handle(n):
  if n % 2 == 0:
    return n

result = filter(handle,num)
print(list(result))
