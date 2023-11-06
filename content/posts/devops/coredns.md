---
title: "部署 CoreDNS 为内部 DNS 服务器"
date: 2023-11-06T14:08:21+08:00
draft: false
categories: 
- coredns
tags:
- dns
---

本例使用 CoreDNS + ETCD 为内部主机提供 DNS 解析服务

## 部署 ETCD

这里采用 yum 源直接安装部署 etcd 单实例，详细部署方法可以参考 [部署 etcd 集群](/posts/etcd-cluster/)

```bash
yum install etcd
systemctl enable --now etcd
```

> 注意: CroeDNS 需要 etcd 3.5 及以上版本

## 部署 CoreDNS

本例直接使用容器启动 coredns 服务，具体操作过程如下

*准备配置文件 `Corefile`, 以解析 `example.net` 域名为例*

```
example.net:53 {
    etcd {
        path /skydns
        endpoint http://localhost:2379
    }
    loadbalance
    log
    errors
    cache
}

.:53 {
    forward . 180.76.76.76 114.114.114.114
    reload
    log
    errors
    cache
}
```

*准备 docker-compose.yml 文件*

```yml
version: '3'

services:
  coredns:
    image: coredns/coredns
    network_mode: host
    volumes:
      - ./Corefile:/etc/Corefile:ro
    command:
      - -conf
      - /etc/Corefile
```

*启动 coredns 容器*

```bash
docker-cmopose up -d
```

## 测试

向 `etcd` 中添加 `example.net` 域名的解析记录

```bash
etcdctl put /skydns/net/example/ '{"host":"1.1.1.1","ttl":60}'
etcdctl put /skydns/net/example/www/ '{"host":"1.1.1.1","ttl":60}'
etcdctl put /skydns/net/example/test/ '{"host":"125.45.48.82","ttl":60}'
```

使用 `nslookup` 或 `dig` 命令测试

```bash
# 配置 dns 服务器
echo 'nameserver 127.0.0.1' > /etc/resolv.conf

# nslookup 命令解析测试
nslookup example.net
nslookup www.example.net
nslookup test.example.net

# dig 命令解析测试
dig example.net
dig www.example.net
dig test.example.net
```

> 参考地址: https://coredns.io/plugins/etcd/
