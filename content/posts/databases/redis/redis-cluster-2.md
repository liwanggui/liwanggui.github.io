---
title: "Redis 5.x 分片集群部署"
date: 2022-03-25T16:56:26+08:00
draft: false
categories: 
- redis
tags:
- redis
---

Redis 5.x 及以上版本配置分片集群不需要在使用 `redis-trib.rb` 脚本，默认 `redis-cli` 已集成集群配置指令

```bash
[root@localhost ~]# redis-cli --cluster help
Cluster Manager Commands:
  create         host1:port1 ... hostN:portN
                 --cluster-replicas <arg>
  check          host:port
                 --cluster-search-multiple-owners
  info           host:port
  fix            host:port
                 --cluster-search-multiple-owners
  reshard        host:port
                 --cluster-from <arg>
                 --cluster-to <arg>
                 --cluster-slots <arg>
                 --cluster-yes
                 --cluster-timeout <arg>
                 --cluster-pipeline <arg>
                 --cluster-replace
  rebalance      host:port
                 --cluster-weight <node1=w1...nodeN=wN>
                 --cluster-use-empty-masters
                 --cluster-timeout <arg>
                 --cluster-simulate
                 --cluster-pipeline <arg>
                 --cluster-threshold <arg>
                 --cluster-replace
  add-node       new_host:new_port existing_host:existing_port
                 --cluster-slave
                 --cluster-master-id <arg>
  del-node       host:port node_id
  call           host:port command arg arg .. arg
  set-timeout    host:port milliseconds
  import         host:port
                 --cluster-from <arg>
                 --cluster-copy
                 --cluster-replace
  help

For check, fix, reshard, del-node, set-timeout you can specify the host and port of any working node in the cluster.
```

## 配置集群

*准备 6 个 redis 实例：*

- 127.0.0.1:6000
- 127.0.0.1:6001
- 127.0.0.1:7000
- 127.0.0.1:7001
- 127.0.0.1:8000
- 127.0.0.1:8001

*配置集群*

```bash
[root@localhost redis]# redis-cli --cluster create --cluster-replicas 1 127.0.0.1:6000 127.0.0.1:7000 127.0.0.1:8000 127.0.0.1:6001 127.0.0.1:7001 127.0.0.1:8001
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 127.0.0.1:7001 to 127.0.0.1:6000
Adding replica 127.0.0.1:8001 to 127.0.0.1:7000
Adding replica 127.0.0.1:6001 to 127.0.0.1:8000
>>> Trying to optimize slaves allocation for anti-affinity
[WARNING] Some slaves are in the same host as their master
M: c9f7d10dc6d4f471a9d5660b67c44699474bba9b 127.0.0.1:6000
   slots:[0-5460] (5461 slots) master
M: cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 127.0.0.1:7000
   slots:[5461-10922] (5462 slots) master
M: e64e780e3a83e871daca04ddf7d4489624d97054 127.0.0.1:8000
   slots:[10923-16383] (5461 slots) master
S: 08f1fa2ecd26f2916092695a3aa5bcb4185c1eee 127.0.0.1:6001
   replicates cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125
S: 2f90e0f293fcf95dada5ec3414d46f90411cd987 127.0.0.1:7001
   replicates e64e780e3a83e871daca04ddf7d4489624d97054
S: 2d555ec571b26fe24012f126b600b2d742233574 127.0.0.1:8001
   replicates c9f7d10dc6d4f471a9d5660b67c44699474bba9b
Can I set the above configuration? (type 'yes' to accept): yes # 输入 yes 后继续
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
..
>>> Performing Cluster Check (using node 127.0.0.1:6000)
M: c9f7d10dc6d4f471a9d5660b67c44699474bba9b 127.0.0.1:6000
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 2f90e0f293fcf95dada5ec3414d46f90411cd987 127.0.0.1:7001
   slots: (0 slots) slave
   replicates e64e780e3a83e871daca04ddf7d4489624d97054
S: 2d555ec571b26fe24012f126b600b2d742233574 127.0.0.1:8001
   slots: (0 slots) slave
   replicates c9f7d10dc6d4f471a9d5660b67c44699474bba9b
S: 08f1fa2ecd26f2916092695a3aa5bcb4185c1eee 127.0.0.1:6001
   slots: (0 slots) slave
   replicates cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125
M: e64e780e3a83e871daca04ddf7d4489624d97054 127.0.0.1:8000
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
M: cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 127.0.0.1:7000
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

> 提示: 使用方法和 `redis-trib.rb` 脚本类似

*检查集群状态*

```bash
[root@localhost redis]# redis-cli --cluster check  127.0.0.1:6000
127.0.0.1:6000 (c9f7d10d...) -> 0 keys | 5461 slots | 1 slaves.
127.0.0.1:8000 (e64e780e...) -> 0 keys | 5461 slots | 1 slaves.
127.0.0.1:7000 (cf12b1d7...) -> 0 keys | 5462 slots | 1 slaves.
[OK] 0 keys in 3 masters.
0.00 keys per slot on average.
>>> Performing Cluster Check (using node 127.0.0.1:6000)
M: c9f7d10dc6d4f471a9d5660b67c44699474bba9b 127.0.0.1:6000
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 2f90e0f293fcf95dada5ec3414d46f90411cd987 127.0.0.1:7001
   slots: (0 slots) slave
   replicates e64e780e3a83e871daca04ddf7d4489624d97054
