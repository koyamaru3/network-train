SNAT設定

```
IFNAME=ip -o addr show | awk -v ip="192.168.0.251" '$0 ~ ip {print $2}'
iptables -t nat -A POSTROUTING -o ${IFNAME} -j SNAT --to-source 192.168.0.251
```