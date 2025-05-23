# 配置 DHCP 中继为多个网段分配 ip 地址


有时我们的网络中可能划分了好几个网段，需要同时为多个网段内的主机分配 `ip` 地址，这时候就需要用到 `dhcp` 中继了。
在连接多个子网的路由器上启用 `dhcp` 中继功能允许有针对性地转发 `dhcp` 广播。

> 学过网络的都应该知道不同子网段是不允许广播通过的。所有 `dhcp` 是无法正常在多网段内提供服务的

安装好 `dhcpd` 软件，通过修改 `/etc/sysconfig/dhcrelay` 文件来配置 `dhcp` 中继。 具体操作步骤如下：

**1. 开启服务器的路由转发功能。**

```bash
vim /etc/sysctl.conf
net.ipv4.ip_forward = 1
sysctl -p
```

**2. 设置允许dhcp中继数据的接口及dhcp服务器的ip地址**

```bash
vim /etc/sysconfig/dhcrelay
INTERFACES="eth0 eth1"
DHCPSERVERS="192.168.1.2"
```

**3. 启动 dhcrelay 中继服务程序**

```bash
service dhcrelay start
chkconfig --level 35 dhcrelay on
```
