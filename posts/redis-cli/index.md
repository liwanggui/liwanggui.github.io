# Redis 基础操作



## Redis 命令

### 管理命令

- `info`: 查看 Redis 当前状态信息

```bash
127.0.0.1:6379> info
# Server
redis_version:3.2.9
redis_git_sha1:00000000
redis_git_dirty:0
redis_build_id:f0e03a357ae83877
redis_mode:standalone
os:Linux 3.10.0-862.el7.x86_64 x86_64
arch_bits:64
multiplexing_api:epoll
gcc_version:4.8.5
process_id:2502
run_id:c913615b9c199a0d7ba4454c38e1a65427525c60
tcp_port:6379
uptime_in_seconds:2047
uptime_in_days:0
hz:10
lru_clock:6276784
executable:/usr/local/bin/redis-server
config_file:/etc/redis/6379.conf

# Clients
connected_clients:1
client_longest_output_list:0
client_biggest_input_buf:0
blocked_clients:0

...(略)
# 只查看特定的信息
127.0.0.1:6379> info Memory
# Memory
used_memory:821088
used_memory_human:801.84K
used_memory_rss:7888896
used_memory_rss_human:7.52M
used_memory_peak:822064
used_memory_peak_human:802.80K
total_system_memory:1021902848
total_system_memory_human:974.56M
used_memory_lua:37888
used_memory_lua_human:37.00K
maxmemory:128000000
maxmemory_human:122.07M
maxmemory_policy:noeviction
mem_fragmentation_ratio:9.61
mem_allocator:jemalloc-4.0.3
```

- `client list`:  查看当前连接的客户端列表
- `client kill <ip:port>`:  结束客户端连接

```bash
127.0.0.1:6379> CLIENT LIST
id=3 addr=127.0.0.1:39676 fd=7 name= age=1340 idle=0 flags=N db=0 sub=0 psub=0 multi=-1 qbuf=0 qbuf-free=32768 obl=0 oll=0 omem=0 events=r cmd=client
# 危险，不要轻易操作
127.0.0.1:6379> CLIENT KILL 127.0.0.1:39676
OK
```

- `config get/set/rewrite`: 在线获取/修改配置信息
- `config resetstat`: 重置统计信息
- `dbsize`: 查看键值对数量
- `flushall`: 清空所有数据，危险操作
- `flushdb`: 清空当前库数据，危险操作
- `select <序号>`: 默认有16个库，切换库

```bash
127.0.0.1:6379> select 1
OK
127.0.0.1:6379[1]> select 15
OK
```

- `monitor`: 实时监控操作指令
- `shutdown`: 停止 redis 服务

### key 通用操作命令

- `keys`: 查看所有 key

```bash
127.0.0.1:6379> KEYS *
1) "user.age"
2) "user.email"
3) "user.name"
127.0.0.1:6379> KEYS *n*
1) "user.name"
127.0.0.1:6379> KEYS user*
1) "user.age"
2) "user.email"
3) "user.name"
```

> 注意: 不建议直接使用 `keys *` 直接查看，数量多的情况下会影响 redis 性能

- `type`: 查看 key 的类型

```bash
127.0.0.1:6379> TYPE user.name
string
127.0.0.1:6379> TYPE hbb
hash
```

- `expire/pexpire`: 以秒/毫秒设置 key 的存活时间
- `ttl/pttl`: 以秒/毫秒返回 key 的存活时间
- `persist`: 取消生存时间设置

```bash
127.0.0.1:6379> set te 123
OK
127.0.0.1:6379> EXPIRE te 20
(integer) 1
127.0.0.1:6379> ttl te
(integer) 16
127.0.0.1:6379> persist te
(integer) 1
127.0.0.1:6379> ttl te
(integer) -1
```

- `del`: 删除一个 key
- `exists`: 检查 key 是否存在
- `rename`: 重命名 key

