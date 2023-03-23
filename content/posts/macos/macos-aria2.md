---
title: "macOS 安装 Aria2"
date: 2023-02-25T15:03:42+08:00
draft: false
categories: 
- macOS
tags:
- aria2
---


## 安装和配置 aria2

**安装**

```bash
berw install aria2
```

**配置**

```bash
mkdir ~/.aria2
cd ~/.aria2
touch aria2.session

# 生成配置 aria2.conf 文件
cat >aria2.conf<<EOF
dir=/Users/liwanggui/Downloads
disable-ipv6=true

#打开rpc的目的是为了给web管理端用
enable-rpc=true
#rpc-secret=thisisasecret
rpc-allow-origin-all=true
rpc-listen-all=true
rpc-listen-port=6800

#断点续传
continue=true
input-file=/Users/liwanggui/.aria2/aria2.session
save-session=/Users/liwanggui/.aria2/aria2.session

#最大同时下载任务数
max-concurrent-downloads=20
save-session-interval=120

# Http/FTP 相关
connect-timeout=120
#lowest-speed-limit=10K

#同服务器连接数
max-connection-per-server=10
#max-file-not-found=2
#最小文件分片大小, 下载线程数上限取决于能分出多少片, 对于小文件重要
min-split-size=10M

#单文件最大线程数, 路由建议值: 5
split=10
check-certificate=false
#http-no-cache=true
EOF
```

## 配置 macOS 开机启动

创建 `~/Library/LaunchAgents/aria2.plist` 启动文件，写下如下配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>KeepAlive</key>
	<true/>
	<key>Label</key>
	<string>aria2</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/local/bin/aria2c</string>
	</array>
	<key>RunAtLoad</key>
    <true/>
	<key>WorkingDirectory</key>
	<string>/Users/liwanggui/Downloads</string>
</dict>
</plist>
```

> 注意: 修改 `WorkingDirectory` 路径

*检查语法和文件权限*

```bash
plutil ~/Library/LaunchAgents/aria2.plist

chmod 644 ~/Library/LaunchAgents/aria2.plist
```

*启动并添加自动项*

```bash
# 添加自动项
launchctl load ~/Library/LaunchAgents/aria2.plist

# 删除自启动项
launchctl unload ~/Library/LaunchAgents/aria2.plist

# 启动服务
launchctl start aria2

# 停止服务
launchctl stop aria2
```

## 安装 aria2 浏览器插件

> Edge 浏览器安装:  `Aria2 for Edge`

- [参考文档](https://blog.csdn.net/alex_yangchuansheng/article/details/121045393)