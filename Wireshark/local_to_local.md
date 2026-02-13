# Local to Local Wireshark Filters
These filters capture traffic with source and destination IP addresses within
private IP address ranges (RFC 1918) or is broadcast traffic.

## Local to Local (RFC 1918) & Broadcast
All traffic between private RFC 1918 addresses, **including** broadcast traffic.
```
(
 (ip.src == 10.0.0.0/8  || ip.src == 172.16.0.0/12  || ip.src == 192.168.0.0/16) &&
 (
   ip.dst == 10.0.0.0/8  ||
   ip.dst == 172.16.0.0/12 ||
   ip.dst == 192.168.0.0/16 ||
   ip.dst == 255.255.255.255
 )
)
```

## Local to Local (RFC 1918) Only
All traffic between private RFC 1918 addresses, **excluding** broadcast traffic.
```
(
 (ip.src == 10.0.0.0/8  || ip.src == 172.16.0.0/12  || ip.src == 192.168.0.0/16) &&
 (ip.dst == 10.0.0.0/8 || ip.dst == 172.16.0.0/12 || ip.dst == 192.168.0.0/16)
)
```

## Local Broadcast
Any ethernet broadcast (ARP, Limited/Subnet IP) where the sender is a private RFC 1918 address.
```
(
  (ip.src == 10.0.0.0/8 || ip.src == 172.16.0.0/12 || ip.src == 192.168.0.0/16) ||
  (arp.src.proto_ipv4 == 10.0.0.0/8 || arp.src.proto_ipv4 == 172.16.0.0/12 || arp.src.proto_ipv4 == 192.168.0.0/16)
)
&& eth.dst == ff:ff:ff:ff:ff:ff
```