S: 2d555ec571b26fe24012f126b600b2d742233574 127.0.0.1:8001
   slots: (0 slots) slave
   replicates c9f7d10dc6d4f471a9d5660b67c44699474bba9b
S: 08f1fa2ecd26f2916092695a3aa5bcb4185c1eee 127.0.0.1:6001
   slots: (0 slots) slave
   replicates cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125
M: e64e780e3a83e871daca04ddf7d4489624d97054 127.0.0.1:8000
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
M: cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 127.0.0.1:7000
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

*连接 redis 查看状态*

```bash
[root@localhost redis]# redis-cli -p 6000
127.0.0.1:6000> CLUSTER NODES
2f90e0f293fcf95dada5ec3414d46f90411cd987 127.0.0.1:7001@17001 slave e64e780e3a83e871daca04ddf7d4489624d97054 0 1648198606347 5 connected
2d555ec571b26fe24012f126b600b2d742233574 127.0.0.1:8001@18001 slave c9f7d10dc6d4f471a9d5660b67c44699474bba9b 0 1648198608000 6 connected
c9f7d10dc6d4f471a9d5660b67c44699474bba9b 127.0.0.1:6000@16000 myself,master - 0 1648198608000 1 connected 0-5460
08f1fa2ecd26f2916092695a3aa5bcb4185c1eee 127.0.0.1:6001@16001 slave cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 0 1648198609379 4 connected
e64e780e3a83e871daca04ddf7d4489624d97054 127.0.0.1:8000@18000 master - 0 1648198607364 3 connected 10923-16383
cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 127.0.0.1:7000@17000 master - 0 1648198608369 2 connected 5461-10922
127.0.0.1:6000> CLUSTER INFO
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:6
cluster_my_epoch:1
cluster_stats_messages_ping_sent:822
cluster_stats_messages_pong_sent:873
cluster_stats_messages_sent:1695
cluster_stats_messages_ping_received:868
cluster_stats_messages_pong_received:822
cluster_stats_messages_meet_received:5
cluster_stats_messages_received:1695
```

*测试集群数据的读写*

```bash
[root@localhost redis]# redis-cli -c -p 6000
127.0.0.1:6000> set hello world
OK
127.0.0.1:6000> set email test@adminc.om
-> Redirected to slot [10780] located at 127.0.0.1:7000
OK
127.0.0.1:7000> get hello
-> Redirected to slot [866] located at 127.0.0.1:6000
"world"
127.0.0.1:6000> get email
-> Redirected to slot [10780] located at 127.0.0.1:7000
"test@adminc.om"
```

> 提示: 使用 `redis-cli` 连接集群时加上 `-c` 参数，这样在操作时就会自动切换 `redis` 实例

## 增加节点

先创建两个 redis 实例

- 127.0.0.1:9000
- 127.0.0.1:9001

*将 `127.0.0.1:9000` 加入为主节点*

```bash
[root@localhost redis]# redis-cli --cluster add-node 127.0.0.1:9000 127.0.0.1:6000
>>> Adding node 127.0.0.1:9000 to cluster 127.0.0.1:6000
>>> Performing Cluster Check (using node 127.0.0.1:6000)
M: c9f7d10dc6d4f471a9d5660b67c44699474bba9b 127.0.0.1:6000
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 2f90e0f293fcf95dada5ec3414d46f90411cd987 127.0.0.1:7001
   slots: (0 slots) slave
   replicates e64e780e3a83e871daca04ddf7d4489624d97054
M: cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 127.0.0.1:7000
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
M: e64e780e3a83e871daca04ddf7d4489624d97054 127.0.0.1:8000
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: 08f1fa2ecd26f2916092695a3aa5bcb4185c1eee 127.0.0.1:6001
   slots: (0 slots) slave
   replicates cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125
S: 2d555ec571b26fe24012f126b600b2d742233574 127.0.0.1:8001
   slots: (0 slots) slave
   replicates c9f7d10dc6d4f471a9d5660b67c44699474bba9b
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
>>> Send CLUSTER MEET to node 127.0.0.1:9000 to make it join the cluster.
[OK] New node added correctly.
```

*检查集群状态*

