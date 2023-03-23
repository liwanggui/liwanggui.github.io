---
title: "VMware - Linux 客户机中装载共享文件夹"
date: 2021-06-13T17:05:05+08:00
draft: false
categories: 
- devops
tags:
- vmware
---

## 1. 安装 vmware-tools 工具

```bash
[root@localhost ~]# mount /dev/cdrom  /mnt
mount: block device /dev/sr0 is write-protected, mounting read-only
[root@localhost ~]# cp /mnt/VMwareTools-10.0.0-2977863.tar.gz .
[root@localhost ~]# tar xzf VMwareTools-10.0.0-2977863.tar.gz
[root@localhost ~]# cd vmware-tools-distrib/
[root@localhost vmware-tools-distrib]# ./vmware-install.pl
[root@localhost vmware-tools-distrib]# ./vmware-install.real.pl
```

## 2. 重启虚拟机，设置共享文件夹，挂载共享文件夹

```bash
[root@localhost ~]# vmware-hgfsclient
data
[root@localhost ~]# mount -t vmhgfs .host:/data /mnt
[root@localhost ~]# ls /mnt/
bssh  env2.7  Fabric-1.13.1  pssh-2.3.1  pytest  test  WTools
```
