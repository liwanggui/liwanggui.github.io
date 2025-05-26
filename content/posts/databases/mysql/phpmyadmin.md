---
title: "使用 phpMyAdmin 登录任意数据库服务器"
date: 2019-09-24T21:18:45+08:00
draft: false
categories: 
- mysql
tags:
- phpMyAdmin
---

## 使用 phpMyAdmin 登录任意数据库服务器

安装完成 `phpMyAdmin` 后, 如果你想在页面手动输入服务器地址进行连接，可以参考以下配置项

- 官方文档: [https://docs.phpmyadmin.net/en/latest/config.html#cfg_AllowArbitraryServer](https://docs.phpmyadmin.net/en/latest/config.html#cfg_AllowArbitraryServer)

编辑 `libraries/config.default.php` 找到 `$cfg['AllowArbitraryServer']` 配置项，将值改为 `true` 即可

```php
$cfg['AllowArbitraryServer'] = true;
```
