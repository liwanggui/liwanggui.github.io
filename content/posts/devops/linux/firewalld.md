---
title: "Firewall 防火墙"
date: 2022-05-26T11:48:08+08:00
draft: false
categories: 
- devops
tags:
- firewalld
---

## firewalld 端口转发

1. 打开内核转发功能

```bash
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
```

2. 开启防火墙伪装(开启后才能转发端口)

```bash
firewall-cmd --permanent --add-masquerade
```

3. 配置端口转发

将访问本机 tcp/222 端口的流量转发到 172.16.174.101 的 tcp/22 端口

```bash
firewall-cmd --permanent --add-forward-port=port=222:proto=tcp:toport=22:toaddr=172.16.174.101
```

> 配置参数说明:  --add-forward-port=port=<源端口号>:proto=<协议>:toport=<目标端口号>:toaddr=<目标IP地址>

4. 重载防火墙规则

重载防火墙规则, 使用配置生效

```bash
firewall-cmd --reload
```

## firewalld 富规则

只允许 192.168.1.0/24 网段 ssh 服务和 80 端口

```bash
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.1.0/24" service name="ssh" accept"
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.1.0/24" port port="80" protocol="tcp" accept"
```

- accept：允许
- reject: 拒绝