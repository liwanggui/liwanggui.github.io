# Redis Sentinel 高可用


## Redis Replication

### Replication 原理

1. 副本库通过 `slaveof 127.0.0.1 6380` 命令, 连接主库, 并发送 SYNC 给主库 
2. 主库收到 SYNC, 会立即触发 BGSAVE, 后台保存 RDB, 发送给副本库
3. 副本库接收后会应用 RDB 快照
4. 主库会陆续将中间产生的新的操作,保存并发送给副本库
5. 到此,我们主复制集就正常工作了
6. 再此以后, 主库只要发生新的操作, 都会以命令传播的形式自动发送给副本库.
7. 所有复制相关信息, 从 info 信息中都可以查到. 即使重启任何节点, 他的主从关系依然都在.
8. 如果发生主从关系断开时,从库数据没有任何损坏, 在下次重连之后, 从库发送 PSYNC 给主库
9. 主库只会将从库缺失部分的数据同步给从库应用, 达到快速恢复主从的目的

> 使用 `slaveof no one` 解除主从关系

### 准备多实例 Redis 服务

实验采用单机多实例的方式进行，创建三个实例。端口 `6380-6382`, 可以使用 redis 源码包中的脚本（`install_server.sh`）创建

```bash
[root@localhost utils]# bash install_server.sh
Welcome to the redis service installer
This script will help you easily set up a running redis server

Please select the redis port for this instance: [6379] 6380
Please select the redis config file name [/data/redis/etc/6380.conf]
Selected default - /data/redis/etc/6380.conf
Please select the redis log file name [/data/redis/log/redis_6380.log]
Selected default - /data/redis/log/redis_6380.log
Please select the data directory for this instance [/data/redis/6380]
Selected default - /data/redis/6380
Please select the redis executable path [/usr/local/bin/redis-server]
Selected config:
Port           : 6380
Config file    : /data/redis/etc/6380.conf
Log file       : /data/redis/log/redis_6380.log
Data dir       : /data/redis/6380
Executable     : /usr/local/bin/redis-server
Cli Executable : /usr/local/bin/redis-cli
Is this ok? Then press ENTER to go on or Ctrl-C to abort.
Copied /tmp/6380.conf => /etc/init.d/redis_6380
Installing service...
Successfully added to chkconfig!
Successfully added to runlevels 345!
Starting Redis server...
Installation successful!
[root@localhost utils]# bash install_server.sh
Welcome to the redis service installer
This script will help you easily set up a running redis server

Please select the redis port for this instance: [6379] 6381
Please select the redis config file name [/data/redis/etc/6381.conf]
Selected default - /data/redis/etc/6381.conf
Please select the redis log file name [/data/redis/log/redis_6381.log]
Selected default - /data/redis/log/redis_6381.log
Please select the data directory for this instance [/data/redis/6381]
Selected default - /data/redis/6381
Please select the redis executable path [/usr/local/bin/redis-server]
Selected config:
Port           : 6381
Config file    : /data/redis/etc/6381.conf
Log file       : /data/redis/log/redis_6381.log
Data dir       : /data/redis/6381
Executable     : /usr/local/bin/redis-server
Cli Executable : /usr/local/bin/redis-cli
Is this ok? Then press ENTER to go on or Ctrl-C to abort.
Copied /tmp/6381.conf => /etc/init.d/redis_6381
Installing service...
Successfully added to chkconfig!
Successfully added to runlevels 345!
Starting Redis server...
Installation successful!
[root@localhost utils]# bash install_server.sh
Welcome to the redis service installer
This script will help you easily set up a running redis server

Please select the redis port for this instance: [6379] 6382
Please select the redis config file name [/data/redis/etc/6382.conf]
Selected default - /data/redis/etc/6382.conf
Please select the redis log file name [/data/redis/log/redis_6382.log]
Selected default - /data/redis/log/redis_6382.log
Please select the data directory for this instance [/data/redis/6382]
Selected default - /data/redis/6382
Please select the redis executable path [/usr/local/bin/redis-server]
Selected config:
Port           : 6382
Config file    : /data/redis/etc/6382.conf
Log file       : /data/redis/log/redis_6382.log
Data dir       : /data/redis/6382
Executable     : /usr/local/bin/redis-server
Cli Executable : /usr/local/bin/redis-cli
Is this ok? Then press ENTER to go on or Ctrl-C to abort.
Copied /tmp/6382.conf => /etc/init.d/redis_6382
Installing service...
Successfully added to chkconfig!
Successfully added to runlevels 345!
Starting Redis server...
Installation successful!
```

> 本例为了使用自定义的目录存放 redis 数据及配置文件对 install_server.sh 脚本中的路径做了修改

### Replication 配置

`6380` 为主库，`6381-6382` 为从库，配置如下:

*主库配置*

```bash
[root@localhost log]# redis-cli -p 6380
127.0.0.1:6381> config set requirepass 123
OK
127.0.0.1:6381> auth 123
OK
127.0.0.1:6381> config set masterauth 123
OK
127.0.0.1:6381> CONFIG REWRITE
```

