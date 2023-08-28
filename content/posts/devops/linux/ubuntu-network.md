---
title: Ubuntu Server 网络配置
date: "2021-03-04T10:05:44+08:00"
draft: false
categories:
- devops
- ubuntu
tags:
- ubuntu
- netplan
---

## 临时IP地址分配

对于临时网络配置，可以使用在大多数其他 GNU/Linux 操作系统上也可以找到的ip命令。ip 命令允许您配置立即生效的设置，但是这些设置不是永久性的，并且在重新启动后会丢失。

要临时配置IP地址，可以按以下方式使用ip命令。修改IP地址和子网掩码以符合您的网络要求。

```bash
sudo ip addr add 10.102.66.200/24 dev enp0s25
```

然后可以使用ip来设置链接的打开或关闭。

```bash
ip link set dev enp0s25 up
ip link set dev enp0s25 down
```

要验证 enp0s25 的 IP 地址配置，可以按以下方式使用 ip 命令。

```bash
ip address show dev enp0s25
10: enp0s25: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 00:16:3e:e2:52:42 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.102.66.200/24 brd 10.102.66.255 scope global dynamic eth0
       valid_lft 2857sec preferred_lft 2857sec
    inet6 fe80::216:3eff:fee2:5242/64 scope link
       valid_lft forever preferred_lft forever6
```

要配置默认网关，可以按以下方式使用ip命令。修改默认网关地址以符合您的网络要求。

```bash
sudo ip route add default via 10.102.66.1
```

要验证默认网关配置，可以按以下方式使用ip命令。

```bash
ip route show
default via 10.102.66.1 dev eth0 proto dhcp src 10.102.66.200 metric 100
10.102.66.0/24 dev eth0 proto kernel scope link src 10.102.66.200
10.102.66.1 dev eth0 proto dhcp scope link src 10.102.66.200 metric 100 
```

如果您需要DNS进行临时网络配置，则可以在文件中添加DNS服务器IP地址 `/etc/resolv.conf`。通常，`/etc/resolv.conf`不建议直接进行编辑，但这是一个临时且非持久的配置。下面的示例显示如何在中输入两个DNS服务器`/etc/resolv.conf`，应将其更改为适合您的网络的服务器。下一节将更详细地说明进行DNS客户端配置的正确的持久方法。

```bash
nameserver 8.8.8.8
nameserver 8.8.4.4
```

如果您不再需要此配置，并且希望从接口清除所有IP配置，则可以将ip命令与flush选项一起使用，如下所示。

```bash
ip addr flush eth0
```
> 使用ip命令刷新IP配置不会清除的内容 `/etc/resolv.conf`。您必须手动删除或修改这些条目，或者重新引导，这也将导致重新写入`/etc/resolv.conf`，这是到的符号链接`/run/systemd/resolve/stub-resolv.conf`

## 静态IP地址分配

要将系统配置为使用静态地址分配，请在文件中创建一个netplan配置 `/etc/netplan/99_config.yaml`。下面的示例假定您正在配置标识为eth0的第一个以太网接口。更改地址，gateway4和名称服务器值，以满足您的网络要求。

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 10.10.10.2/24
      gateway4: 10.10.10.1
      nameservers:
        search: 
        - mydomain
        - otherdomain
        addresses: 
        - 10.10.10.1
        - 1.1.1.1
```

然后可以使用 netplan 命令应用该配置。

```bash
sudo netplan apply
```

## 名称解析

与IP网络相关的名称解析是将IP地址映射到主机名的过程，从而更容易识别网络上的资源。下一节将说明如何使用DNS和静态主机名记录正确配置系统以进行名称解析。

DNS客户端配置
传统上，该文件`/etc/resolv.conf`是静态配置文件，很少需要通过DCHP客户端挂接进行更改或自动更改。Systemd 解析处理名称服务器配置，并且应该通过systemd-resolve命令与之交互。Netplan配置systemd-resolved以生成要放入的名称服务器和域的列表`/etc/resolv.conf`，这是一个符号链接：
`/etc/resolv.conf -> ../run/systemd/resolve/stub-resolv.conf`

要配置解析器，请将适合您的网络的名称服务器的IP地址添加到netplan配置文件中。您还可以添加可选的DNS后缀搜索列表以匹配您的网络域名。生成的文件可能如下所示：

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s25:
      addresses:
        - 192.168.0.100/24
      gateway4: 192.168.0.1
      nameservers:
          search: [mydomain, otherdomain]
          addresses: [1.1.1.1, 8.8.8.8, 4.4.4.4]
```
该搜索选项也可以用多个域名使用，使得DNS查询将按照它们的输入顺序追加。例如，您的网络可能有多个子域可供搜索；的父域`example.com`和两个子域，`sales.example.com`以及`dev.example.com`。

如果您要搜索多个域，则配置可能如下所示：

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s25:
      addresses:
        - 192.168.0.100/24
      gateway4: 192.168.0.1
      nameservers:
          search: [example.com, sales.example.com, dev.example.com]
          addresses: [1.1.1.1, 8.8.8.8, 4.4.4.4]
```

如果您尝试对名称为server1的主机执行ping操作，系统将按以下顺序自动查询DNS的完全合格域名（FQDN）：

1. server1.example.com
2. server1.sales.example.com
3. server1.dev.example.com

如果找不到匹配项，则DNS服务器将提供notfound的结果，并且DNS查询将失败。

## 静态路由

例如，如果你要添加到目标为 `192.168.1.0/24` 的网络，网关为 `192.168.0.2` 的路由，可以将以下行添加到配置文件中：

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s25:
      addresses:
        - 192.168.0.100/24
      nameservers:
          search: [example.com, sales.example.com, dev.example.com]
          addresses: [1.1.1.1, 8.8.8.8, 4.4.4.4]
      routes:
        - to: default
          via: 192.168.0.1
        - to: 192.168.1.0/24
          via: 192.168.0.2
```

> 注意: 临时静态路由可以使用 `ip route` 命令添加删除