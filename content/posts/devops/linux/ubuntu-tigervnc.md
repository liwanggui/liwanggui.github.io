---
title: "Ubuntu 安装配置 tigervnc & noVNC"
date: 2023-09-15T13:40:46+08:00
draft: false
categories: 
- devops
- ubuntu
tags:
- ubuntu
- tigervnc
- vnc
---

本实验以 `Ubuntu server 22.04` 系统为基础进行

## 安装 xfce4

安装 `xfce4` 桌面及其终端工具，如果你是 `ubuntu` 桌面系统，这步可以跳过

```bash
liwanggui@ubuntu:~$ sudo apt install -y xrdp xfce4 xfce4-terminal
```

> 注意: 安装 `xrdp` 包可以防止在 `vnc` 远程连接打开软件时，出现 `input/output` 错误

## 安装配置 tigervnc

### 安装 tigervnc

通过二进制压缩包，安装最新版本的 `tigervnc`

```bash
liwanggui@ubuntu:~$ wget -qO- https://nchc.dl.sourceforge.net/project/tigervnc/stable/1.13.1/tigervnc-1.13.1.x86_64.tar.gz | sudo tar xz --strip 1 -C /
```

> 注意: 通过 apt 安装的 tigervnc 版本较旧一点

### 配置 tigervnc

生成 `vnc` 密码，如下所示，按提示输入密码

```bash
liwanggui@ubuntu:~$ vncpasswd
Password:
Verify:
Would you like to enter a view-only password (y/n)? y
Password:
Verify:
liwanggui@ubuntu:~$ ls -lh .vnc/
total 4.0K
-rw------- 1 liwanggui liwanggui 16 Sep 15 05:56 passwd
```

修改 `/etc/tigervnc/vncserver.users` 配置文件，配置信息可以参考文件中的提示

添加如下配置信息

```conf
# TigerVNC User assignment
#
# This file assigns users to specific VNC display numbers.
# The syntax is <display>=<username>. E.g.:
#
# :2=andrew
# :3=lisa
 :0=liwanggui
```

> 提示: display 为 `:0` 表示使用的 `vnc` 端口号为 `5900`, 如果是 `:1` 端口则是 `5900 + 1` 为 `5901`

启动 vncserver 

```bash
liwanggui@ubuntu:~$ sudo systemctl start vncserver@:0
liwanggui@ubuntu:~$ sudo systemctl status vncserver@:0
● vncserver@:0.service - Remote desktop service (VNC)
     Loaded: loaded (/lib/systemd/system/vncserver@.service; disabled; vendor preset: enabled)
     Active: active (running) since Fri 2023-09-15 06:03:03 UTC; 3s ago
    Process: 39543 ExecStart=/usr/libexec/vncsession-start :0 (code=exited, status=0/SUCCESS)
   Main PID: 39550 (vncsession)
      Tasks: 0 (limit: 4516)
     Memory: 744.0K
        CPU: 14ms
     CGroup: /system.slice/system-vncserver.slice/vncserver@:0.service
             ‣ 39550 /usr/sbin/vncsession liwanggui :0

Sep 15 06:03:03 ubuntu systemd[1]: Starting Remote desktop service (VNC)...
Sep 15 06:03:03 ubuntu systemd[1]: Started Remote desktop service (VNC).
```

此时你可以通过 `vnc` 客户端工具进行远程连接了

> 提示: 如果要将 vnc 设为开机自启, 可以运行 `sudo systemctl enable vncserver@:0`

## noVNC

`noVNC` 是一个可以通过浏览器操作 vnc 远程桌面的工具，关于 `noVNC` 的详细信息可以查看其 [Github 站点](https://github.com/novnc/noVNC)

安装 `noVNC`

```bash
export GHPROXY=https://gh.wglee.org/
curl -sL ${GHPROXY}https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar xz -C /opt
cd /opt/noVNC-1.4.0 && ln -sf vnc.html index.html
git clone --depth=1 ${GHPROXY}https://github.com/novnc/websockify /opt/noVNC-1.4.0/utils/websockify
```

通过以下命令，运行 `noVNC`

```bash
/opt/noVNC-1.4.0/utils/novnc_proxy
```

`noVNC` 默认监控端口为 `6080`, 启动成功后，可以能过浏览器访问 `http://<server_ip_address>:6080`


> 提示: noVNC 默认连接的 vnc 端口为 5900，如果你的 vnc 商品不是 5900，请使用 `--vnc VNC_HOST:PORT` 指定
