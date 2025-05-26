# Keepalived 高可用简单入门


## Keepalived 介绍

`Keepalived` 是一个基于 VRRP 协议来实现的 WEB 服务高可用方案，可以利用其来避免单点故障。使用多台节点安装keepalived。其他的节点用来提供真实的服务（RealServer），同样的，他们对外表现一个虚拟的IP（vip）。主服务器宕机的时候，备份服务器就会接管虚拟IP，继续提供服务，从而保证了高可用性。

## Keepalived 简单应用

> 拓扑图

### 环境准备

本次实验需要准备2台后端 Web 服务器，用于提供真实服务，最前端挂2台 nginx 反向代理并安装 keepalived 实现高可用。 总共4台机器。

**实现的目的**

当用户请求 web 服务器时，请求先到 keeplived 主服务器，然后 keepalived 主服务器根据 nginx 的负载均衡配置规则 选择 1台后端的 web 服务器将用户的请求转发给它，keepalived 主服务器拿到相应的数据后在响应给用户。如果keepalived 主服务器的 nginx 服务挂了，将由备份 keepalived 服务器接手为用户提供服务。

> nginx：反向代理、负载均衡配置参考 nginx 文档

## 安装配置 keepalived

### 安装 keepalived

```bash
root@lb-01:~# apt install keepalived
# 复制一份示例配置文件
root@lb-01:~# cp /usr/share/doc/keepalived/samples/keepalived.conf.sample /etc/keepalived/keepalived.conf
```

### keepalived 高可用配置

`keepalived` 的配置文件默认位于：`/etc/keepalived/keepalived.conf`

```config
! Configuration File for keepalived

global_defs {
  ! 运行Keepalived服务器的一个标识，发邮件时显示在邮件主题中。
   router_id LVS_DEVEL
}

! 定义 nginx 服务检测脚本
vrrp_script check_nginx {
    script "/bin/bash /etc/keepalived/chk_ngx.sh"
    ! 检查时间间隔，2秒
    interval 2
}

! 定义高可用实例
vrrp_instance VI_1 {
    ! 指明当前服务的角色，备用为 BACKUP
    state MASTER
    ! 指定监测的网络接口
    interface ens32
    ! 虚拟路由标识，同一个实例使用唯一的标识，master与backup必须是一致的
    virtual_router_id 50
    ! 定义节点的优先级，数字越大，优先级越高。
    priority 100
    ! 主从主机之间同步检查的时间间隔
    advert_int 1
    ! 不抢占，恢复后不进行切换，主挂了再起来不会抢回身份。防止 vip 飘来飘去影响稳定性
    nopreempt
    ! 用于设置节点间通信验证类型和密码
    authentication {
       auth_type PASS
       auth_pass 11111
    }

    ! 设置虚拟 ip 地址
    virtual_ipaddress {
       192.168.31.30
    }

    ! 检查条件
    track_script {
        check_nginx
    }
}
```

*/etc/keepalived/chk_ngx.sh*

```bash
#!/bin/bash

/bin/pidof nginx &> /dev/null
## 也可使用 killall -0 nginx 探测服务状态

if [[ $? -ne 0 ]]; then
    echo 'nginx is stop'
    exit 1
fi
```

> 将 `keepalived.conf` 和 `chk_ngx.sh` 复制到备份主机上，修改 `keepalived.conf` 文件 `state BACKUP`, `priority 90`, 删除 `nopreempt` 即可。


## 安装反代和Web服务

### 安装 Web 服务

这里使用 `nginx` 来提供一个简单 Web 页面用来测试

*web-01*

```bash
root@web-01:~# apt install nginx
root@web-01:~# echo '<h1>Welcome to nginx 11111111111!</h1>' > /var/www/html/index.nginx-debian.html
root@web-01:~# systemctl start nginx
root@web-01:~# curl localhost
<h1>Welcome to nginx 11111111111!</h1>
```

*web-02*

```bash
root@web-02:~# apt install nginx
root@web-02:~# echo '<h1>Welcome to nginx 22222222!</h1>' > /var/www/html/index.nginx-debian.html
root@web-02:~# systemctl start nginx
root@web-02:~# curl localhost
<h1>Welcome to nginx 22222222!</h1>
```

