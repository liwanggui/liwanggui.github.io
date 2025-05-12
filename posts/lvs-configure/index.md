# 配置 LVS DR 负载均衡


## 环境准备

1. Director Server:  192.168.31.33/24
2. Real Server 1: 192.168.31.31/24
3. Real Server 2: 192.168.31.32/24
4. VIP: 192.168.31.30/32

## 安装配置 ipvs

### 安装 ipvs 管理软件

在 `Director Server` 上安装 `ipvsadm`

```bash
root@lb-01:~# apt install ipvsadm
```

### 配置 ipvs

**配置 vip**

```bash
root@lb-01:~# ip addr add 192.168.31.30/32 brd 192.168.31.30 dev ens32
root@lb-01:~# ip addr show ens32
2: ens32: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:af:9c:1f brd ff:ff:ff:ff:ff:ff
    inet 192.168.31.33/24 brd 192.168.31.255 scope global ens32
       valid_lft forever preferred_lft forever
    inet 192.168.31.30/32 brd 192.168.31.30 scope global ens32
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:feaf:9c1f/64 scope link
       valid_lft forever preferred_lft forever
```

**配置 ipvs 规则**

```bash
# 清空 ipvsadm 配置表
root@lb-01:~# ipvsadm -C
# 设置连接超时值
root@lb-01:~# ipvsadm --set 30 5 60
# 添加虚拟服务器
root@lb-01:~# ipvsadm -A -t 192.168.31.30:80 -s rr -p 20
# 向虚拟服务器添加 RealServer
root@lb-01:~# ipvsadm -a -t 192.168.31.30:80 -r 192.168.31.31:80 -g -w 1
root@lb-01:~# ipvsadm -a -t 192.168.31.30:80 -r 192.168.31.32:80 -g -w 1
# 查看 lvs 状态
root@lb-01:~# ipvsadm -L -n --stats
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  192.168.31.30:80                    0        0        0        0        0
  -> 192.168.31.31:80                    0        0        0        0        0
  -> 192.168.31.32:80                    0        0        0        0        0
```

**参数说明**

- `-C:` 清空 ipvs 所有规则 
- `-A:` 添加虚拟服务器
- `-t:` 使用 tcp 协议, 后接虚拟服务器的 ip 地址和端口
- `-s:` 使用的调度算法
- `-p`: 定义持久时间，能够实现将来自同一个地址的请求始终发往同一个 RealServer
- `-a:` 添加 RealServer
- `-r:` 指定 RealServer 地址和端口
- `-g:` 使用的 DR 实现方式
- `-w:` RealServer 服务器的权重

## RealServer 服务器配置

### 向回环接口（lo）添加 vip

```bash
root@web-01:~# ip addr add 192.168.31.30/32 brd 192.168.31.30 dev lo
```

### 抑制 arp 广播

禁止发送 arp 广播，由于 vip 在多台机器上配置了，如果不抑制广播会造成 ip 地址冲突。

```bash
root@web-01:~# echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore
root@web-01:~# echo 1 > /proc/sys/net/ipv4/conf/lo/arp_ignore
root@web-01:~# echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce
root@web-01:~# echo 2 > /proc/sys/net/ipv4/conf/lo/arp_announce
```

## 在客户机测试 LVS 负载群集

```bash
curl 192.168.31.30
```

> 注意: 至此 lvs 负载均衡集群配置完成，由于 lvs 服务器本身不支持高可用，存在单点故障， 可以配合 `keepalived` 一起使用


## 服务脚本

lvs 的配置是终端上配置的，机器重启后会丢失，那么该如何管理配置呢？ 有两种方法: 

1. ipvsadm 包自带配置信息管理工具，`ipvsadm-save`, `ipvsadm-restore`
2. 开发脚本管理

- ipvsadm-save: 用于导出 lvs 配置
- ipvsadm-restore: 用于从文件中恢复 lvs 配置 

> 也可以使用 ipvsadm 包中的脚本管理 `/etc/init.d/ipvsadm`

### lvs 配置管理

```bash
root@lb-01:~# ipvsadm-save > /etc/ipvsadm.rules   # 等价于 /etc/init.d/ipvsadm save
root@lb-01:~# ipvsadm-restore < /etc/ipvsadm.rules  # 等价于 /etc/init.d/ipvsadm load
root@lb-01:~# ipvsadm -Ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  192.168.31.30:80 rr persistent 20
  -> 192.168.31.31:80             Route   1      0          0
  -> 192.168.31.32:80             Route   1      0          0
```

### lvs 服务器配置脚本

```bash
#!/bin/bash

INTERFACE=ens32
PORT=80
VIP=192.168.31.30
RIP=(
192.168.31.31
192.168.31.32
)

IPVSADM=/usr/sbin/ipvsadm

start() {
    ip addr add ${VIP}/32 brd ${VIP} dev $INTERFACE
    $IPVSADM -C
    $IPVSADM --set 30 5 60
    $IPVSADM -A -t ${VIP}:${PORT} -s rr -p 20
    for (( i = 0; i < echo ${#RIP[*]}; i++ )); do
        $IPVSADM -a -t ${VIP}:${PORT} -r ${RIP[$i]}:${PORT} -g -w 1
    done
    echo "The lvs Server is start!"
}

stop() {
    $IPVSADM -C
    ip addr del ${VIP}/32 brd ${VIP} dev $INTERFACE
    echo "The lvs Server is stop!"
}

status() {
    $IPVSADM -L -n --stats
}

case $1 in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop 
        sleep 1
        start
        ;;
    status)
        status
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart}"
        exit 2
        ;;
esac
```

### RealServer 服务器配置脚本

```bash
#!/bin/bash

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
