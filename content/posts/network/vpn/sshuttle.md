---
title: "sshuttle 轻量级全局代理工具"
date: 2021-06-13T17:07:48+08:00
draft: false
categories: 
- network
tags:
- vpn
- sshuttle
---

## 穷人的 VPN

`sshuttle` 是一个使用简单的轻量级全局代理工具(穷人的vpn)，以 `ubuntu 18.04` 为例演示如何使用, 使用前提是你有一台远程的 `linux` 服务器

> Github 官方仓库: [https://github.com/sshuttle/sshuttle](https://github.com/sshuttle/sshuttle)

*安装*

```bash
sudo apt install sshuttle
```

*使用*

使用前先将不需要网络代理地址段列出来，例如本地局域网 `192.168.1.0/24`

```bash
sshuttle --dns -r username@server_ipaddress:port -x 192.168.1.0/24 -x server_ipaddress 0/0 -D
```

> 注意: 如果出现 `fatal: server died with error code 255` 错误，请使用 -x 选项排除服务器 ip
> https://github.com/sshuttle/sshuttle/issues/150

## 番外

其他的全局代理软件

**Linux 下的有**

- proxychains [下载地址](http://proxychains.sourceforge.net/)
- redsocks [下载地址](https://github.com/darkk/redsocks)
- tsocks [下载地址](http://tsocks.sourceforge.net/)
- sshuttle [Github - sshuttle](https://github.com/sshuttle/sshuttle)

**macOS 下的有**

- Proxifier [下载地址](http://www.proxifier.com/)
- ProxyCap [下载地址](http://www.proxycap.com/download.html)

**Windows 下的有**

- Proxifier [下载地址](http://www.proxifier.com/)
- ProxyCap [下载地址](http://www.proxycap.com/download.html)

### Proxifier

`Proxifier` 允许不支持通过代理服务器工作的网络应用程序通过SOCKS或HTTPS代理和链进行操作。

> 操作参考 [https://blog.csdn.net/wu_cai_/article/details/80271478](https://blog.csdn.net/wu_cai_/article/details/80271478)

**注册码**

> 用户名可以随意填写

*Windows*

- 5EZ8G-C3WL5-B56YG-SCXM9-6QZAP
- G3ZC7-7YGPY-FZD3A-FMNF9-ENTJB
- YTZGN-FYT53-J253L-ZQZS4-YLBN9

*macOS*

- P427L-9Y552-5433E-8DSR3-58Z68
