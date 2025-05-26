---
title: "OpenVPN 服务端配置"
date: 2022-11-18T16:20:00+08:00
draft: false
categories: 
- network
tags:
- vpn
- openvpn
---

## 服务端开启一个证书或账户多人同时登录

修改 `openVPN` 配置文件 `server.conf` ， 内容如下

```
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key # This file should be kept secret
dh dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "route 172.16.1.0 255.255.255.0"
keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status openvpn-status.log
verb 3
explicit-exit-notify 1
duplicate-cn
```

> duplicate-cn：这字段就是开启一个证书或账户多人同时登录。

## 为客户端分配固定IP

修改配置 `/etc/openvpn/server.conf` 配置文件, 添加如下配置后，重启 `openvpn-server@server` 服务

```
client-config-dir /etc/openvpn/client
```

> 注意: 如果使用相对路径以 server.conf 目录为基准

配置客户端用户名文件 `/etc/openvpn/client/<username>`，例如用户名为: `liwanggui`

创建 liwanggui 客户端配置文件 `/etc/openvpn/client/liwanggui`, 添加如下配置

```
ifconfig-push 10.8.0.21 255.255.255.0
```

> 说明:  `ifconfig-push` 接分配给客户端的 IP 地址和子网掩码

> 注意: 添加客户端配置不需要重启服务