可以看到 `127.0.0.1:9000` 为主节点，哈希槽数当前为 `0`

```bash
[root@localhost redis]# redis-cli --cluster check 127.0.0.1:6000
127.0.0.1:6000 (c9f7d10d...) -> 0 keys | 5461 slots | 1 slaves.
127.0.0.1:9000 (b0a13bf5...) -> 0 keys | 0 slots | 0 slaves.
127.0.0.1:7000 (cf12b1d7...) -> 0 keys | 5462 slots | 1 slaves.
127.0.0.1:8000 (e64e780e...) -> 0 keys | 5461 slots | 1 slaves.
[OK] 0 keys in 4 masters.
0.00 keys per slot on average.
>>> Performing Cluster Check (using node 127.0.0.1:6000)
M: c9f7d10dc6d4f471a9d5660b67c44699474bba9b 127.0.0.1:6000
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
M: b0a13bf57d4e514cffa305c44d41a5a92858eb9a 127.0.0.1:9000
   slots: (0 slots) master
S: 2f90e0f293fcf95dada5ec3414d46f90411cd987 127.0.0.1:7001
   slots: (0 slots) slave
   replicates e64e780e3a83e871daca04ddf7d4489624d97054
M: cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 127.0.0.1:7000
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
M: e64e780e3a83e871daca04ddf7d4489624d97054 127.0.0.1:8000
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: 08f1fa2ecd26f2916092695a3aa5bcb4185c1eee 127.0.0.1:6001
   slots: (0 slots) slave
   replicates cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125
S: 2d555ec571b26fe24012f126b600b2d742233574 127.0.0.1:8001
   slots: (0 slots) slave
   replicates c9f7d10dc6d4f471a9d5660b67c44699474bba9b
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

*为 `127.0.0.1:9000` 分配哈希槽*

```bash
[root@localhost redis]# redis-cli --cluster reshard 127.0.0.1:6000
>>> Performing Cluster Check (using node 127.0.0.1:6000)
M: c9f7d10dc6d4f471a9d5660b67c44699474bba9b 127.0.0.1:6000
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
M: b0a13bf57d4e514cffa305c44d41a5a92858eb9a 127.0.0.1:9000
   slots: (0 slots) master
S: 2f90e0f293fcf95dada5ec3414d46f90411cd987 127.0.0.1:7001
   slots: (0 slots) slave
   replicates e64e780e3a83e871daca04ddf7d4489624d97054
M: cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 127.0.0.1:7000
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
M: e64e780e3a83e871daca04ddf7d4489624d97054 127.0.0.1:8000
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: 08f1fa2ecd26f2916092695a3aa5bcb4185c1eee 127.0.0.1:6001
   slots: (0 slots) slave
   replicates cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125
S: 2d555ec571b26fe24012f126b600b2d742233574 127.0.0.1:8001
   slots: (0 slots) slave
   replicates c9f7d10dc6d4f471a9d5660b67c44699474bba9b
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
How many slots do you want to move (from 1 to 16384)? 4096
```

> 这里我们分配 4096 个哈希槽

```bash
What is the receiving node ID? b0a13bf57d4e514cffa305c44d41a5a92858eb9a
```
> 输入 `127.0.0.1:9000` 实例的 ID

```bash
What is the receiving node ID? b0a13bf57d4e514cffa305c44d41a5a92858eb9a
Please enter all the source node IDs.
  Type 'all' to use all the nodes as source nodes for the hash slots.
  Type 'done' once you entered all the source nodes IDs.
Source node #1: all
```

> 输入 all , 从所有实例中转移哈希槽至 `127.0.0.1:9000` 实例

```bash
    Moving slot 12284 from e64e780e3a83e871daca04ddf7d4489624d97054
    Moving slot 12285 from e64e780e3a83e871daca04ddf7d4489624d97054
    Moving slot 12286 from e64e780e3a83e871daca04ddf7d4489624d97054
    Moving slot 12287 from e64e780e3a83e871daca04ddf7d4489624d97054
Do you want to proceed with the proposed reshard plan (yes/no)? yes
```

> 输入 yes 开始配置

*完成后我们检查集群状态*

```bash
[root@localhost redis]# redis-cli --cluster check 127.0.0.1:6000
127.0.0.1:6000 (c9f7d10d...) -> 0 keys | 4096 slots | 1 slaves.
127.0.0.1:9000 (b0a13bf5...) -> 0 keys | 4096 slots | 0 slaves.
127.0.0.1:7000 (cf12b1d7...) -> 0 keys | 4096 slots | 1 slaves.
127.0.0.1:8000 (e64e780e...) -> 0 keys | 4096 slots | 1 slaves.
[OK] 0 keys in 4 masters.
0.00 keys per slot on average.
>>> Performing Cluster Check (using node 127.0.0.1:6000)
M: c9f7d10dc6d4f471a9d5660b67c44699474bba9b 127.0.0.1:6000
   slots:[1365-5460] (4096 slots) master
   1 additional replica(s)
