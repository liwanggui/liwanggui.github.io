---
title: "systemctl 命令"
date: 2022-12-21T12:49:40+08:00
draft: false
categories: 
- systemd
tags:
- systemctl
---

`systemctl` 是一个 `systemd` 工具，主要负责控制 `systemd` 系统和服务管理器。

`systemd` 是一个系统管理守护进程、工具和库的集合，用于取代 `System V` 初始进程。

`systemd` 的功能是用于集中管理和配置 Linux 系统。

以网络服务 `network.service` 为例：

## 管理服务

```bash
#查看服务状态
systemctl status network.service

#启动服务
systemctl start network.service

#重启服务
systemctl restart network.service

#停止服务
systemctl stop network.service

#开机启动服务
systemctl enable network.servic

#停止开机启动
systemctl disable network.servic

#清理 systemd 失效的服务
systemctl reset-failed mongodb.service
```

## 服务单元

*查找所有或者某个服务*

```bash
systemctl list-units --type=service | grep network
```

`systemctl` 接受服务（`.service`），挂载点（`.mount`），套接口（`.socket`）和设备（`.device`）作为单元

*列出所有可用单元*

```bash
systemctl list-unit-files
```

*列出所有运行中单元*

```bash
systemctl list-units
```

*列出所有失败单元*

```bash
systemctl --failed
```

*使用systemctl命令杀死服务*

```bash
systemctl kill network.service
```

*列出所有系统挂载点*

```bash
systemctl list-unit-files --type=mount

UNIT FILE                     STATE   
dev-hugepages.mount           static  
dev-mqueue.mount              static  
proc-sys-fs-binfmt_misc.mount static  
sys-fs-fuse-connections.mount static  
sys-kernel-config.mount       static  
sys-kernel-debug.mount        static  
tmp.mount                     disabled
```

*挂载、卸载、重新挂载、重载系统挂载点并检查系统中挂载点状态*

```bash
systemctl start tmp.mount
systemctl stop tmp.mount
systemctl restart tmp.mount
systemctl reload tmp.mount
systemctl status tmp.mount
```
