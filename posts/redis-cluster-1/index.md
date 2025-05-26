# Redis 4.x 分片集群部署


## 简单介绍

**高可用**

在搭建集群时，会为每一个分片的主节点，对应一个从节点，实现 slaveof 的功能，同时当主节点 down，实现类似于 sentinel 的自动 failover 的功能。

1. redis会有多组分片构成（3组）
2. redis cluster 使用固定个数的slot存储数据（一共16384slot）
3. 每组分片分得1/3 slot个数（0-5500  5501-11000  11001-16383）
4. 基于CRC16(key) % 16384 ====》值 （槽位号）。

**高性能**

1. 在多分片节点中，将 16384 个槽位，均匀分布到多个分片节点中
2. 存数据时，将 key 做 crc16(key), 然后和 16384 进行取模，得出槽位值（0-16383之间）
3. 根据计算得出的槽位值，找到相对应的分片节点的主节点，存储到相应槽位上
4. 如果客户端当时连接的节点不是将来要存储的分片节点，分片集群会将客户端连接切换至真正存储节点进行数据存储

## 部署分片集群

Redis 集群至少需要三个主节点，一个主节点最少一个从节点，一共需要准备六个节点

### 编译安装

```bash
wget http://download.redis.io/releases/redis-4.0.11.tar.gz
tar xzf redis-4.0.11.tar.gz
cd redis-4.0.11
make 
make install
```

> 提示: make 时如果提示错误，你可能需要到 deps 目录下的应用目录执行 make 

*使用 redis 提供的脚本配置服务, 进入 utils 目录，执行 `bash install_server.sh` 命令，按提示进行操作*

```bash
# bash install_server.sh
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
```

重要执行上面的命令，配置6个redis 实例，实例信息如下

- 127.0.0.1:6379 
- 127.0.0.1:7379 
- 127.0.0.1:8379 
- 127.0.0.1:6380 
- 127.0.0.1:7380 
- 127.0.0.1:8380

### 配置集群

修改 redis 实例配置文件，添加以下配置项 (注意区分不同的实例配置项 `cluster-config-file`)

```bash
appendonly yes
cluster-enabled yes
cluster-config-file nodes-6379.conf
cluster-node-timeout 15000
```

修改完成后，重启所有 redis 服务

```bash
cd /etc/init.d/
ls redis_* | while read f; do ./$f restart; sleep 0.5; done
```

这里我们使用 `redis` 源码包中的 `redis-trib.rb` 脚本进行分片集群配置

由于系统默认的 ruby 版本过低，我们先安装高版本的 ruby 

```bash
wget https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.3.tar.gz
tar xzf ruby-2.7.3.tar.gz
cd ruby-2.7.3
./configure --prefix=/usr/local/ruby
make
make install

# 加入环境变量
echo 'export PATH=/usr/local/ruby/bin:$PATH' > /etc/profile.d/ruby.sh
source /etc/profile

# 修改国内源
gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/

# 安装 redis 模块
gem install redis
```

**开始创建 redis 分片集群**

进行入 redis 源码包的中 `src` 目录中，执行 `./redis-trib.rb create --replicas 1  127.0.0.1:6379 127.0.0.1:7379 127.0.0.1:8379 127.0.0.1:6380 127.0.0.1:7380 127.0.0.1:8380`