M: b0a13bf57d4e514cffa305c44d41a5a92858eb9a 127.0.0.1:9000
   slots:[0-1364],[5461-6826],[10923-12287] (4096 slots) master
S: 2f90e0f293fcf95dada5ec3414d46f90411cd987 127.0.0.1:7001
   slots: (0 slots) slave
   replicates e64e780e3a83e871daca04ddf7d4489624d97054
M: cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 127.0.0.1:7000
   slots:[6827-10922] (4096 slots) master
   1 additional replica(s)
M: e64e780e3a83e871daca04ddf7d4489624d97054 127.0.0.1:8000
   slots:[12288-16383] (4096 slots) master
   1 additional replica(s)
S: 08f1fa2ecd26f2916092695a3aa5bcb4185c1eee 127.0.0.1:6001
   slots: (0 slots) slave
   replicates cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125
S: 2d555ec571b26fe24012f126b600b2d742233574 127.0.0.1:8001
   slots: (0 slots) slave
   replicates c9f7d10dc6d4f471a9d5660b67c44699474bba9b
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

> 可以看到哈希槽已经按我们的预期分配了

*为 `127.0.0.1:9000` 实例指定从节点*

```bash
[root@localhost redis]# redis-cli --cluster add-node --cluster-slave --cluster-master-id b0a13bf57d4e514cffa305c44d41a5a92858eb9a 127.0.0.1:9001 127.0.0.1:9000
>>> Adding node 127.0.0.1:9001 to cluster 127.0.0.1:9000
>>> Performing Cluster Check (using node 127.0.0.1:9000)
M: b0a13bf57d4e514cffa305c44d41a5a92858eb9a 127.0.0.1:9000
   slots:[0-1364],[5461-6826],[10923-12287] (4096 slots) master
M: e64e780e3a83e871daca04ddf7d4489624d97054 127.0.0.1:8000
   slots:[12288-16383] (4096 slots) master
   1 additional replica(s)
S: 2f90e0f293fcf95dada5ec3414d46f90411cd987 127.0.0.1:7001
   slots: (0 slots) slave
   replicates e64e780e3a83e871daca04ddf7d4489624d97054
M: c9f7d10dc6d4f471a9d5660b67c44699474bba9b 127.0.0.1:6000
   slots:[1365-5460] (4096 slots) master
   1 additional replica(s)
S: 2d555ec571b26fe24012f126b600b2d742233574 127.0.0.1:8001
   slots: (0 slots) slave
   replicates c9f7d10dc6d4f471a9d5660b67c44699474bba9b
S: 08f1fa2ecd26f2916092695a3aa5bcb4185c1eee 127.0.0.1:6001
   slots: (0 slots) slave
   replicates cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125
M: cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 127.0.0.1:7000
   slots:[6827-10922] (4096 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
>>> Send CLUSTER MEET to node 127.0.0.1:9001 to make it join the cluster.
Waiting for the cluster to join

>>> Configure node as replica of 127.0.0.1:9000.
[OK] New node added correctly.
```

*查看集群所有节点*

```bash
[root@localhost redis]# redis-cli -p 6000 cluster nodes
b0a13bf57d4e514cffa305c44d41a5a92858eb9a 127.0.0.1:9000@19000 master - 0 1648200334000 7 connected 0-1364 5461-6826 10923-12287
e80d70fe82df986be2e7bc39873d87dd4b02040f 127.0.0.1:9001@19001 slave b0a13bf57d4e514cffa305c44d41a5a92858eb9a 0 1648200335385 7 connected
2f90e0f293fcf95dada5ec3414d46f90411cd987 127.0.0.1:7001@17001 slave e64e780e3a83e871daca04ddf7d4489624d97054 0 1648200336402 5 connected
c9f7d10dc6d4f471a9d5660b67c44699474bba9b 127.0.0.1:6000@16000 myself,master - 0 1648200335000 1 connected 1365-5460
cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 127.0.0.1:7000@17000 master - 0 1648200334000 2 connected 6827-10922
e64e780e3a83e871daca04ddf7d4489624d97054 127.0.0.1:8000@18000 master - 0 1648200337408 3 connected 12288-16383
08f1fa2ecd26f2916092695a3aa5bcb4185c1eee 127.0.0.1:6001@16001 slave cf12b1d7074b1ef58d9f2cd8b3c50d9bdd53c125 0 1648200333367 4 connected
2d555ec571b26fe24012f126b600b2d742233574 127.0.0.1:8001@18001 slave c9f7d10dc6d4f471a9d5660b67c44699474bba9b 0 1648200334375 6 connected
```
