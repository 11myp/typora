import psutil

# Get memory information
mem_info = psutil.virtual_memory()

# Print out the memory information
print("Memory Info: ")
print("Total Memory:", mem_info.total)
print("Available Memory:", mem_info.available)
print("Used Memory:", mem_info.used)
print("Free Memory:", mem_info.free)
print("Percent Used:", mem_info.percent)