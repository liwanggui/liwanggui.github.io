# 部署 CoreDNS 为内部 DNS 服务器


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

## 测试 CoreDNS

向 `etcd` 中添加 `example.net` 域名的解析记录

*添加 example.net 多条 A 记录*

```bash
etcdctl put /skydns/net/example/x1 '{"host":"1.1.1.1","ttl":60}'
etcdctl put /skydns/net/example/x2 '{"host":"1.1.1.1","ttl":60}'
```

> 注意: `x1` 和 `x2` 可自定义如 `a、b、c` 等，并且设置多个 `AAAA` 等方法类似

*添加 www.example.net 多条 A 记录*

```bash
etcdctl put /skydns/net/example/www/x1 '{"host":"2.1.1.1","ttl":60}'
etcdctl put /skydns/net/example/www/x2 '{"host":"2.1.1.2","ttl":60}'
```

*添加 test.example.net 多条 A 记录*

```bash
etcdctl put /skydns/net/example/test/x1 '{"host":"125.45.48.81","ttl":60}'
etcdctl put /skydns/net/example/test/x2 '{"host":"125.45.48.82","ttl":60}'
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


## 添加解析记录注意点

**先上示例** 为 `example.net` 、`www.example.net` 、`test.example.net` 添加 A 记录

```bash
etcdctl put /skydns/net/example/ '{"host":"1.1.1.1","ttl":60}'
etcdctl put /skydns/net/example/www/ '{"host":"1.1.1.2","ttl":60}'
etcdctl put /skydns/net/example/test/ '{"host":"1.1.1.3","ttl":60}'
```

**解析测试**

```bash
# nslookup example.net
Server:         127.0.0.1
Address:        127.0.0.1#53

Name:   example.net
Address: 1.1.1.1
Name:   example.net
Address: 1.1.1.2
Name:   example.net
Address: 1.1.1.3

# nslookup www.example.net
Server:         127.0.0.1
Address:        127.0.0.1#53

Name:   www.example.net
Address: 1.1.1.2

# nslookup test.example.net
Server:         127.0.0.1
Address:        127.0.0.1#53

Name:   test.example.net
Address: 1.1.1.3
```

可以看到解析 `example.net` 域名时返回的解析记录有三条记录, 记录的值刚好是 `www` 和 `test` 的值，
再看单独解析 `www` 和 `test` 时，解析结果返回只有一条。

这时候需要思考为什么产生这个结果？？

参考 `coredns` 多解析记录的添加方式，就会明白了。

解析 `example.net` 域名时会返 `/skydns/net/example/` 和 `/skydns/net/example/*/` 下所有的值

是不是和添加多解析记录一样，只是添加多解析记录示例使用的字符是 `x1, x2` ， 但不要忘记了这个字符是可以自定义的，
正是因为如此 `coredns` 才会将 `www` 和 `test` 的值一并取出
为了避免这个问题，添加解析记录时需采用添加多记录的方式添加。