```bash
# ./redis-trib.rb create --replicas 1  127.0.0.1:6379 127.0.0.1:7379 127.0.0.1:8379 \
127.0.0.1:6380 127.0.0.1:7380 127.0.0.1:8380
>>> Creating cluster
>>> Performing hash slots allocation on 6 nodes...
Using 3 masters:
127.0.0.1:6379
127.0.0.1:7379
127.0.0.1:8379
Adding replica 127.0.0.1:7380 to 127.0.0.1:6379
Adding replica 127.0.0.1:8380 to 127.0.0.1:7379
Adding replica 127.0.0.1:6380 to 127.0.0.1:8379
>>> Trying to optimize slaves allocation for anti-affinity
[WARNING] Some slaves are in the same host as their master
M: 7dcdc92a442ff4f8e972d5cf90cfc981371d2f69 127.0.0.1:6379
   slots:0-5460 (5461 slots) master
M: 1c3116e5046325324085a43ebdf0496aa4ad42e2 127.0.0.1:7379
   slots:5461-10922 (5462 slots) master
M: 551738168e78c691169141fc6666ad83fffcd5cb 127.0.0.1:8379
   slots:10923-16383 (5461 slots) master
S: 686fc42d830ce4a8bbda355e0091f4b8f2b7b4a4 127.0.0.1:6380
   replicates 551738168e78c691169141fc6666ad83fffcd5cb
S: eb2858ad9d61ba694f80a55e7ab141521e9cd253 127.0.0.1:7380
   replicates 7dcdc92a442ff4f8e972d5cf90cfc981371d2f69
S: 758a588d3b8f8350797b107a5bad5e9052bdf97f 127.0.0.1:8380
   replicates 1c3116e5046325324085a43ebdf0496aa4ad42e2
Can I set the above configuration? (type 'yes' to accept): yes # 确认没有问题，输入 yes 继续
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join.....
>>> Performing Cluster Check (using node 127.0.0.1:6379)
M: 7dcdc92a442ff4f8e972d5cf90cfc981371d2f69 127.0.0.1:6379
   slots:0-5460 (5461 slots) master
   1 additional replica(s)
S: 758a588d3b8f8350797b107a5bad5e9052bdf97f 127.0.0.1:8380
   slots: (0 slots) slave
   replicates 1c3116e5046325324085a43ebdf0496aa4ad42e2
M: 551738168e78c691169141fc6666ad83fffcd5cb 127.0.0.1:8379
   slots:10923-16383 (5461 slots) master
   1 additional replica(s)
S: 686fc42d830ce4a8bbda355e0091f4b8f2b7b4a4 127.0.0.1:6380
   slots: (0 slots) slave
   replicates 551738168e78c691169141fc6666ad83fffcd5cb
M: 1c3116e5046325324085a43ebdf0496aa4ad42e2 127.0.0.1:7379
   slots:5461-10922 (5462 slots) master
   1 additional replica(s)
S: eb2858ad9d61ba694f80a55e7ab141521e9cd253 127.0.0.1:7380
   slots: (0 slots) slave
   replicates 7dcdc92a442ff4f8e972d5cf90cfc981371d2f69
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

*命令说明*

- --replicas: 表示主节点下有几个从节点

*如何指定实例为主节点？*

只需要将主节点实例写在从节点前面

**检查集群状态**

```bash
./redis-trib.rb check 127.0.0.1:6379
```

**通过 redis-cli 查询集群信息**

```bash
# redis-cli -p 6379
127.0.0.1:6379> cluster info
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:6
cluster_my_epoch:1
cluster_stats_messages_ping_sent:828
cluster_stats_messages_pong_sent:850
cluster_stats_messages_sent:1678
cluster_stats_messages_ping_received:845
cluster_stats_messages_pong_received:828
cluster_stats_messages_meet_received:5
cluster_stats_messages_received:1678
127.0.0.1:6379> cluster nodes
758a588d3b8f8350797b107a5bad5e9052bdf97f 127.0.0.1:8380@18380 slave 1c3116e5046325324085a43ebdf0496aa4ad42e2 0 1648110968000 6 connected
551738168e78c691169141fc6666ad83fffcd5cb 127.0.0.1:8379@18379 master - 0 1648110967481 3 connected 10923-16383
7dcdc92a442ff4f8e972d5cf90cfc981371d2f69 127.0.0.1:6379@16379 myself,master - 0 1648110967000 1 connected 0-5460
686fc42d830ce4a8bbda355e0091f4b8f2b7b4a4 127.0.0.1:6380@16380 slave 551738168e78c691169141fc6666ad83fffcd5cb 0 1648110968000 4 connected
1c3116e5046325324085a43ebdf0496aa4ad42e2 127.0.0.1:7379@17379 master - 0 1648110968496 2 connected 5461-10922
eb2858ad9d61ba694f80a55e7ab141521e9cd253 127.0.0.1:7380@17380 slave 7dcdc92a442ff4f8e972d5cf90cfc981371d2f69 0 1648110969507 5 connected
```

### 增加新节点

新创建两个 redis 实例 7000/7001, 并启用集群配置，参考上面的集群配置部分

*加入新节点 (主节点)*

- 127.0.0.1:7000 要加入集群的节点
- 127.0.0.1:6379 集群中已存在的节点

```bash
./redis-trib.rb add-node 127.0.0.1:7000 127.0.0.1:6379
```

*加入从节点*

--master-id 指定为 127.0.0.1:7000 的 ID

```bash
./redis-trib.rb add-node --slave --master-id 4cd0398657f6b401169939edfb3ec985092b676a 127.0.0.1:7001 127.0.0.1:6379
```

> 提示: 命令详细参数说明，可以执行 `./redis-trib.rb` 查看

*为新加入的节点分配哈希槽*

```bash
# ./redis-trib.rb reshard 127.0.0.1:6379
>>> Performing Cluster Check (using node 127.0.0.1:6379)
M: 7dcdc92a442ff4f8e972d5cf90cfc981371d2f69 127.0.0.1:6379
   slots:0-5460 (5461 slots) master
   1 additional replica(s)
