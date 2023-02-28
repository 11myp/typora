import psutil

# Get CPU information
cpu_info = psutil.cpu_times()

# Print out the CPU information
print("CPU Info: ")
print("User Time:", cpu_info.user)
print("System Time:", cpu_info.system)
print("Idle Time:", cpu_info.idle)
print("Interrupt Time:", cpu_info.interrupt)