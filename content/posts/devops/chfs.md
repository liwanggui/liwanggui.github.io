---
title: "跨平台简易文件共享工具"
date: 2022-08-07T08:22:27+08:00
draft: false
categories: 
- devops
tags:
- chfs
---

## 简介

CuteHttpFileServer/chfs是一个免费的、HTTP协议的文件共享服务器，使用浏览器可以快速访问。它具有以下特点：

- 单个文件，核心功能无需其他文件
- 跨平台运行，支持主流平台：Windows，Linux和Mac
- 界面简洁，简单易用
- 支持扫码下载和手机端访问，手机与电脑之间共享文件非常方便
- 支持账户权限控制和地址过滤
- 支持快速分享文字片段
- 支持webdav协议
- 与其他常用文件共享方式（如FTP，飞秋，网盘，自己建站）相比，具有使用简单，适用场景更多的优点，在个人使用以及共享给他人的场景中非常方便快捷。


> CuteHttpFileServer [官方站点](http://iscute.cn/chfs) | [软件下载地址](http://iscute.cn/tar/chfs/)

## 部署

这里以 linux 环境为例

下载安装

```bash
wget http://iscute.cn/tar/chfs/2.0/chfs-linux-amd64-2.0.zip
unzip chfs-linux-amd64-2.0.zip
chmod +x chfs
mv chfs /usr/bin/
```

准备配置文件 `/etc/chfs/chfs.ini`, 这里以官方提供的模板进行修改 [chfs.ini](http://iscute.cn/asset/chfs.ini)

```ini
#---------------------------------------
# 请注意：
#     1，如果不存在键或对应值为空，则不影响对应的配置
#     2，配置项的值，语法如同其对应的命令行参数
#---------------------------------------

# 监听端口
port=80

# 共享根目录，通过字符'|'进行分割
# 注意：
#     1，带空格的目录须用引号包住，如 path="c:\a uply name\folder"
#     2，可配置多个path，分别对应不同的目录
path=/data/fileserver

# IP地址过滤
allow=

#----------------- 账户控制规则 -------------------
# 注意：该键值可以同时存在多个，你可以将每个用户的访问规则写成一个rule，这样比较清晰，如：
#     rule=::
#     rule=root:123456:RW
#     rule=readonlyuser:123456:R
# 禁止匿名访问
rule=::
rule=lwg:123456:RW

# 用户操作日志存放目录，默认为空
# 如果赋值为空，表示禁用日志
log=/var/log/chfs

# 网页标题
html.title=

# 网页顶部的公告板。可以是文字，也可以是HTML标签，此时，需要适用一对``(反单引号，通过键盘左上角的ESC键下面的那个键输出)来包住所有HTML标签。几个例子：
#     1,html.notice=内部资料，请勿传播
#     2,html.notice=`<img src="https://mat1.gtimg.com/pingjs/ext2020/qqindex2018/dist/img/qq_logo_2x.png" width="100%"/>`
#     3,html.notice=`<div style="background:black;color:white"><p>目录说明：</p><ul>一期工程：一期工程资料目录</ul><ul>二期工程：二期工程资料目录</ul></div>`
html.notice=

# 是否启用图片预览(网页中显示图片文件的缩略图)，true表示开启，false为关闭。默认开启
image.preview=true

# 下载目录策略。disable:禁用; leaf:仅限叶子目录的下载; enable或其他值:不进行限制。
# 默认值为 enable
folder.download=enable

#-------------- 设置生效后启用HTTPS，注意监听端口设置为443-------------
# 指定certificate文件
ssl.cert=
# 指定private key文件
ssl.key=

# 设置会话的生命周期，单位：分钟，默认为30分钟
session.timeout=
```


配置为系统服务

```bash
cat >/usr/lib/systemd/system/chfs.service<<EOF
[Unit]
Description=Cute HTTP File Server
Documentation=http://iscute.cn/chfs
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/chfs --file /etc/chfs/chfs.ini
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable chfs.service
systemctl start chfs.service
```

> 部署完成后，可以在浏览器中打开 http://<your_server_ip> 