S: 758a588d3b8f8350797b107a5bad5e9052bdf97f 127.0.0.1:8380
   slots: (0 slots) slave
   replicates 1c3116e5046325324085a43ebdf0496aa4ad42e2
M: 551738168e78c691169141fc6666ad83fffcd5cb 127.0.0.1:8379
   slots:10923-16383 (5461 slots) master
   1 additional replica(s)
S: 686fc42d830ce4a8bbda355e0091f4b8f2b7b4a4 127.0.0.1:6380
   slots: (0 slots) slave
   replicates 551738168e78c691169141fc6666ad83fffcd5cb
S: adb61c6d04f283077383e2dd6ed1323f6fcd2863 127.0.0.1:7001
   slots: (0 slots) slave
   replicates 4cd0398657f6b401169939edfb3ec985092b676a
M: 4cd0398657f6b401169939edfb3ec985092b676a 127.0.0.1:7000
   slots: (0 slots) master
   0 additional replica(s)
M: 1c3116e5046325324085a43ebdf0496aa4ad42e2 127.0.0.1:7379
   slots:5461-10922 (5462 slots) master
   1 additional replica(s)
S: eb2858ad9d61ba694f80a55e7ab141521e9cd253 127.0.0.1:7380
   slots: (0 slots) slave
   replicates 7dcdc92a442ff4f8e972d5cf90cfc981371d2f69
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
How many slots do you want to move (from 1 to 16384)? 4096 
What is the receiving node ID? 4cd0398657f6b401169939edfb3ec985092b676a  # 这里是填接收哈希槽主节点ID，也是就是 7000 的 ID
Please enter all the source node IDs.
  Type 'all' to use all the nodes as source nodes for the hash slots.
  Type 'done' once you entered all the source nodes IDs.
Source node #1: all  # 这里输入 all
......
    Moving slot 1362 from 1c3116e5046325324085a43ebdf0496aa4ad42e2
    Moving slot 1363 from 1c3116e5046325324085a43ebdf0496aa4ad42e2
    Moving slot 1364 from 1c3116e5046325324085a43ebdf0496aa4ad42e2
Do you want to proceed with the proposed reshard plan (yes/no)? yes # 输入 yes 开始执行
```

一共存在四个主节点，为了平均分配我们需要给 7000 分配 16384 除以 4 等于 4096 个节点，所以我们输入 4096

> Redis 集群节点的删除也可以使用 `redis-trib.rb` 轻松完成