*从库配置*

```bash
[root@localhost log]# redis-cli -p 6381
127.0.0.1:6381> config set requirepass 123
OK
127.0.0.1:6381> auth 123
OK
127.0.0.1:6381> config set masterauth 123
OK
127.0.0.1:6381> CONFIG REWRITE
OK
127.0.0.1:6381> slaveof 127.0.0.1 6380
OK

[root@localhost log]# redis-cli -p 6382
127.0.0.1:6381> config set requirepass 123
OK
127.0.0.1:6381> auth 123
OK
127.0.0.1:6381> config set masterauth 123
OK
127.0.0.1:6381> CONFIG REWRITE
OK
127.0.0.1:6381> slaveof 127.0.0.1 6380
OK
```

> 如果想解除主从关系可以使用 `slaveof no one` 指令

### 检查 Replication 状态

```bash
[root@localhost etc]# redis-cli -p 6380 -a 123 info replication
# Replication
role:master
connected_slaves:2
slave0:ip=127.0.0.1,port=6381,state=online,offset=3442,lag=1
slave1:ip=127.0.0.1,port=6382,state=online,offset=3442,lag=1
master_repl_offset:3575
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:2
repl_backlog_histlen:3574
[root@localhost etc]# redis-cli -p 6381 -a 123 info replication
# Replication
role:slave
master_host:127.0.0.1
master_port:6380
master_link_status:up
master_last_io_seconds_ago:0
master_sync_in_progress:0
slave_repl_offset:6291
slave_priority:100
slave_read_only:1
connected_slaves:0
master_repl_offset:0
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
```

> 可以在主库写入数据然后到从库读取测试同步

## Redis Sentinel 高可用

由于 redis replication 默认状态下如果主库宕机，是不会自动切换主从身份的，需要手动干预，这是生产环境下不允许的。为了解决此问题 redis 引入哨兵模式。

redis sentinel 有以下作用：

1. 监控节点
2. 自动选主，切换主从身份
3. 从库自动指向新的主库
4. 对应用透明
5. 自动处理故障节点

### 配置 sentinel

*准备 sentinel 配置文件*

源码包中有示例配置文件可用，直接复制修改即可

```bash
mkdir /data/sentinel
cat > /data/sentinel/26379.conf <<EOF
protected-mode no
daemonize yes
logfile "/data/sentinel/26379.log"
port 26379
dir "/tmp"
sentinel myid 994ea01af0f13692c13eeda116a0668084bb5e68

# mymaster 是一个自定义名称，客户端通过 sentinel 连接 redis 时需要使用
# 127.0.0.1 6380  是主节点的 ip 和 端口号
# 1 是 sentinel failover 投票数，默认为 sentinel 节点数/2 + 1, 1个节点时为1
# 为了能正常投票得出结果 sentinel 节点数得为奇数个
sentinel monitor mymaster 127.0.0.1 6380 1
sentinel down-after-milliseconds mymaster 5000
sentinel auth-pass mymaster 123
sentinel config-epoch mymaster 3
sentinel leader-epoch mymaster 3
sentinel known-slave mymaster 127.0.0.1 6382
sentinel known-slave mymaster 127.0.0.1 6381
sentinel current-epoch 3
EOF
```

*启动 sentinel 服务*

```bash
/usr/local/bin/redis-sentinel /data/sentinel/26379.conf
```

> `redis-sentinel` 是 `redis-server` 的软链接

### 连接测试 sentinel 

#### sentinel 命令

sentinel 支持的合法命令如下：

- `PING` sentinel 回复 PONG.
- `SENTINEL masters` 显示被监控的所有master以及它们的状态.
- `SENTINEL master` <master name> 显示指定master的信息和状态；
- `SENTINEL slaves <master name>` 显示指定master的所有slave以及它们的状态；
- `SENTINEL get-master-addr-by-name <master name>` 返回指定master的ip和端口，如果正在进行failover或者failover已经完成，将会显示被提升为master的slave的ip和端口。
- `SENTINEL reset <pattern>` 重置名字匹配该正则表达式的所有的master的状态信息，清楚其之前的状态信息，以及slaves信息。
- `SENTINEL failover <master name>` 强制sentinel执行failover，并且不需要得到其他sentinel的同意。但是failover后会将最新的配置发送给其他sentinel。

#### 动态修改 Sentinel 配置

从 `redis2.8.4` 开始，sentinel 提供了一组 API 用来添加，删除，修改 master 的配置。

> 需要注意的是，如果你通过 API 修改了一个 sentinel 的配置， sentinel 不会把修改的配置告诉其他 sentinel 。你需要自己手动地对多个 sentinel 发送修改配置的命令。

以下是一些修改 sentinel 配置的命令：

- `SENTINEL MONITOR <name> <ip> <port> <quorum>` 这个命令告诉 sentinel 去监听一个新的 master
- `SENTINEL REMOVE <name>` 命令sentinel放弃对某个master的监听
- `SENTINEL SET <name> <option> <value>` 这个命令很像Redis的CONFIG SET命令，用来改变指定master的配置。支持多个 <option><value>。例如以下实例：
- `SENTINEL SET objects-cache-master down-after-milliseconds 1000`

