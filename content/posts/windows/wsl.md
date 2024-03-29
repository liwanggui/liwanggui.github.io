---
title: "Windows linux 子系统 WSL 配置"
date: 2023-03-10T14:15:50+08:00
draft: false
categories: 
- windows
tags:
- wsl
---

## wsl 启用 systemd

许多 Linux 发行版（包括 Ubuntu）默认运行 “systemd”，WSL 最近添加了对此系统/服务管理器的支持，因此 WSL 更类似于在裸机上使用你最爱的 `Linux` 发行版。 需要 `WSL` 的 `0.67.6+` 版本才能启用 `systemd`。 使用命令 `wsl --version` 检查 WSL 版本

若要启用 `systemd`，请使用 `sudo` 通过管理员权限在文本编辑器中打开 `wsl.conf` 文件，并将以下行添加到 `/etc/wsl.conf`：

```ini
[boot]
systemd=true
```

> 官方文档: https://learn.microsoft.com/zh-cn/windows/wsl/wsl-config

## 开机启动并开启 SSH 服务

安装 openssh 服务，提供 ssh 远程连接

```bash
sudo apt update
sudo apt install -y openssh-server
/etc/init.d/ssh start
```

> 注意: wsl 不支持 systemd 服务管理，并且每次开机网口 ip 会变

WSL 的 内网 ip 地址， 可以通过写 shell 脚本获取，获取后写入 Windows 的 hosts (`/mnt/c/Windows/System32/drivers/etc/hosts`) 文件中, 做本地解析。

为了在开机的时候启动 ssh 服务并获取内网 IP 地址可以写个启动初始化脚本 `init.wsl`

在 WSL 中创建 `/etc/init.wsl` 开机启动脚本文件, 并添加执行权限 `chmod +x /etc/init.wsl`

```bash
#!/bin/bash

IPADDR=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}')

tempfile=$(tempfile)

cat /mnt/c/Windows/System32/drivers/etc/hosts > $tempfile
sed -i '/wslhost/d' $tempfile
echo "${IPADDR%%/*}       wslhost" >> $tempfile
cat $tempfile > /mnt/c/Windows/System32/drivers/etc/hosts

/bin/rm -f $tempfile

/etc/init.d/ssh start
```

配置开机启动, 按 Win + R 键输入 "`shell:startup`" 打开启动目录，创建 `wsl-start.vbs` 文件， 内容如下

```vbs
Set ws = CreateObject("Wscript.Shell")
ws.run "wsl -d Ubuntu-22.04 -u root /etc/init.wsl", vbhide
```

> 注意: `-d` 参数为你安装的 `linux` 发行版名称，使用 `wsl -l` 查看

> 注意: 如何启用了 `systemd` , 就不用启动时执行 `init.wsl` 脚本 <br />
> 1. 直接通过 `systemd` 配置自启 
> 2. 也可以通过 `wsl.conf` 配置自启

## 故障问题

安装旧版本的 Proxifier 程序会导致 wsl 无法启动，只需要安装 Proxifier 4.x 及以上版本即可解决