### 安装配置 nginx 反向代理

在两台 `keepalived` 机器上安装 `nginx` 并配置反向代理到后端两台 Web 服务器, 两台机的配置是一样的。

```bash
root@lb-01:~# apt install nginx
root@lb-01:~# cat /etc/nginx/sites-available/default
upstream web {
  server 192.168.31.31;
  server 192.168.31.32;
}

server {
  listen 80 default_server;
  listen [::]:80 default_server;
  root /var/www/html;
  index index.html index.htm index.nginx-debian.html;
  server_name _;
  location / {
      proxy_pass http://web;
  }
}
root@lb-01:~# systemctl restart nginx
```

## 测试 keepalived 高可用

### 启用 keepalived 服务

```bash
root@lb-01:~# systemctl start keepalived.service
root@lb-01:~# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ens32: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:af:9c:1f brd ff:ff:ff:ff:ff:ff
    inet 192.168.31.33/24 brd 192.168.31.255 scope global ens32
       valid_lft forever preferred_lft forever
    inet 192.168.31.30/32 scope global ens32
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:feaf:9c1f/64 scope link
       valid_lft forever preferred_lft forever
```

*日志信息*

```
Feb 27 08:10:46 lb-01 systemd[1]: Starting Keepalive Daemon (LVS and VRRP)...
Feb 27 08:10:46 lb-01 Keepalived[8259]: Starting Keepalived v1.3.9 (10/21,2017)
Feb 27 08:10:46 lb-01 Keepalived[8259]: Opening file '/etc/keepalived/keepalived.conf'.
Feb 27 08:10:46 lb-01 systemd[1]: Started Keepalive Daemon (LVS and VRRP).
Feb 27 08:10:46 lb-01 Keepalived[8275]: Starting Healthcheck child process, pid=8276
Feb 27 08:10:46 lb-01 Keepalived[8275]: Starting VRRP child process, pid=8277
Feb 27 08:10:46 lb-01 Keepalived_healthcheckers[8276]: Opening file '/etc/keepalived/keepalived.conf'.
Feb 27 08:10:46 lb-01 Keepalived_vrrp[8277]: Registering Kernel netlink reflector
Feb 27 08:10:46 lb-01 Keepalived_vrrp[8277]: Registering Kernel netlink command channel
Feb 27 08:10:46 lb-01 Keepalived_vrrp[8277]: Registering gratuitous ARP shared channel
Feb 27 08:10:46 lb-01 Keepalived_vrrp[8277]: Opening file '/etc/keepalived/keepalived.conf'.
Feb 27 08:10:46 lb-01 Keepalived_vrrp[8277]: WARNING - default user 'keepalived_script' for script execution does not exist - please create.
Feb 27 08:10:46 lb-01 Keepalived_vrrp[8277]: (VI_1): Warning - nopreempt will not work with initial state MASTER
Feb 27 08:10:46 lb-01 Keepalived_vrrp[8277]: SECURITY VIOLATION - scripts are being executed but script_security not enabled.
Feb 27 08:10:46 lb-01 Keepalived_vrrp[8277]: Using LinkWatch kernel netlink reflector...
Feb 27 08:10:46 lb-01 Keepalived_vrrp[8277]: VRRP_Script(check_nginx) succeeded
Feb 27 08:10:47 lb-01 Keepalived_vrrp[8277]: VRRP_Instance(VI_1) Transition to MASTER STATE
Feb 27 08:10:48 lb-01 Keepalived_vrrp[8277]: VRRP_Instance(VI_1) Entering MASTER STATE
```

> 从上面的信息可以看到， keepalived 自动为 ens32 网卡添加一个 vip，服务角色为 master

**开启备份节点服务**

```bash
root@lb-02:/etc/keepalived# systemctl start keepalived.service
```

### 测试

测试使用 vip 访问 Web 服务

```bash
root@web-01:~# while :; do curl 192.168.31.30; sleep .5; done
<h1>Welcome to nginx 22222222!</h1>
<h1>Welcome to nginx 11111111111!</h1>
<h1>Welcome to nginx 22222222!</h1>
<h1>Welcome to nginx 11111111111!</h1>
<h1>Welcome to nginx 22222222!</h1>
<h1>Welcome to nginx 11111111111!</h1>
```

