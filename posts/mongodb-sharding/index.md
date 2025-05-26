# Mongodb 分片(sharding)集群部署


## 环境准备

这里使用3台虚拟机来部署 mongodb 分片集群; 各角色使用的 ip, 端口如下表

|角色|端口|ip 地址|
|:--|:--|:--|
|mongos|28017|172.16.1.100|
|config|27017|172.16.1.100|
|config|27018|172.16.1.100|
|config|27019|172.16.1.100|
|shard1|27017|172.16.1.101|
|shard1|27018|172.16.1.101|
|shard1|27019|172.16.1.101|
|shard2|27017|172.16.1.102|
|shard2|27018|172.16.1.102|
|shard2|27019|172.16.1.102|

**内部鉴权**

节点间鉴权采用 `keyfile` 方式实现鉴权，`mongos` 与分片之间、副本集节点之间共享同一套 `keyfile` 文件

**账户设置**

- 管理员账户：`admin/admin`，具有集群及所有库的管理权限
- 应用账号：`appuser/appuser`，具有 appdb 的 owner 权限

**关于初始化权限**

keyfile 方式默认会开启鉴权，而针对初始化安装的场景，Mongodb 提供了 [localhost-exception](https://docs.mongodb.com/manual/core/security-users/#localhost-exception) 机制，可以在首次安装时通过本机创建用户、角色，以及副本集初始化操作。

## 部署集群

### 准备工作

下载 mongodb 

```bash
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.6.20.tgz
```

安装 mongodb

```bash
cd /usr/local/src
tar xzf mongodb-linux-x86_64-rhel62-3.6.20.tgz -C /usr/local/
cd /usr/local/
ln -s /usr/local/mongodb-linux-x86_64-rhel62-3.6.20 /usr/local/mongodb
# 加入环境变量
echo 'export PATH=/usr/local/mongodb/bin:$PATH' > /etc/profile.d/mongo.sh
source /etc/profile
```

mongodb 配置所使用的相关路径如下

- `/data/mongodb/<端口>/etc` : 配置文件目录
- `/data/mongodb/<端口>/data` : 数据目录
- `/data/mongodb/<端口>/logs` : 日志目录
- `/data/mongodb/mongod.key` : keyfile 文件路径

*mongos 路径*

- `/data/mongos/<端口>/etc` : 配置文件目录
- `/data/mongos/<端口>/logs` : 日志目录

生成 `keyfile`, 所有实例都会用到

```bash
openssl rand -base64 756 > mongo.key
```

### 部署分片复制集

在以下服务器上进行操作，以 `172.16.1.101` 为例

- 172.16.1.101
- 172.16.1.102

> 在 `172.16.1.102` 上操作时注意修改相应参数

```bash
for port in {27017..27019}; do
# 创建多实例目录
    mkdir -p /data/mongodb/$port/etc
    mkdir -p /data/mongodb/$port/logs
    mkdir -p /data/mongodb/$port/data
    # chown -R mongod.mongod /data/mongodb/$port
# 生成配置文件
    cat > /data/mongodb/$port/etc/mongod.conf <<EOF
systemLog:
  destination: file
  path: /data/mongodb/$port/logs/mongodb.log
  logAppend: true

storage:
  journal:
    enabled: true
  dbPath: /data/mongodb/$port/data
  directoryPerDB: true
  #engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true

processManagement:
  fork: true

net:
  bindIp: 127.0.0.1,172.16.1.101
  port: $port

security:
  keyFile: /data/mongodb/mongod.key

replication:
  oplogSizeMB: 2048
  # 同一个分片复制集名称保持一致，不同分片名称必须不同
  replSetName: sh1

# 启用分片
sharding:
  clusterRole: shardsvr
EOF
    echo "start mongodb $port instance"
    echo "/usr/local/mongodb/bin/mongod -f /data/mongodb/$port/etc/mongod.conf"
done

cat >/data/mongodb/mongod.key<<EOF
ry2cCv+u8AuoVsKmQqmwOXeP2nfH+CG+VD9dMpUUHcggztWQ09VDyXJTXhGgBnYu
a9UH3jvfbmT7mqRV2esOxSnTazcY5mXjyMCMzgaSvpN8OtfuDZXX20v5qpYCqjCj
xlLyyDkeFhOeTqWJcQKvwhZnh0SXC65QwGxeEL8DRnLXziBAooR4EYkRGgZnGvmP
23KRhagRgQ7iwivwiXoepf+PwtZ3DKi2wudUTcojvFPa+ls5rhXSnEGChMPlL8zV
b+xGDdOe4YDOiDoAATYLRkDUfUpG8DF921azQ4WH1g7BJU/zY2CpAX8nd4lhBA7o
6YD51kR6odBGUGGarZOvk7tW4DY+sWSK5pbc7nttFICUcw87K1R9Hxe1wEVNqo/m
xcQ0vtgJ7IvHRwIbvYxmEoEfnBzqOkfZLXKgE/tgEvphdoiUCCyJ89JrkN3W8o2Q
yb1RuvEOPE+8MjyE1vKkwuwnn95ePle8AJ8+fb3W5p5n2lNpBYrbe2CfWjRVMqri
bnnb93DsG5Qd4U+QYJ/ZSnAofPdSLRxQn54MLIPHRuPlpJuCQXeB0bnQeGbTMjaO
2aaB+kOpwfWMcQBqvdErdQqeFgITFEGTG1sa92Nc+9zO07R6FQ7qveKTOMoH1hLB
chfBPAt5pck50h3DtGMZgmhCzR2606VOVgiOw4s4UQoG28fvA9Fhj/xA2qIFcloz
Yz9urc0bFMoOQOVPCmClFbUTbG+Jp1O1yc0RbXyBvecPs4BQNdSd+K1KE5BcWGsy
RkgmsNUEaPMIqiT7SVYxny59UmegW1uiict3orJtOEAuRlEDAWn6E0E6FYWoy9Qk
CYk+X7kB1CF15/KYGCsADxPf5YZy1UpWjiJtWYozKGwH/Ri1dLs3CMUxbNPArcBV
THh3GHz4gE31/cZpRSux3LN/uLOEyCQvwHmdwngDantN52Ma/KwQBcbqBGeoTUq3
4VhBTVzaOng/F1t+XAZtrXB0XM6MsztAvYP2Brpw/54DSBTM
EOF
chmod 600 /data/mongodb/mongod.key
```

> 注意：keyfile 的权限必须为 600

启动 mongodb 服务

```bash
/usr/local/mongodb/bin/mongod -f /data/mongodb/27017/etc/mongod.conf
/usr/local/mongodb/bin/mongod -f /data/mongodb/27018/etc/mongod.conf
/usr/local/mongodb/bin/mongod -f /data/mongodb/27019/etc/mongod.conf
```

初始化集群

```bash
$ mongo --port 27017 admin
## 定义初始化信息
> config = {_id: 'sh1', members: [
    {_id: 0, host: '172.16.1.101:27017'},
    {_id: 1, host: '172.16.1.101:27018'},
    {_id: 2, host: '172.16.1.101:27019'}]
}
## 初始化复制集
> rs.initiate(config)
```

### 部署配置集群

在 `172.16.1.100` 服务器上操作

```bash
for port in {27017..27019}; do
# 创建多实例目录
    mkdir -p /data/mongodb/$port/etc
    mkdir -p /data/mongodb/$port/logs
    mkdir -p /data/mongodb/$port/data
    chown -R mongod.mongod /data/mongodb/$port
# 生成配置文件
    cat > /data/mongodb/$port/etc/mongod.conf <<EOF
systemLog:
  destination: file
  path: /data/mongodb/$port/logs/mongodb.log
  logAppend: true

storage:
  journal:
    enabled: true
  dbPath: /data/mongodb/$port/data
  directoryPerDB: true
  #engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true

processManagement:
  fork: true

net:
  bindIp: 127.0.0.1,172.16.1.100
  port: $port

security:
  keyFile: /data/mongodb/mongod.key

replication:
  oplogSizeMB: 2048
  replSetName: configReplSet

# 分片配置服务器
sharding:
  clusterRole: configsvr

EOF
    echo "start mongodb $port instance"
    echo "/usr/local/mongodb/bin/mongod -f /data/mongodb/$port/etc/mongod.conf"
done

cat >/data/mongodb/mongod.key<<EOF
ry2cCv+u8AuoVsKmQqmwOXeP2nfH+CG+VD9dMpUUHcggztWQ09VDyXJTXhGgBnYu
a9UH3jvfbmT7mqRV2esOxSnTazcY5mXjyMCMzgaSvpN8OtfuDZXX20v5qpYCqjCj
xlLyyDkeFhOeTqWJcQKvwhZnh0SXC65QwGxeEL8DRnLXziBAooR4EYkRGgZnGvmP
23KRhagRgQ7iwivwiXoepf+PwtZ3DKi2wudUTcojvFPa+ls5rhXSnEGChMPlL8zV
b+xGDdOe4YDOiDoAATYLRkDUfUpG8DF921azQ4WH1g7BJU/zY2CpAX8nd4lhBA7o
6YD51kR6odBGUGGarZOvk7tW4DY+sWSK5pbc7nttFICUcw87K1R9Hxe1wEVNqo/m
xcQ0vtgJ7IvHRwIbvYxmEoEfnBzqOkfZLXKgE/tgEvphdoiUCCyJ89JrkN3W8o2Q
yb1RuvEOPE+8MjyE1vKkwuwnn95ePle8AJ8+fb3W5p5n2lNpBYrbe2CfWjRVMqri
bnnb93DsG5Qd4U+QYJ/ZSnAofPdSLRxQn54MLIPHRuPlpJuCQXeB0bnQeGbTMjaO
2aaB+kOpwfWMcQBqvdErdQqeFgITFEGTG1sa92Nc+9zO07R6FQ7qveKTOMoH1hLB
chfBPAt5pck50h3DtGMZgmhCzR2606VOVgiOw4s4UQoG28fvA9Fhj/xA2qIFcloz
Yz9urc0bFMoOQOVPCmClFbUTbG+Jp1O1yc0RbXyBvecPs4BQNdSd+K1KE5BcWGsy
RkgmsNUEaPMIqiT7SVYxny59UmegW1uiict3orJtOEAuRlEDAWn6E0E6FYWoy9Qk
CYk+X7kB1CF15/KYGCsADxPf5YZy1UpWjiJtWYozKGwH/Ri1dLs3CMUxbNPArcBV
THh3GHz4gE31/cZpRSux3LN/uLOEyCQvwHmdwngDantN52Ma/KwQBcbqBGeoTUq3
4VhBTVzaOng/F1t+XAZtrXB0XM6MsztAvYP2Brpw/54DSBTM
EOF
chmod 0600 /data/mongodb/mongod.key
```

> 注意：keyfile 的权限必须为 600

启动 mongodb 服务

```bash
/usr/local/mongodb/bin/mongod -f /data/mongodb/27017/etc/mongod.conf
/usr/local/mongodb/bin/mongod -f /data/mongodb/27018/etc/mongod.conf
/usr/local/mongodb/bin/mongod -f /data/mongodb/27019/etc/mongod.conf
```

初始化集群

```bash
$ mongo --port 27017 admin
## 定义初始化信息
> config = {_id: 'configReplSet', members: [
    {_id: 0, host: '172.16.1.100:27017'},
    {_id: 1, host: '172.16.1.100:27018'},
    {_id: 2, host: '172.16.1.100:27019'}]
}
## 初始化复制集
> rs.initiate(config)
```

### 部署 mongos

在 `172.16.1.100` 服务器上操作

```bash
mkdir -p /data/mongos/{etc,logs}

cat > /data/mongos/etc/mongos.conf <<EOF
systemLog:
  destination: file
  path: /data/mongos/logs/mongos.log
  logAppend: true

net:
  bindIp: 127.0.0.1,172.16.1.100
  port: 28017

security:
  keyFile: /data/mongodb/mongod.key

sharding:
  configDB: configReplSet/172.16.1.100:27017,172.16.1.100:27018,172.16.1.100:27019

processManagement:
  fork: true
EOF
```

启动 mongos 服务

```bash
/usr/local/mongodb/bin/mongos -f /data/mongos/etc/mongos.conf
```

## 添加分片服务器

通过 mongos 操作, 连接至 mongos 服务器

```bash
mongo --port 28017
```

添加分片集群

```bash
mongos> sh.addShard("sh1/172.16.1.101:27017")
mongos> sh.addShard("sh2/172.16.1.102:27017")
```

## 初始化管理用户

创建集群管理员账号, 连接至 `mongos` 输入以下命令

```bash
use admin
db.createUser({
    user:'admin', pwd:'admin',
    roles:[
        {role:'clusterAdmin',db:'admin'},
        {role:'userAdminAnyDatabase',db:'admin'},
        {role:'dbAdminAnyDatabase',db:'admin'},
        {role:'readWriteAnyDatabase',db:'admin'}
]})
```

检查集群状态命令需要身份验证通过才能执行

```bash
mongos> sh.status()
--- Sharding Status ---
  sharding version: {
  	"_id" : 1,
  	"minCompatibleVersion" : 5,
  	"currentVersion" : 6,
  	"clusterId" : ObjectId("611342dcd920275eccff657f")
  }
  shards:
        {  "_id" : "sh1",  "host" : "sh1/172.16.1.101:27017,172.16.1.101:27018,172.16.1.101:27019",  "state" : 1 }
        {  "_id" : "sh2",  "host" : "sh2/172.16.1.102:27017,172.16.1.102:27018,172.16.1.102:27019",  "state" : 1 }
  active mongoses:
        "3.6.20" : 1
  autosplit:
        Currently enabled: yes
  balancer:
        Currently enabled:  yes
        Currently running:  no
        Failed balancer rounds in last 5 attempts:  0
        Migration Results for the last 24 hours:
                No recent migrations
  databases:
        {  "_id" : "config",  "primary" : "config",  "partitioned" : true }
                config.system.sessions
                        shard key: { "_id" : 1 }
                        unique: false
                        balancing: true
                        chunks:
                                sh1	1
                        { "_id" : { "$minKey" : 1 } } -->> { "_id" : { "$maxKey" : 1 } } on : sh1 Timestamp(1, 0)
```

> 关于集群用户与复制集本地用户说明

分片集群中的访问都会通过 `mongos` 入口，而鉴权数据是存储在 `config` 副本集中的，即 `config` 实例中 `admin.system.users` 数据库存储了集群用户及角色权限配置。

`mongos` 与 `shard` 实例则通过内部鉴权 (keyfile 机制) 完成，因此 `shard` 实例上可以通过添加本地用户以方便操作管理。在一个副本集上，只需要在 `Primary` 节点上添加用户及权限，相关数据会自动同步到 `Secondary` 节点

*为 sh1/sh2 复制集创建本地管理用户*

```js
use admin
db.createUser({user:'root',pwd:'root123',roles:[{role:'root',db:'admin'}]})
```

## 使用分片集群

创建 appuser 用户、为数据库 appdb 启动分片。

```bash
mongos> use appdb
switched to db appdb
mongos> db.createUser({user:'appuser',pwd:'appuser',roles:[{role:'dbOwner',db:'appdb'}]})
Successfully added user: {
	"user" : "appuser",
	"roles" : [
		{
			"role" : "dbOwner",
			"db" : "appdb"
		}
	]
}
# 启动分片
mongos> sh.enableSharding("appdb")
{
	"ok" : 1,
	"operationTime" : Timestamp(1628653967, 8),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1628653967, 8),
		"signature" : {
			"hash" : BinData(0,"i1anstgDj52hxkVuk35ovKp4rB0="),
			"keyId" : NumberLong("6995008158896750620")
		}
	}
}
```

创建集合 book，为其执行分片初始化

```bash
# 创建 book 集合
mongos> db.createCollection("book")
{
	"ok" : 1,
	"operationTime" : Timestamp(1628654035, 2),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1628654035, 2),
		"signature" : {
			"hash" : BinData(0,"xaHyTUdZgqesb5vp1uwGdD9hhzU="),
			"keyId" : NumberLong("6995008158896750620")
		}
	}
}
# 创建索引
mongos> db.book.ensureIndex( { id: 1 } )
{
	"raw" : {
		"sh2/172.16.1.102:27017,172.16.1.102:27018,172.16.1.102:27019" : {
			"createdCollectionAutomatically" : false,
			"numIndexesBefore" : 1,
			"numIndexesAfter" : 2,
			"ok" : 1
		}
	},
	"ok" : 1,
	"operationTime" : Timestamp(1628654068, 1),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1628654068, 1),
		"signature" : {
			"hash" : BinData(0,"WgBJJi1ToTcvLrnkV/tl3TU3uWg="),
			"keyId" : NumberLong("6995008158896750620")
		}
	}
}
# 开启分片
mongos> sh.shardCollection("appdb.book", {id: "hashed"})
{
	"collectionsharded" : "appdb.book",
	"collectionUUID" : UUID("62617c67-1c9b-453d-8505-4622190fc738"),
	"ok" : 1,
	"operationTime" : Timestamp(1628654268, 55),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1628654268, 55),
		"signature" : {
			"hash" : BinData(0,"FScHlkPUhSWN3k7a0RaXRYtBkR4="),
			"keyId" : NumberLong("6995008158896750620")
		}
	}
}
```

往 book 集合写入 1000W 条记录，观察 chunks 的分布情况

```js
use appdb
var cnt = 0;
for(var i=0; i<1000; i++){
    var dl = [];
    for(var j=0; j<100; j++){
        dl.push({
                "id" : "BBK-" + i + "-" + j,
                "type" : "Revision",
                "version" : "IricSoneVB0001",
                "title" : "Jackson's Life",
                "subCount" : 10,
                "location" : "China CN Shenzhen Futian District",
                "author" : {
                      "name" : 50,
                      "email" : "RichardFoo@yahoo.com",
                      "gender" : "female"
                },
                "createTime" : new Date()
            });
      }
      cnt += dl.length;
      db.book.insertMany(dl);
      print("insert ", cnt);
}
```

查看 chunks 的分布情况

```bash
mongos> db.book.getShardDistribution()

Shard sh1 at sh1/172.16.1.101:27017,172.16.1.101:27018,172.16.1.101:27019
 data : 13.22MiB docs : 49905 chunks : 2
 estimated data per chunk : 6.61MiB
 estimated docs per chunk : 24952

Shard sh2 at sh2/172.16.1.102:27017,172.16.1.102:27018,172.16.1.102:27019
 data : 13.27MiB docs : 50095 chunks : 2
 estimated data per chunk : 6.63MiB
 estimated docs per chunk : 25047

Totals
 data : 26.49MiB docs : 100000 chunks : 4
 Shard sh1 contains 49.9% data, 49.9% docs in cluster, avg obj size on shard : 277B
 Shard sh2 contains 50.09% data, 50.09% docs in cluster, avg obj size on shard : 277B
 ```

连接 `sh1/sh2` 查看 (需要创建本地管理用户账号)

*sh1*

```bash
sh2:PRIMARY> use admin
sh1:PRIMARY> db.auth('root', 'root123')
1
sh1:PRIMARY> use appdb
switched to db appdb
sh1:PRIMARY> db.book.count()
49905
```

*sh2*

```bash
sh2:PRIMARY> use admin
sh2:PRIMARY> db.auth('root', 'root123')
1
sh2:PRIMARY> use appdb
switched to db appdb
sh2:PRIMARY> db.book.count()
50095
```

## 分片集群的查询及管理

判断是否 Shard 集群

```bash
mongos> use admin
mongos> db.runCommand({ isdbgrid : 1})
```

列出所有分片信息

```bash
mongos> use admin
mongos> db.runCommand({ listshards : 1})
```

列出开启分片的数据库

```bash
mongos> use config
mongos> db.databases.find( { "partitioned": true } )
# 或者：
mongos> db.databases.find() //列出所有数据库分片情况
```

查看分片的片键

```bash
mongos> use config
mongos> db.collections.find().pretty()
{
	"_id" : "config.system.sessions",
	"lastmodEpoch" : ObjectId("611343e1d920275eccff6b43"),
	"lastmod" : ISODate("1970-02-19T17:02:47.296Z"),
	"dropped" : false,
	"key" : {
		"_id" : 1
	},
	"unique" : false,
	"uuid" : UUID("1ec5dcd3-bb66-46fb-9a21-8dbb7006a43c")
}
{
	"_id" : "appdb.book",
	"lastmodEpoch" : ObjectId("61134abcd920275eccff9665"),
	"lastmod" : ISODate("1970-02-19T17:02:47.297Z"),
	"dropped" : false,
	"key" : {
		"id" : "hashed"
	},
	"unique" : false,
	"uuid" : UUID("62617c67-1c9b-453d-8505-4622190fc738")
}
```

查看分片的详细信息

```bash
mongos> sh.status()
```

删除分片节点（谨慎）

```bash
# 确认 blance 是否在工作
sh.getBalancerState()

# 删除 sh2 节点(谨慎)
mongos> db.runCommand( { removeShard: "sh2" } )
```

> 注意：删除操作一定会立即触发 blancer

## balancer 操作

mongos 的一个重要功能，自动巡查所有 shard 节点上的 chunk 的情况，自动做 chunk 迁移。

什么时候工作？

1. 自动运行，会检测系统不繁忙的时候做迁移
2. 在做节点删除的时候，立即开始迁移工作
3. balancer 只能在预设定的时间窗口内运行

有需要时可以关闭和开启 blancer（备份的时候）

```bash
mongos> sh.stopBalancer()
mongos> sh.startBalancer()
```

自定义 blancer 自动平衡进行的时间段 - [官方文档](https://docs.mongodb.com/manual/tutorial/manage-sharded-cluster-balancer/#schedule-the-balancing-window)

```js
use config
sh.setBalancerState( true )
db.settings.update(
    { _id : "balancer" }, 
    { $set : { activeWindow : { start : "3:00", stop : "5:00" } } }, 
    { upsert: true }
)

sh.getBalancerWindow()
sh.status()
```

关闭 appdb.book 集合的 balance

```js
sh.disableBalancing("appdb.book")
```

打开 appdb.book 集合的 balancer

```js
sh.enableBalancing("appdb.book")
```

确定 appdb.book 集合的 balance 是开启或者关闭

```js
db.getSiblingDB("config").collections.findOne({_id : "appdb.book"}).noBalance
```