```bash
127.0.0.1:6379> exists te
(integer) 1
127.0.0.1:6379> del te
(integer) 1
127.0.0.1:6379> exists te
(integer) 0
127.0.0.1:6379> set te adf
OK
127.0.0.1:6379> rename te tem
OK
127.0.0.1:6379> get tem
"adf"
127.0.0.1:6379> exists tem
(integer) 1
```

## Redis 数据类型

redis 支持的数据类型如下

- `String`： 字符类型
- `Hash`：字典类型
- `List`：列表     
- `Set`：集合 
- `Sorted set`：有序集合

### string 

- 应用场景: 
  - session 共享
  - 计数器：微博数，粉丝数，订阅、礼物

字符串类型操作命令

```bash
# 设置键的字符串值
127.0.0.1:6379> set mykey 0
OK
# 获取键的值
127.0.0.1:6379> get mykey
"0"
# 设置键的字符串值并返回其旧值
127.0.0.1:6379> getset key2 2
(nil)
# 设置键的值和有效期(单位秒)
127.0.0.1:6379> setex time 10 10
OK
127.0.0.1:6379> ttl time
(integer) 7
# 仅当密钥不存在时设置密钥的值
127.0.0.1:6379> setnx k3 3
(integer) 1
127.0.0.1:6379> get k3
"3"
# 将键的整数值加1
127.0.0.1:6379> incr sar
(integer) 1
# 将键的整数值减1
127.0.0.1:6379> decr sar
(integer) 0
# 将键的整数值增加给定的数量
127.0.0.1:6379> incrby sar 100
(integer) 100
# 将键的整数值减少给定的数量
127.0.0.1:6379> decrby sar 15
(integer) 85
# 同时为多个键设置多个值
127.0.0.1:6379> mset k1 1 k2 2 k3 3
OK
# 同时获取多个键的值
127.0.0.1:6379> mget k1 k2 k3
1) "1"
2) "2"
3) "3"
# 检测键是否存在
127.0.0.1:6379> exists k1
(integer) 1
# 获取键值的长度
127.0.0.1:6379> strlen k2
(integer) 1
```

### hash

应用场景: 存储部分变更的数据，如用户信息等, 最接近 mysql 表结构的一种类型,主要是可以做数据库缓存

hash 字典类型操作命令

```bash
# 设置字典
127.0.0.1:6379> hmset stu id 101 name zhangsan age 20 gender m
OK
# 获取字典多个字段值
127.0.0.1:6379> hmget stu name age gender
1) "zhangsan"
2) "20"
3) "m"
# 获取 stu 键的字段数量
127.0.0.1:6379> hlen stu
(integer) 4
# 判断 stu 键中是否存在 name 的字段
127.0.0.1:6379> hexists stu name
(integer) 1
# 返回 stu 键的所有字段和值
127.0.0.1:6379> hgetall stu
1) "id"
2) "101"
3) "name"
4) "zhangsan"
5) "age"
6) "20"
7) "gender"
8) "m"
# 获取 stu 所有字段名称
127.0.0.1:6379> hkeys stu
1) "id"
2) "name"
3) "age"
4) "gender"
# 获取 stu 所有字段的值
127.0.0.1:6379> hvals stu
1) "101"
2) "zhangsan"
3) "20"
4) "m"
```

### list

应用场景: 消息队列系统，社交类朋友圈

*创建一个列表*

每次插入的数据都会放在最前面，第一个索引号为 0

```bash
127.0.0.1:6379> lpush wechat "today is nice day !"
(integer) 1
127.0.0.1:6379> lpush wechat "today is bad day !"
(integer) 2
127.0.0.1:6379> lpush wechat "today is good day !"
(integer) 3
127.0.0.1:6379> lpush wechat "today is rainy day !"
(integer) 4
127.0.0.1:6379> lpush wechat "today is friday day !"
(integer) 5
```

*获取列表中的数据*

