---
title: "Filebrowser 一个简单的在线文件服务"
date: 2021-08-23T16:16:21+08:00
draft: false
categories: 
- fileserver
tags:
- filebrowser
---

- 官方文档: [https://filebrowser.org/](https://filebrowser.org/)

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
```

## 配置

创建配置目录 `/etc/filebrowser`

```bash
sudo mkdir -p /etc/filebrowser
```

初始化数据库文件

```bash
sudo filebrowser config init -d /etc/filebrowser/filebrowser.db
```

> 默认 filebrowser.db 是不存在的, filebrowser 配置信息都保存在数据库文件中

配置文件服务的根目录

```bash
sudo filebrowser config set -r /data/fileserver -d /etc/filebrowser/filebrowser.db
```

配置服务监听地址及端口

```bash
sudo filebrowser config set -a 0.0.0.0 -d /etc/filebrowser/filebrowser.db
sudo filebrowser config set -p 80 -d /etc/filebrowser/filebrowser.db
```

添加管理员用户, 用户名: admin  密码: admin

```bash
sudo filebrowser users add admin admin --perm.admin -d /etc/filebrowser/filebrowser.db
```

> 配置完成后可以通过 `filebrowser -d /etc/filebrowser/filebrowser.db` 命令启动服务

## 服务管理

为了更好的管理 `filebrowser` 服务，编写 `Unit` 配置文件 `/usr/lib/systemd/system/filebrowser.service`

```ini
[Unit]
Description=File Browser
Documentation=https://filebrowser.org/
After=network.target

[Service]
Type=simple
WorkingDirectory=/etc/filebrowser
ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser/filebrowser.db
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

设置为开机自启并启动服务

```bash
sudo systemctl enable --now filebrowser.service
```