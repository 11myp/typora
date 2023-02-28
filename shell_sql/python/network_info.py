import psutil

# Get network information
net_info = psutil.net_if_addrs()

# Print out the network information
print("Network Info:")
for interface, details in net_info.items():
    for detail in details:
        print(interface, ":", detail.address, detail.netmask, detail.broadcast)

# Get network packet information
packet_info = psutil.net_io_counters()
print(packet_info)

# Print out the network packet information
print("Network Packet Info:")
print("Bytes Sent:", packet_info.bytes_sent)
print("Bytes Received:", packet_info.bytes_recv)
print("Packets Sent:", packet_info.packets_sent)
print("Packets Received:", packet_info.packets_recv)
