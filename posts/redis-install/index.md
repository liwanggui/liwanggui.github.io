# Redis 的简单安装与使用


## 使用场景介绍

Memcached：多核的缓存服务，更加适合于多用户并发访问次数较少的应用场景

Redis：单核的缓存服务，单节点情况下，更加适合于少量用户，多次访问的应用场景。 redis 一般是单机多实例架构，配合 redis 集群出现。

## 安装 Reis

### 源码编译安装 Redis

**redis 3.x**

```bash
cd /usr/local/src
wget http://download.redis.io/releases/redis-3.2.12.tar.gz
tar xzf redis-3.2.12.tar.gz
yum -y install gcc automake autoconf libtool make
cd /usr/local/src/redis-3.2.12
make
make install
```

**redis 6.x** 

```bash
wget https://download.redis.io/releases/redis-6.2.5.tar.gz
tar xzf redis-6.2.5.tar.gz
cd redis-6.2.5

# 编译 redis 所需依赖, 不编译时可能会无法编译下去
cd deps
make hdr_histogram  hiredis  jemalloc  linenoise  lua

# 编译 redis
cd ..
make
make install
```

### 安装 Redis 服务

使用源码包中的 `install_server.sh` 脚本工具，安装 `redis` 服务

```bash
[root@10-7-171-239 redis-3.2.12]# cd utils
[root@10-7-171-239 utils]# bash install_server.sh
Welcome to the redis service installer
This script will help you easily set up a running redis server

Please select the redis port for this instance: [6379]
Selecting default: 6379
Please select the redis config file name [/etc/redis/6379.conf]
Selected default - /etc/redis/6379.conf
Please select the redis log file name [/var/log/redis_6379.log]
Selected default - /var/log/redis_6379.log
Please select the data directory for this instance [/var/lib/redis/6379]
Selected default - /var/lib/redis/6379
Please select the redis executable path [/usr/local/bin/redis-server]
Selected config:
Port           : 6379
Config file    : /etc/redis/6379.conf
Log file       : /var/log/redis_6379.log
Data dir       : /var/lib/redis/6379
Executable     : /usr/local/bin/redis-server
Cli Executable : /usr/local/bin/redis-cli
Is this ok? Then press ENTER to go on or Ctrl-C to abort.
Copied /tmp/6379.conf => /etc/init.d/redis_6379
Installing service...
Successfully added to chkconfig!
Successfully added to runlevels 345!
Starting Redis server...
Installation successful!
```

## 配置 Redis

### 连接测试 Redis

redis 默认配置文件中监听的地址和端口是 `127.0.0.1:6379`，无密码验证(`requirepass`) 可以直接使用 `redis-cli` 命令连接

```bash
[root@localhost ~]# /etc/init.d/redis_6379 status
Redis is running (1446)
[root@localhost ~]# redis-cli
127.0.0.1:6379> ping
PONG
```

> 输入 ping 指令，redis 回复 PONG w代表连接成功，可以正常与 redis-server 通信

### 配置 redis 

配置文件基础项说明

```bash
$ egrep -v '^#|^$' /etc/redis/6379.conf

# 绑定的 ip 地址， 只绑定 127.0.0.1 地址是无法对外提供服务的
# 生产环境中建议配置此项
bind 127.0.0.1 10.7.171.239

# 是否启用保护模式
# 在未指定绑定地址，未向客户端请求认证密码。 在此模式下，仅从环回接口接受连接。 
# 如果要从外部计算机连接到 Redis 可以使用以下方法
# 1. 关闭保护模式, 通过在线修改 (CONFIG SET protected-mode no) 或者 修改配置文件
# 2. 启动服务时加入 '--protected-mode no' 参数
# 3. 配置 bind 地址或身份验证密码
# 注意：您只需要执行上述操作之一，服务器就可以开始接受来自外部的连接。
protected-mode yes

# 连接时验证的密码
requirepass S4Ea0lFLwJjehB91

# 服务监听端口
port 6379
# 是否后台运行
daemonize yes
# pidfile 存放路径
pidfile /var/run/redis_6379.pid
# 日志 存放路径
logfile /var/log/redis_6379.log
# 日志级别
loglevel notice

## RDB 持久化配置 ##
# RDB 持久化数据文件, 存储在 dir 选项配置的目录下
dbfilename dump.rdb
# 数据持久化存储路径
dir /var/lib/redis/6379
# 900 秒内如果累积 1 个变更就持久化一次
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes

# 最大使用内存大小
maxmemory 512m

slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100

## AOF 持久化配置，如果用于缓存用途可以不开启 ##
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
```

### 在线查看和修改 redis 配置 

#### 在线查看配置项

```bash
# 查看所有配置项
127.0.0.1:6379> config get *
  1) "dbfilename"
  2) "dump.rdb"
  3) "requirepass"
  4) "123"
  5) "masterauth"
  6) ""
  7) "unixsocket"
  8) ""
  9) "logfile"
....
# 查看验证密码
127.0.0.1:6379> config get maxmemory
1) "maxmemory"
2) "0"
# 模糊查看配置项
127.0.0.1:6379> config get maxm*
1) "maxmemory"
2) "128000000"
3) "maxmemory-samples"
4) "5"
5) "maxmemory-policy"
6) "noeviction"
```

#### 在线调整配置项

```bash
# 配置最大使用内存量
127.0.0.1:6379> config set maxmemory 128m
OK
# 配置连接验证密码
127.0.0.1:6379> config set requirepass 123
OK
# 连接验证
127.0.0.1:6379> auth 123
OK
# 查看配置
127.0.0.1:6379> config get maxmemory
1) "maxmemory"
2) "128000000"
127.0.0.1:6379> config get requirepass
1) "requirepass"
2) "123"
# 将修改的配置修改写入配置文件中
127.0.0.1:6379> config rewrite
OK
```