只要是配置文件中存在的配置项，都可以用 `SENTINEL SET` 命令来设置。这个还可以用来设置 master 的属性，比如说 quorum(票数)，而不需要先删除 master，再重新添加 master。例如：

```
SENTINEL SET objects-cache-master quorum 5
```

#### 测试主从切换

*模拟故障停止主库*

```bash
[root@localhost etc]# redis-cli -p 6380 -a 123 shutdown
```

*查看 sentinel 日志*

```
3963:X 28 Mar 15:31:13.864 # +sdown master mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:13.864 # +odown master mymaster 127.0.0.1 6380 #quorum 1/1
3963:X 28 Mar 15:31:13.864 # +new-epoch 6
3963:X 28 Mar 15:31:13.864 # +try-failover master mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:13.864 # +vote-for-leader 994ea01af0f13692c13eeda116a0668084bb5e68 6
3963:X 28 Mar 15:31:13.864 # +elected-leader master mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:13.864 # +failover-state-select-slave master mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:13.948 # +selected-slave slave 127.0.0.1:6382 127.0.0.1 6382 @ mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:13.948 * +failover-state-send-slaveof-noone slave 127.0.0.1:6382 127.0.0.1 6382 @ mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:14.007 * +failover-state-wait-promotion slave 127.0.0.1:6382 127.0.0.1 6382 @ mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:14.943 # +promoted-slave slave 127.0.0.1:6382 127.0.0.1 6382 @ mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:14.943 # +failover-state-reconf-slaves master mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:15.004 * +slave-reconf-sent slave 127.0.0.1:6381 127.0.0.1 6381 @ mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:15.994 * +slave-reconf-inprog slave 127.0.0.1:6381 127.0.0.1 6381 @ mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:15.994 * +slave-reconf-done slave 127.0.0.1:6381 127.0.0.1 6381 @ mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:16.055 # +failover-end master mymaster 127.0.0.1 6380
3963:X 28 Mar 15:31:16.055 # +switch-master mymaster 127.0.0.1 6380 127.0.0.1 6382
3963:X 28 Mar 15:31:16.055 * +slave slave 127.0.0.1:6381 127.0.0.1 6381 @ mymaster 127.0.0.1 6382
3963:X 28 Mar 15:31:16.055 * +slave slave 127.0.0.1:6380 127.0.0.1 6380 @ mymaster 127.0.0.1 6382
3963:X 28 Mar 15:31:21.064 # +sdown slave 127.0.0.1:6380 127.0.0.1 6380 @ mymaster 127.0.0.1 6382
```

> 可以看到 sentinel 检测到主库服务停止，将 6382 选为主库，进行了切换操作， 6381 也自动与 6382 建立主从关系

*6380 修复好后，重新启动服务 sentinel 会自动检测到并 6380 加入主从环境中*

```bash
[root@localhost etc]# /etc/init.d/redis_6380 start
Starting Redis server...
```

此时可以从 sentinel 日志中看到以下信息

```
3963:X 28 Mar 15:35:05.234 # -sdown slave 127.0.0.1:6380 127.0.0.1 6380 @ mymaster 127.0.0.1 6382
3963:X 28 Mar 15:35:15.229 * +convert-to-slave slave 127.0.0.1:6380 127.0.0.1 6380 @ mymaster 127.0.0.1 6382
```

*sentinel 会自动在 6380 实例的配置文件最后一行加入一行配置*

```bash
[root@localhost etc]# tail -n 3 6380.conf
requirepass "123"
masterauth "123"
slaveof 127.0.0.1 6382
```

#### 配置多节点 sentinel 

此时 redis 的高可用解决了，但 sentinel 只有一个节点存在单点故障，为了解决这个问题，可以通过部署多个 sentinel 节点解决。
配置多个 sentinel 节点时需要注意节点数据及配置文件中的 `sentinel monitor mymaster 127.0.0.1 6380 1` 配置项的最后一个值的配置。


#### 客户端连接 redis

以 python 客户端为例说明, 参考文档: [https://pypi.org/project/redis/](https://pypi.org/project/redis/)

*安装 redis 库*

```bash
pip install redis
```

*连接至单实例 reids*

```python
>>> import redis
>>> r = redis.Redis(host='localhost', port=6379, db=0)
>>> r.set('foo', 'bar')
True
>>> r.get('foo')
b'bar'
```

*Sentinel 模式*

```python
>>> from redis.sentinel import Sentinel
>>> sentinel = Sentinel([('localhost', 26379)], socket_timeout=0.1)
>>> sentinel.discover_master('mymaster')
('127.0.0.1', 6379)
>>> sentinel.discover_slaves('mymaster')
[('127.0.0.1', 6380)]

>>> master = sentinel.master_for('mymaster', socket_timeout=0.1, password='123')
>>> slave = sentinel.slave_for('mymaster', socket_timeout=0.1, password='123')
>>> master.set('foo', 'bar')
>>> slave.get('foo')
b'bar'
```
