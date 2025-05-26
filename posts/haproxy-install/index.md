# HAPrxoy 的简单使用


## HAPrxoy 介绍

HAProxy 是一个使用 C 语言编写的自由及开放源代码软件，其提供高可用性、负载均衡，以及基于 tcp 和 http 的应用程序代理。

- `mode http`：七层反向代理，受端口数量限制
- `mode tcp`：四层反向代理，不受套接字文件数量限制

HAProxy 特别适用于那些负载特大的 web 站点，这些站点通常又需要会话保持或七层处理。HAProxy 运行在当前的硬件上，完全可以支持数以万计的并发连接。并且它的运行模式使得它可以很简单安全的整合进您当前的架构中，同时可以保护你的 web 服务器不被暴露到网络上。

> 更多内容请查看 [官方网站](http://www.haproxy.org) -- [官方文档](http://cbonte.github.io/haproxy-dconv/)

## 安装 HAProxy

以 `Ubuntu Server 18.04` 操作系统为例, [官方教程](https://haproxy.debian.net/)

*您需要使用以下命令启用专用的PPA：*

```bash
root@lb-01:~# apt-get install --no-install-recommends software-properties-common
root@lb-01:~# add-apt-repository ppa:vbernat/haproxy-2.2
```

*然后，使用以下命令：*

```bash
root@lb-01:~# apt-get install haproxy=2.2.\*
```

> 您将获得最新版本的 HAProxy 2.2（并坚持使用此分支）。


## HAProxy 服务配置

### 程序环境

- 主程序：`/usr/sbin/haproxy`
- 主配置文件：`/etc/haproxy/haproxy.cfg`
- systemd 服务配置文件：`/lib/systemd/system/haproxy.service`

### 配置文件说明

```bash
root@lb-01:/etc/haproxy# cat haproxy.cfg
# 全局配置段
global
    log /dev/log local0
    log /dev/log local1 notice

    # 指定最大连接数
    maxconn 200000

    # 限制 haproxy 根路径
    chroot /var/lib/haproxy

    # 指定 haproxy 管理 socket 文件并与指定的进程绑定(process)
    stats socket /run/haproxy/admin1.sock mode 660 level admin expose-fd listeners process 1
    stats socket /run/haproxy/admin2.sock mode 660 level admin expose-fd listeners process 2

    stats timeout 30s

    # 指定 haproxy 运行的用户和组
    user haproxy
    group haproxy

    # 开启守护进程
    daemon

    # 避免对于后端检测同时并发造成的问题，设置错开时间比，范围0到50，一般设置2-5较好
    spread-checks 5
    
    # 开启多进程
    nbproc 2
    # 设定进程与 CPU 绑定
    cpu-map 1 0
    cpu-map 2 1


# 默认参数配置段， 为 frontend, listen, backend 提供默认配置
defaults
    log global
    # 使用 http 模式
    mode http
    # 日志类别 http 日志格式
    option httplog
    
    # 对应的服务器挂掉后,强制定向到其他健康的服务器
    option redispatch

    # 不记录健康检查的日志信息
    option dontlognull 

    # 开启 ip 透传，向后端服务发送真实客户端地址
    option forwardfor
    
    # 开启 http 长连接
    option http-keep-alive

    # 长连接超时时间设置
    timeout http-keep-alive 120s
    # 连接超时时间设置
    timeout connect 60s
    # 与后端服务器连接超时时间设置
    timeout server 600s
    # 与客户端连接超时时间设置
    timeout client 600s
    # check 检测超时时间设置
    timeout check 5s

    # 配置默认 http 错误响应码对应的页面文件
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# 开启状态页
listen stauts
    mode http
    bind :9999
    stats enable
    # 指定状态面的 uri 路径
    stats uri /haproxy-status
    # 配置状态页的用户名和密码
    stats auth  haproxy:liwg

# 配置 http 代理
listen http
    # 代理监控端口
    bind *:80
    # 使用的负载均衡调度算法
    balance roundrobin
    # 在后端启用基于 cookie 的持久性
    cookie SRVID insert indirect nocache
    # 后端服务器配置列表, cookie: 指定 cookie值， check: 启用健康检测 
    # inter 检测间隔， fall 检测失败次数， rise 重试次数
    server server1 192.168.31.31:80 cookie 31 check inter 3s fall 3 rise 5
    server server2 192.168.31.32:80 cookie 32 check inter 3s fall 3 rise 5
```

> 当使用 haproxy 负载均衡集群时，监听的地址为 vip 时，服务会无法启动，
> 这是因为 Linux 绑定了一个网卡上没有配置的 ip 地址导致的，
> 此时可以通过修改 Linux 内核 `net.ipv4.ip_nonlocal_bind = 1` 参数解决

## 启动 HAProxy 服务并测试

### 启动 HAProxy 服务

```bash
root@lb-01:/etc/haproxy# systemctl start haproxy.service
root@lb-01:/etc/haproxy# ss -anptl | grep haproxy
LISTEN   0         128                 0.0.0.0:9999             0.0.0.0:*        users:(("haproxy",pid=26699,fd=12),("haproxy",pid=26697,fd=12))
LISTEN   0         128                 0.0.0.0:80               0.0.0.0:*        users:(("haproxy",pid=26699,fd=14),("haproxy",pid=26697,fd=14))
root@lb-01:/etc/haproxy# ps -ef | grep haproxy
root      26690      1  0 14:32 ?        00:00:00 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -S /run/haproxy-master.sock
haproxy   26697  26690  0 14:32 ?        00:00:00 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -S /run/haproxy-master.sock
haproxy   26699  26690  0 14:32 ?        00:00:00 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -S /run/haproxy-master.sock
```

> 端口 `9999` 是 `haproxy` 状态页，端口 `80` 用于后端服务器负载均衡， 通过 `ps` 命令， 可以看到 `haproxy` 开启了多进程 

### 动态下线/上线后端服务器

*动态下线后端服务器*

```bash
root@lb-01:/etc/haproxy# echo 'disable server http/server2' | socat stdio /run/haproxy/admin1.sock
root@lb-01:/etc/haproxy# echo 'disable server http/server2' | socat stdio /run/haproxy/admin2.sock
```

> 注意： 当输入软下线的命令时 `haproxy` 依旧可以将用户的请求调度到后端已经下线的服务器上，这是因为 `haproxy` 的 `socket` 文件的关系，一个 `socket` 文件对应一个进程，当 `haproxy` 处于多进程的模式下时，就需要有多个 `socket` 文件，并将其和进程进行绑定，对后端服务器进行软下线时需要对所有的 `socket` 文件下达软下线的指令。

> 可以通过 http://haproxy_ipaddress:9999/haproxy-status 查看后端服务器状态

*动态上线后端服务器*

```bash
root@lb-01:/etc/haproxy# echo 'enable server http/server2' | socat stdio /run/haproxy/admin1.sock
root@lb-01:/etc/haproxy# echo 'enable server http/server2' | socat stdio /run/haproxy/admin2.sock
```
