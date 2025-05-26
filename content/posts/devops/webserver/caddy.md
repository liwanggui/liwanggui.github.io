---
title: "Caddy 一个简单的 Web 服务"
date: 2021-08-23T15:50:36+08:00
draft: false
categories: 
- webserver
tags:
- caddy
---

Caddy 是一个简单易用的 Web 服务端应用，它可以自动为域名申请证书，自动续期等...

- 官方文档: [https://caddyserver.com/docs/](https://caddyserver.com/docs/)

## 安装

以 `Ubuntu` 为例，其它安装方式请参考: [https://caddyserver.com/docs/install#static-binaries](https://caddyserver.com/docs/install#static-binaries)

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo tee /etc/apt/trusted.gpg.d/caddy-stable.asc
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

## 配置

通过包安装 `Caddy` 的配置文件默认在 `/etc/caddy` 目录，配置文件为 `Caddyfile`

```caddyfile
:80 {
	# Set this path to your site's directory.
	root * /usr/share/caddy
	file_server
	# Enable the static file server.
	# file_server browse

	# Another common task is to set up a reverse proxy:
	# reverse_proxy localhost:9090

	# Or serve a PHP site through php-fpm:
	# php_fastcgi localhost:9000
}
```

使用 `sudo systemctl start caddy` 启动 Caddy 

> 现在你可以在浏览器中输入 http://localhost 访问 caddy 默认页


*caddy.service*

```
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```

## 示例

### 文件服务器

修改 `Caddyfile` , 使用 `fileserver browse` 指令启用 `Caddy` 文件服务功能，配置如下：

```
dl.liwanggui.com {
	root * /usr/share/caddy
	file_server browse
}
```

### 反向代理 

`Caddy` 使用 `reverse_proxy` 指令启用反向代理功能

> 语法参考: https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#syntax

```
liwanggui.com {
	reverse_proxy localhost:8080
}
```

### PHP 站点

使用 `php_fastcgi` 指令来配置 PHP 站点

```
liwanggui.com {
    root * /data/www/typecho
    php_fastcgi localhost:9000
}
```

### 返回客户端地址

```
myip.liwanggui.com {
    respond {remote_host}
}
```

### 子路径配置

目录结构如下:

```
├── bar
│   └── index.html
└── root
    └── index.html
```

实现

```
liwanggui.com ====> root/index.html
liwanggui.com/abc ====> bar/index.html
```

Caddy 配置如下

```
liwanggui.com {

	# 重定向 /abc -> /abc/
    redir /abc /abc/  

	# 匹配以 /abc/ 开头的请求
	# handle_path 会去除 /abc 前缀，
	# 如果不去除 /abc, 访问文件的路径是 /bar/abc/index.html (此路径是不存在的，返回 404)
	# 去除 /abc 前缀，访问文件的路径是 /bar/index.html 
    handle_path /abc/* {
        root * /bar
        file_server
    }

	# 匹配所有
    handle {
        root * /root
        file_server
    }
}
```

等价于 nginx 的配置如下:

```
server {
	listen 80;
	server_name  liwanggui.com;

	location / {
		root /foo;
	}

	location /abc/ {
		alias /foo/bar/;
	}
}   
```