# iptable Nat 网络地址转换


## NAT 说明

`NAT` 全名是 `Network Address Translation`，字面上的意思是网络地址转换，它还可以分为源地址转换(SNAT)和目的地址转换(DNAT)

- SNAT: 将内网主机访问外网的源 IP 地址转换成网关地址，以达到用一个公网 IP 地址上网的目的
- DNAT: 将内网主机端口外网关端口绑定，用于将服务暴露在外网，方便外网客户端访问内网服务

## SNAT

### 1. 开启路由转发功能

```bash
sysctl -w net.ipv4.ip_forward=1
```

> 注: 如果想永久生效，编辑 `/etc/sysctl.conf` 文件，写入 `net.ipv4.ip_forward = 1` 后，执行 `sysctl -p`

### 2. 配置 SNAT 规则

内网所有主机访问外网时，都将源地址转换为 1.1.1.1 (网关 WAN 口地址)

```bash
iptables -t nat -A POSTROUTING -o ens32 -j SNAT --to-source 1.1.1.1
```

> 注：如果网关 WAN 没有固定 IP 地址，可以使用命令: `iptables -t nat -A POSTROUTING -o ens32 -j MASQUERADE`
> MASQUERADE 将自动对经过网关或路由器的数据包进行源地址伪装


## DNAT 

假设内网有台服务器，在 `80/tcp` 端口提供 Web 服务，想让外网的用户也可以访问到此服务，只需配置 DNAT 规则即可

实现方法: 将网关其中一个端口(8000 为例)与服务器的 80 端口进行绑定

```bash
iptables -t nat -A PREROUTING -p tcp -m tcp --dport 8000 -j DNAT --to-destination 192.168.2.100:80
```

此时，访问 `http://<网关 WAN 口地址>:8000`  即可访问到内网 Web 服务


