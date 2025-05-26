---
title: "OpenVPN 客户端添加路由配置（流量分流）"
date: 2022-11-18T16:20:00+08:00
draft: false
categories: 
- network
tags:
- vpn
- openvpn
---

- [Windows 客户端软件包下载地址](https://openvpn.net/community-downloads/)
- [macOS 客户端软件包下载地址](https://openvpn.net/vpn-server-resources/connecting-to-access-server-with-macos/)
    - [macOS 第三方客户端 - Tunnelblick](https://tunnelblick.net/)
    - [macOS 第三方客户端 - Viscosity](https://www.sparklabs.com/viscosity/)

我们因为某些原因需要特定的流量不进VPN隧道或者进VPN隧道转发，我们就可以通过定义路由实现。

路由控制需要由三个参数进行定义：

1. route-nopull

如果在客户端配置文件中配 route-nopull，openvpn 连接后将不会在电脑上添加任何路由，所有流量都将本地转发。

2. vpn_gateway

如果在客户端配置文件中配vpn_getaway，默认访问网络不走vpn隧道，如果可以通过添加该参数，下发路由，访问目的网络匹配到会自动进入VPN隧道。

```
route 10.0.0.0 255.255.255.0  vpn_gateway
route 172.16.0.0 255.255.255.0  vpn_gateway
```

3. net_gateway

这个参数和 vpn_gateway 相反,表示在默认出去的访问全部走 openvpn 时,强行指定部分IP地址段访问不通过 Openvpn 出去。
max-routes 参数表示可以添加路由的条数,默认只允许添加100条路由,如果少于100条路由可不加这个参数。

```
max-routes 1000
route 10.100.0.0 255.255.255.0 net_gateway
```

配置如下：

```
client
dev tun
proto tcp
remote 114.112.4.6 11194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
#ignore-unknown-option block-outside-dns
#block-outside-dns
verb 3
route-nopull
route 192.168.1.0 255.255.255.0 vpn_gateway
route xxx.xxx.xxx.0 255.255.255.0 net_gateway
```

> [文章源地址](https://blog.csdn.net/zzchances/article/details/124801161)