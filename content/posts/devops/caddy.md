---
title: "Caddy 一个简单的 Web 服务"
date: 2021-08-23T15:50:36+08:00
draft: false
categories: 
- devops
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

```caddy
# The Caddyfile is an easy way to configure your Caddy web server.
#
# Unless the file starts with a global options block, the first
# uncommented line is always the address of your site.
#
# To use your own domain name (with automatic HTTPS), first make
# sure your domain's A/AAAA DNS records are properly pointed to
# this machine's public IP, then replace ":80" below with your
# domain name.

:80 {
	# Set this path to your site's directory.
	root * /usr/share/caddy

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

## 文件服务器

修改 `Caddyfile` , 使用 `fileserver browse` 指令启用 `Caddy` 文件服务功能，配置如下：

```
dl.liwanggui.com {
	root * /usr/share/caddy
	file_server browse
}
```

## 反向代理 

`Caddy` 使用 `reverse_proxy` 指令启用反向代理功能

```
liwanggui.com {
	reverse_proxy localhost:8080
}
```

## PHP 站点

使用 `php_fastcgi` 指令来配置 PHP 站点

```
liwanggui.com {
    root * /data/www/typecho
    php_fastcgi localhost:9000
}
```

## 返回客户端地址

```
myip.liwanggui.com {
    respond {remote_host}
}
```