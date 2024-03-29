---
title: "使用 iperf 进行网络性能评估"
date: 2021-06-12T16:10:10+08:00
draft: false
categories: 
- devops
- command
tags:
- iperf
---

> 官方站点：[https://iperf.fr/](https://iperf.fr/)
> 支持平台： `windows`  `linux`  `macOS`  `unix`

安装方式可以选择二进制文件安装，也可以源码编译安装

```bash
./configure && make && make install
```

`iperf` 需要两台服务器，一台作服务器，一台作客户端，默认监听 `5201` 端口

## 1、启动服务器

```bash
iperf3 -s -D
```

> 说明： -s 以服务的方式运行， -D 以守护进程的方式运行

## 2、客户端连接测试

```bash
iperf3 -c iperf3_server_ipaddress
```
> 说明： -c 以客户端的方式运行测试 

**客户端选项**

```bash
-c        以客户端的方式运行 
-u        使用udp协议
-b [K|M|G] 指定udp使用的带宽，单位bits/sec。 此选项与-u相关。默认值是1Mbits/sec
-t         指定传输数据包的总时间，默认是10s
-n [K|M|G] 指定传输数据包的字节数
-l         指定读写缓冲区的长度，TCP方式默认大小为8kb，udp方式默认大小为1470B
-P         指定客户端与服务器端之间的线程数，默认是1个线程
-R         切换发送，接收模式，默认客户端发送，服务器端接收。设置此参数将反转。
-w         指定套接字缓冲区大小
-B         用来绑定一个主机地址或接口，适用于有多个网络接口的主机
-M         设置TCP最大信息段的值 
-N         设置TCP无延时
```

**客户端与服务器端共用选项**

```bash
-f [k|m|g|K|M|G]    指定带宽输入单位
-p                  指定服务器使用的端口或者客户端连接的端口
-i                  指定每次报告间隔的时间
-F                  指定文件作为数据流进行带宽测试
```
