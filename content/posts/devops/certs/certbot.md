---
title: "使用 certbot 自动申请证书"
date: 2021-12-06T16:48:21+08:00
draft: false
categories: 
- devops
tags:
- certbot
---

由于生产环境中有使用 certbot 工具为 apache 的虚拟主机自动申请证书，记录下 certbot 配置操作过程

- certbot 官方站点: [https://certbot.eff.org/](https://certbot.eff.org/)

## 安装 certbot

certbot 为 python 项目可以直接使用 pip 工具进行安装，在 centos 的 epel 源中也有相应的 rpm 包可以使用 yum 安装

### YUM 安装

```bash
yum install epel-release
yum install certbot python2-certbot-apache
```

> 注意: 有可能会安装失败

### PIP 安装 (推荐)

*安装 certbot-apache 依赖包*

```bash
yum install -y augeas
```

*安装 certbot 环境*

```bash
python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot certbot-apache
ln -s /opt/certbot/bin/certbot /usr/bin/certbot
```

> certbot-apache 是 certbot 支持 apache 的插件

## 申请证书

为 apache 虚拟主机自动申请证书

```bash
certbot --apache
```

## 证书自动续期

加入计划任务，每周一检查一次证书有效期，到期就自动续期

```bash
0 0 * * 1 /usr/bin/certbot renew &>/dev/null
```

> 根据提示信息进行操作即可

证书申请完成后 certbot 会自动修改 apache 配置文件，添加 https 相关配置，文件名为 虚拟主机配置文件名加上 `le-ssl` 字符，原先的虚拟主机配置会加上 http 跳转至 https 的配置

```bash
[soperator@iZm5ees9if066t4cmhfx3kZ conf.d]$ ls
autoindex.conf   php.conf  ssl.conf      virtualhost.conf         welcome.conf
enviroment.conf  README    userdir.conf  virtualhost-le-ssl.conf  
```

**http 跳转 https 配置**

```bash
RewriteEngine on
RewriteCond %{SERVER_NAME} =test.liwanggui.com
RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
```

**自动生成配置文件内容: virtualhost-le-ssl.conf**

```bash
<IfModule mod_ssl.c>
<VirtualHost *:443>
    DocumentRoot "/data/www/test"
    ServerName test.liwanggui.com
    <Directory "/data/www/test">
        Require all granted
        AllowOverride all
        Options -indexes +FollowSymLinks
    </Directory>
SSLCertificateFile /etc/letsencrypt/live/test.liwanggui.com/cert.pem
SSLCertificateKeyFile /etc/letsencrypt/live/test.liwanggui.com/privkey.pem
Include /etc/letsencrypt/options-ssl-apache.conf
SSLCertificateChainFile /etc/letsencrypt/live/test.liwanggui.com/chain.pem
</VirtualHost>
</IfModule>
```