```bash
# 取最新1条数据
127.0.0.1:6379> lrange wechat  0 0
1) "today is friday day !"
# 取所有数据
127.0.0.1:6379> lrange wechat 0 -1
1) "today is friday day !"
2) "today is rainy day !"
3) "today is good day !"
4) "today is bad day !"
5) "today is nice day !"
# 取最新的前3条数据
127.0.0.1:6379> lrange wechat 0 2
1) "today is friday day !"
2) "today is rainy day !"
3) "today is good day !"
# 取最后2条数据
127.0.0.1:6379> lrange wechat -2 -1
1) "today is bad day !"
2) "today is nice day !"
```

**列表的 增、删、改、查 操作命令**

```
# 增 
lpush mykey a b             若key不存在,创建该键及与其关联的List,依次插入a ,b， 若List类型的key存在,则插入value中
lpushx mykey2 e             若key不存在,此命令无效， 若key存在,则插入value中
linsert mykey before a a1   在 a 的前面插入新元素 a1
linsert mykey after e e2    在e 的后面插入新元素 e2
rpush mykey a b             在链表尾部先插入b,在插入a
rpushx mykey e              若key存在,在尾部插入e, 若key不存在,则无效
rpoplpush mykey mykey2      将mykey的尾部元素弹出,再插入到mykey2 的头部(原子性的操作)

# 删
del mykey                   删除已有键 
lrem mykey 2 a              从头部开始找,按先后顺序,值为a的元素,删除数量为2个,若存在第3个,则不删除
ltrim mykey 0 2             从头开始,索引为0,1,2的3个元素,其余全部删除

# 改
lset mykey 1 e              从头开始, 将索引为1的元素值,设置为新值 e,若索引越界,则返回错误信息
rpoplpush mykey mykey       将 mykey 中的尾部元素移到其头部

# 查
lrange mykey 0 -1           取链表中的全部元素，其中0表示第一个元素,-1表示最后一个元素。
lrange mykey 0 2            从头开始,取索引为0,1,2的元素
lrange mykey 0 0            从头开始,取第一个元素,从第0个开始,到第0个结束
lpop mykey                  获取头部元素,并且弹出头部元素,出栈
lindex mykey 6              从头开始,获取索引为6的元素 若下标越界,则返回nil 
```

### set

案例：在微博应用中，可以将一个用户所有的关注人存在一个集合中，将其所有粉丝存在一个集合中。

Redis 还为集合提供了求交集、并集、差集等操作，可以非常方便的实现如共同关注、共同喜好、二度好友等功能，
对上面的所有集合操作，你还可以使用不同的命令选择将结果返回给客户端还是存集到一个新的集合中。

```bash
127.0.0.1:6379> sadd lxl pg1 jnl baoqiang gsy alexsb
(integer) 5
127.0.0.1:6379> sadd jnl baoqiang ms bbh yf wxg
(integer) 5
# 求并集
127.0.0.1:6379> sunion lxl jnl
1) "bbh"
2) "baoqiang"
3) "pg1"
4) "alexsb"
5) "gsy"
6) "ms"
7) "yf"
8) "jnl"
9) "wxg"
# 求交集
127.0.0.1:6379> sinter lxl jnl
1) "baoqiang"
# 求差集
127.0.0.1:6379> sdiff lxl jnl
1) "alexsb"
2) "pg1"
3) "gsy"
4) "jnl"
```

*增、删、改、查*