停止 keepalived 主服务的 nginx 服务，查看 vip 是否转移。Web 服务是否可用。

```bash
root@lb-01:~# systemctl stop nginx
```

*主节点日志信息*

```
Feb 27 08:17:15 lb-01 systemd[1]: Stopping A high performance web server and a reverse proxy server...
Feb 27 08:17:15 lb-01 systemd[1]: Stopped A high performance web server and a reverse proxy server.
Feb 27 08:17:17 lb-01 Keepalived_vrrp[8277]: /bin/bash /etc/keepalived/chk_ngx.sh exited with status 1
Feb 27 08:17:17 lb-01 Keepalived_vrrp[8277]: VRRP_Script(check_nginx) failed
Feb 27 08:17:18 lb-01 Keepalived_vrrp[8277]: VRRP_Instance(VI_1) Entering FAULT STATE
Feb 27 08:17:18 lb-01 Keepalived_vrrp[8277]: VRRP_Instance(VI_1) Now in FAULT state
Feb 27 08:17:19 lb-01 Keepalived_vrrp[8277]: /bin/bash /etc/keepalived/chk_ngx.sh exited with status 1
```

> 日志信息表明，检测到 nginx 服务停止，检测失败，keepalived 进入 FAULT 状态。

*查看备用节点的日志和网卡信息*

```tail
root@lb-02:/etc/keepalived# systemctl start keepalived.service
root@lb-02:/etc/keepalived# tail /var/log/syslog
Feb 27 08:14:08 ubuntu Keepalived_vrrp[10287]: Registering gratuitous ARP shared channel
Feb 27 08:14:08 ubuntu Keepalived_vrrp[10287]: Opening file '/etc/keepalived/keepalived.conf'.
Feb 27 08:14:08 ubuntu Keepalived_vrrp[10287]: WARNING - default user 'keepalived_script' for script execution does not exist - please create.
Feb 27 08:14:08 ubuntu Keepalived_vrrp[10287]: SECURITY VIOLATION - scripts are being executed but script_security not enabled.
Feb 27 08:14:08 ubuntu Keepalived_vrrp[10287]: Using LinkWatch kernel netlink reflector...
Feb 27 08:14:08 ubuntu Keepalived_vrrp[10287]: VRRP_Instance(VI_1) Entering BACKUP STATE
Feb 27 08:14:08 ubuntu Keepalived_vrrp[10287]: VRRP_Script(check_nginx) succeeded
Feb 27 08:17:01 ubuntu CRON[10641]: (root) CMD (   cd / && run-parts --report /etc/cron.hourly)
Feb 27 08:17:18 ubuntu Keepalived_vrrp[10287]: VRRP_Instance(VI_1) Transition to MASTER STATE
Feb 27 08:17:19 ubuntu Keepalived_vrrp[10287]: VRRP_Instance(VI_1) Entering MASTER STATE
root@lb-02:/etc/keepalived# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ens32: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:0c:ee:46 brd ff:ff:ff:ff:ff:ff
    inet 192.168.31.34/24 brd 192.168.31.255 scope global ens32
       valid_lft forever preferred_lft forever
    inet 192.168.31.30/32 scope global ens32
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fe0c:ee46/64 scope link
       valid_lft forever preferred_lft forever
```

> 从日志和网卡信息可以看出，备用节点接替了主节点的 vip ，并将自己提升为主节点

*客户端请求测试信息*

```
<h1>Welcome to nginx 22222222!</h1>
<h1>Welcome to nginx 11111111111!</h1>
curl: (7) Failed to connect to 192.168.31.30 port 80: Connection refused
curl: (7) Failed to connect to 192.168.31.30 port 80: Connection refused
curl: (7) Failed to connect to 192.168.31.30 port 80: Connection refused
curl: (7) Failed to connect to 192.168.31.30 port 80: Connection refused
curl: (7) Failed to connect to 192.168.31.30 port 80: Connection refused
<h1>Welcome to nginx 22222222!</h1>
<h1>Welcome to nginx 11111111111!</h1>
<h1>Welcome to nginx 22222222!</h1>
```

> 可以看到在 vip 切换时，有一些无法响应的请求，之后又立即恢复了

