# Keepalived 实现 LVS 高可用负载均衡群集


## 环境准备

两台调度服务器: 安装 keepalived + ipvsadm
两台真实服务器: 安装 nginx 提供 Web 服务

- web-01: 192.168.31.31/24
- web-02: 192.168.31.32/24
- lb-01: 192.168.31.33/24
- lb-02: 192.168.31.34/24
- vip: 192.168.31.30

## 配置 Real Server 服务器

安装 `nginx` 来提供一个简单 Web 页面用来测试

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

## 配置 lvs 调用可用集群

### 安装 keepalived 与 ipvs 管理工具

```bash
root@lb-01:~# apt install keepalived ipvsadm
```

### 配置 keepalived

*配置主节点 `/etc/keepalived/keepalived.conf`*

```config
! Configuration File for keepalived

global_defs {
   router_id LVS_DEVEL
}

vrrp_instance VI_1 {
    state MASTER
    interface ens32
    virtual_router_id 50
    priority 100
    advert_int 1
    nopreempt

    authentication {
       auth_type PASS
       auth_pass 11111
    }

    virtual_ipaddress {
       192.168.31.30
    }
}

virtual_server 192.168.31.31 80 {
    delay_loop 6
    
    ! 使用 rr 调度算法
    lb_algo rr

    ! 使用 DR 直接路由工作方式
    lb_kind DR  
    
    ! 会话保持时间，单位是秒。这个选项对动态网页是非常有用的，为集群系统中的 SEEION 共享
    ! 提供了一个很好的解决方案。有了这个会话保持功能，用户的请求会一直分发到同一个服务节点，
    ! 直到超过这个会话的保持时间。 注意: 这个会话保持时间是最大无响应超时时间。如果用户一直
    ! 在操作动态页面，是不受这个时间限制的。
    persistence_timeout 50

    ! 使用转发的协议类型， 也可以是 UDP    
    protocol TCP

    ! 真实提供服务器的机器
    real_server 192.168.31.31 80 {
        ! 定义权重
        weight 3

        ! real_server 状态检测，单位为秒 
        TCP_CHECK {
            ! 表示3秒无响应超时
            connect_timeout 3
            ! 表示重试次数
            nb_get_retry 3
            ! 重试间隔
            delay_before_retry 3
        }
    }

    real_server 192.168.31.32 80 {
        weight 3
        TCP_CHECK {
            connect_timeout 3
            nb_get_retry 3
            delay_before_retry 3
        }
    }
}
```

*配置备用节点 `/etc/keepalived/keepalived.conf`*

```config
! Configuration File for keepalived

global_defs {
   router_id LVS_DEVEL
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens32
    virtual_router_id 50
    priority 90
    advert_int 1

    authentication {
       auth_type PASS
       auth_pass 11111
    }

    virtual_ipaddress {
       192.168.31.30
    }
}

virtual_server 192.168.31.31 80 {
    delay_loop 6
    lb_algo rr
    lb_kind DR  
    persistence_timeout 50
    protocol TCP

    real_server 192.168.31.31 80 {
        weight 3
        TCP_CHECK {
            connect_timeout 3
            nb_get_retry 3
            delay_before_retry 3
        }
    }

    real_server 192.168.31.32 80 {
        weight 3
        TCP_CHECK {
            connect_timeout 3
            nb_get_retry 3
            delay_before_retry 3
        }
    }
}
```

### 启动 keepalivd 服务

启动 `keepalived` 服务并查看 `ipvs` 规则， `vip` 配置情况

```bash
root@lb-01:/etc/keepalived# systemctl start keepalived.service
root@lb-01:/etc/keepalived# ipvsadm -Ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  192.168.31.30:80 rr persistent 50
  -> 192.168.31.31:80             Route   3      0          0
  -> 192.168.31.32:80             Route   3      0          0
root@lb-01:/etc/keepalived# ip addr show ens32
2: ens32: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:af:9c:1f brd ff:ff:ff:ff:ff:ff
    inet 192.168.31.33/24 brd 192.168.31.255 scope global ens32
       valid_lft forever preferred_lft forever
    inet 192.168.31.30/32 scope global ens32
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:feaf:9c1f/64 scope link
       valid_lft forever preferred_lft forever
```

> 备用节点的 keepalived 服务也启动起来

### 配置 RealServer 

由于 lvs 的 DR 方式，需要在两台 Real Server 上也配置 vip 地址，并且还需要抑制 arp 广播。 使用以下脚本完成。

```bash
#!/bin/bash
# 
# filename: lvs-vip.sh
#

VIP=192.168.31.30
INTERFACE=lo

case $1 in
  start)
      echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore
      echo 1 > /proc/sys/net/ipv4/conf/lo/arp_ignore
      echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce
      echo 2 > /proc/sys/net/ipv4/conf/lo/arp_announce
      ip addr add ${VIP}/32 brd ${VIP} dev $INTERFACE
      echo "The RS Server is Ready!"
      ;;
      
  stop)
      ip addr del ${VIP}/32 brd ${VIP} dev $INTERFACE
      echo 0 > /proc/sys/net/ipv4/conf/all/arp_ignore
      echo 0 > /proc/sys/net/ipv4/conf/lo/arp_ignore
      echo 0 > /proc/sys/net/ipv4/conf/all/arp_announce
      echo 0 > /proc/sys/net/ipv4/conf/lo/arp_announce
      echo "The RS Server is Canceled!"
      ;;

  *)
      echo $"Usage: $0 {start|stop|restart}"
      exit 1
      ;;
esac
```

*启用 vip*

```bash
root@web-01:~# mv lvs-vip.sh /usr/local/bin/
root@web-01:~# chmod +x /usr/local/bin/lvs-vip.sh
root@web-01:~# lvs-vip.sh start
The RS Server is Ready!
```

## 测试 lvs 高可用集群

测试过程略，请自行测试...

可以将主 lvs 服务器宕机，然后查看服务是否会中断， 备用 lvs 服务器是否能接手，并正确配置 vip 提供调度服务。