```
# 增
sadd myset a b c 
若 key 不存在, 创建该键及与其关联的 set, 依次插入a ,b, 若key存在, 则插入value中, 若 a 在myset中已经存在,则插入了 d 和 e 两个新成员。

# 删
spop myset              尾部的 b 被移出, 事实上 b 并不是之前插入的第一个或最后一个成员
srem myset a d f        若 f 不存在, 移出 a、d ,并返回2

# 改
smove myset myset2 a    将a从 myset 移到 myset2，

# 查
sismember myset a                         判断 a 是否已经存在，返回值为 1 表示存在。
smembers myset                            查看 set 中的内容
scard myset                               获取 set 集合中元素的数量
srandmember myset                         随机的返回某一成员
sdiff myset1 myset2 myset3                1和2得到一个结果,拿这个集合和3比较,获得每个独有的值
sdiffstore diffkey myset myset2 myset3    3个集和比较,获取独有的元素,并存入diffkey 关联的Set中
sinter myset myset2 myset3                获得3个集合中都有的元素
sinterstore interkey myset myset2 myset3  把交集存入interkey 关联的Set中
sunion myset myset2 myset3                获取3个集合中的成员的并集
sunionstore unionkey myset myset2 myset3  把并集存入unionkey 关联的Set中
```

### sorted set

应用场景：

排行榜应用，取 TOP N 操作

这个需求与上面需求的不同之处在于，前面操作以时间为权重，这个是以某个条件为权重，比如按顶的次数排序，
这时候就需要我们的 sorted set 出马了，将你要排序的值设置成 sorted set 的score，将具体的数据设置成相应的 value，每次只需要执行一条 ZADD 命令即可。

```bash
127.0.0.1:6379> zadd topN 0 smlt 0 fskl 0 fshkl 0 lzlsfs 0 wdhbx 0 wxg
(integer) 6
127.0.0.1:6379> ZINCRBY topN 100000 smlt
"100000"
127.0.0.1:6379> ZINCRBY topN 10000 fskl
"10000"
127.0.0.1:6379> ZINCRBY topN 1000000 fshkl
"1000000"
127.0.0.1:6379> ZINCRBY topN 100 lzlsfs
"100"
127.0.0.1:6379> ZINCRBY topN 100000000 wxg
"100000000"
127.0.0.1:6379> ZREVRANGE topN 0 2
1) "wxg"
2) "fshkl"
3) "smlt"
127.0.0.1:6379> ZREVRANGE topN 0 2 withscores
1) "wxg"
2) "100000000"
3) "fshkl"
4) "1000000"
5) "smlt"
6) "100000"
```

*增、删、改、查*

```
# 增
zadd myzset 2 "two" 3 "three"           添加两个分数分别是 2 和 3 的两个成员

# 删
zrem myzset one two                     删除多个成员变量,返回删除的数量

# 改
zincrby myzset 2 one                    将成员 one 的分数增加 2，并返回该成员更新后的分数

# 查 
zrange myzset 0 -1 WITHSCORES           返回所有成员和分数,不加WITHSCORES,只返回成员
zrank myzset one                        获取成员one在Sorted-Set中的位置索引值。0表示第一个位置
zcard myzset                            获取 myzset 键中成员的数量
zcount myzset 1 2                       获取分数满足表达式 1 <= score <= 2 的成员的数量
zscore myzset three                     获取成员 three 的分数
zrangebyscore myzset  1 2               获取分数满足表达式 1 < score <= 2 的成员
#-inf 表示第一个成员，+inf最后一个成员
#limit限制关键字
#2  3  是索引号
zrangebyscore myzset -inf +inf limit 2 3  返回索引是2和3的成员
zremrangebyscore myzset 1 2               删除分数 1<= score <= 2 的成员，并返回实际删除的数量
zremrangebyrank myzset 0 1                删除位置索引满足表达式 0 <= rank <= 1 的成员
zrevrange myzset 0 -1 WITHSCORES          按位置索引从高到低,获取所有成员和分数
#原始成员:位置索引从小到大
      one  0  
      two  1
#执行顺序:把索引反转
      位置索引:从大到小
      one 1
      two 0
#输出结果: two  
       one
zrevrange myzset 1 3                        获取位置索引,为1,2,3的成员
#相反的顺序:从高到低的顺序
zrevrangebyscore myzset 3 0                 获取分数 3>=score>=0的成员并以相反的顺序输出
zrevrangebyscore myzset 4 0 limit 1 2       获取索引是1和2的成员,并反转位置索引
```
