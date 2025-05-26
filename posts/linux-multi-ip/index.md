# Linux 多 ip 源进源出


场景:

- eth0: 192.168.1.10/24  网关: 192.168.1.1
- eth1: 10.10.0.10/24    网关: 10.10.0.1

要求:

10.10.0.10 这个 IP 的流量从 10.10.0.1 网关出，保证 10.10.0.10 这个地址可以正常连接, 其他所有流量均从 192.168.1.1 网关出

配置:

1. 将 192.168.1.1 配置为默认网关，写在网卡配置文件中
2. 添加新的路由表规则

```bash
echo "200  test"  >> /etc/iproute2/rt_tables
ip route add default via 10.10.0.1 dev eth1 table test
ip rule add from 10.10.0.10 table test
```

> 为了重启后也有效，将配置命令写入 /etc/rc.d/rc.local 文件中，并为此文件赋于运行权限
