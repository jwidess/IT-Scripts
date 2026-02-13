# Local <-> External Wireshark Filters
Traffic between private IP address ranges (RFC 1918) and non-private (Internet) addresses.

## Local to External
Outbound traffic from RFC 1918 private addresses to non-private (Internet) addresses.
```
(ip.src == 10.0.0.0/8  || ip.src == 172.16.0.0/12  || ip.src == 192.168.0.0/16) &&
!(ip.dst == 10.0.0.0/8 || ip.dst == 172.16.0.0/12 || ip.dst == 192.168.0.0/16)
```

## External to Local
Inbound traffic from non-private (Internet) addresses to RFC 1918 private addresses.
```
!(ip.src == 10.0.0.0/8  || ip.src == 172.16.0.0/12  || ip.src == 192.168.0.0/16) &&
(ip.dst == 10.0.0.0/8 || ip.dst == 172.16.0.0/12 || ip.dst == 192.168.0.0/16)
```
