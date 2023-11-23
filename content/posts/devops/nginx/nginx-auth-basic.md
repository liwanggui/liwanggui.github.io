---
title: "nginx - 基础身份验证 (auth_basic)"
date: 2021-04-02T13:56:42+08:00
draft: false
categories: 
- devops
- nginx
tags:
- nginx
---

nginx 的 [ngx_http_auth_basic_module](https://nginx.org/en/docs/http/ngx_http_auth_basic_module.html) 模块允许通过使用 “HTTP Basic Authentication” 协议验证用户名和密码来限制对资源的访问，
当站点本身不支持身份验证，又需要添加身份验证时就可以使用此模块来实现

## 配置 auth_basic

```
location / {
    auth_basic           "closed site";
    auth_basic_user_file conf/htpasswd;
}
```

## 准备用户身份验证文件

用户身份验证文件 `conf/htpasswd` 格式如下:

```
# comment
name1:password1
name2:password2:comment
name3:password3
```

> 注意: 用户密码可以使用 `htpasswd` (htpasswd 是 apache web 服务的实用工具) 或 `openssl passwd -apr1` 命令生成

生成用户身份验证文件, 用户: `zhangshan` 密码: `test@123`

```bash
echo "zhangshan:$(openssl passwd -apr1 test@123):张三" >> conf/htpasswd
```
