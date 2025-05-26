---
title: "nginx - 日志轮转"
date: 2021-04-01T18:24:00+08:00
draft: false
categories:
- nginx
tags:
- nginx
---

## 使用 logrotate 管理 nginx 日志

随着时间的推移 nginx 的日志会越来越大，为了减少 nginx 日志的体积大小，使用 logrotate 工具每天对 nginx 日志进行切割处理

*nginx logrotate 配置文件: `/etc/logrotate.d/nginx`*

```bash
/usr/local/nginx/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    dateext
    delaycompress
    notifempty
    sharedscripts
    postrotate
       if [ -f /usr/local/nginx/logs/nginx.pid ]; then
               kill -USR1 `cat /usr/local/nginx/logs/nginx.pid`
       fi
    endscript
}
```

> 更多 `logrotate` 配置参数请参考 man 手册 `man logrotate`