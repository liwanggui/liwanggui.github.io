# 使用 sshpass 免密码远程执行命令


首先我们知道通过添加 `key` 的方式可以实现 ssh 远程免密码执行命令，但是如果我们使用密码的方式该如何不提示输入密码进行 `ssh` 远程执行命令呢？

答案就是通过使用 `sshpass` 工具来实现

## 1. 安装`sshpass`

```bash
yum install sshpass
```

> *Tips:* 如果系统 yum 源没有 sshpass 包，可以添加阿里云的源。 [阿里云开源站点](http://mirrors.aliyun.com/)

## 2. 示例

通过ssh远程登录来测试 `sshpass` 功能

```bash
# 本机ip地址
[root@localhost ~]# ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 00:0C:29:7B:7C:7E
          inet addr:192.168.92.132  Bcast:192.168.92.255  Mask:255.255.255.0
          inet6 addr: fe80::20c:29ff:fe7b:7c7e/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:15089 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8054 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:17225172 (16.4 MiB)  TX bytes:797990 (779.2 KiB)
          Interrupt:19 Base address:0x2000
# 输入这条命令不会提示输入密码及确认添加 known_hosts
[root@localhost ~]# sshpass -p liwanggui ssh root@192.168.92.133 -o StrictHostKeyChecking=no
Last login: Sat Mar 11 07:28:41 2017 from 192.168.92.132
# ssh连接主机的ip地址
[root@localhost ~]# 
eth0      Link encap:Ethernet  HWaddr 00:0C:29:F2:3A:2D
          inet addr:192.168.92.133  Bcast:192.168.92.255  Mask:255.255.255.0
          inet6 addr: fe80::20c:29ff:fef2:3a2d/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:225 errors:0 dropped:0 overruns:0 frame:0
          TX packets:105 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:23814 (23.2 KiB)  TX bytes:14940 (14.5 KiB)
          Interrupt:19 Base address:0x2000
```
