---
title: "Mongodb RepliSet 部署"
date: "2021-02-08T10:50:06+08:00"
draft: false
categories:
- mongodb
tags:
- mongodb
- mongodb-replication
---

## Replication Set 基本原理

MongoDB 复制集的基本构成是一主两从的结构，自带互相监控投标机制，使用 Raft 协议保证数据一致性，（MySQL MGR 用的是 Paxos 变种）
如果发生主库宕机，复制集内部会进行投票选举，选择一个新的主库替代原有主库对外提供服务。同时复制集会自动通知
客户端程序，主库已经发生切换了。应用就会连接到新的主库。

## Replication Set 配置过程

### 多实例复制集环境规划

三个以上的 mongodb 节点或多实例, 这里使用多实例。

- 多实例端口: 28017、28018、28019
- 多实例配置目录:  /data/mongodb/{28017,28018,28019}/etc
- 多实例配置目录:  /data/mongodb/{28017,28018,28019}/logs
- 多实例数据目录:  /data/mongodb/{28017,28018,28019}/data

### 创建多实例环境

使用以下脚本创建 MongoDB 多实例

```bash
#!/bin/bash
#
# filename: mongodb-instances.sh
#

for port in {28017..28019}; do
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
  bindIp: 127.0.0.1,10.7.171.239
  port: $port

replication:
  oplogSizeMB: 2048
  replSetName: my_repl
EOF
    echo "start mongodb $port instance"
    echo "/usr/local/mongodb/bin/mongod -f /data/mongodb/$port/etc/mongod.conf"
done
```

**执行脚本**

```bash
$ bash mongodb-instances.sh
start mongodb 28017 instance
/usr/local/mongodb/bin/mongod -f /data/mongodb/28017/etc/mongod.conf
start mongodb 28018 instance
/usr/local/mongodb/bin/mongod -f /data/mongodb/28018/etc/mongod.conf
start mongodb 28019 instance
/usr/local/mongodb/bin/mongod -f /data/mongodb/28019/etc/mongod.conf
```

**启用 mongodb 多实例服务**

```bash
## 使用 mongod 用户启动 mongodb 多实例服务
# su - mongod
$ /usr/local/mongodb/bin/mongod -f /data/mongodb/28017/etc/mongod.conf
about to fork child process, waiting until server is ready for connections.
forked process: 15702
child process started successfully, parent exiting
$ /usr/local/mongodb/bin/mongod -f /data/mongodb/28018/etc/mongod.conf
about to fork child process, waiting until server is ready for connections.
forked process: 15731
child process started successfully, parent exiting
$ /usr/local/mongodb/bin/mongod -f /data/mongodb/28019/etc/mongod.conf
about to fork child process, waiting until server is ready for connections.
forked process: 15760
child process started successfully, parent exiting

## 查看服务启动状态
$ ss -anptl | grep mongo
LISTEN     0      128    10.7.171.239:28017                    *:*                   users:(("mongod",pid=15702,fd=12))
LISTEN     0      128    127.0.0.1:28017                    *:*                   users:(("mongod",pid=15702,fd=11))
LISTEN     0      128    10.7.171.239:28018                    *:*                   users:(("mongod",pid=15731,fd=12))
LISTEN     0      128    127.0.0.1:28018                    *:*                   users:(("mongod",pid=15731,fd=11))
LISTEN     0      128    10.7.171.239:28019                    *:*                   users:(("mongod",pid=15760,fd=12))
LISTEN     0      128    127.0.0.1:28019                    *:*                   users:(("mongod",pid=15760,fd=11))
```

## 配置普通复制集

配置一主两从，从库为两普通从库

### 初始化复制集

```bash
$ mongo --port 28017 admin
## 定义初始化信息
> config = {_id: 'my_repl', members: [
    {_id: 0, host: '10.7.171.239:28017'},
    {_id: 1, host: '10.7.171.239:28018'},
    {_id: 2, host: '10.7.171.239:28019'}]
}
## 初始化复制集
> rs.initiate(config)
{
	"ok" : 1,
	"operationTime" : Timestamp(1614066863, 1),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1614066863, 1),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	}
}
```

### 查询复制集状态

```bash
my_repl:PRIMARY> rs.status()
{
	"set" : "my_repl",
	"date" : ISODate("2021-02-23T07:56:10.466Z"),
	"myState" : 1,
	"term" : NumberLong(1),
	"syncingTo" : "",
	"syncSourceHost" : "",
	"syncSourceId" : -1,
	"heartbeatIntervalMillis" : NumberLong(2000),
	"optimes" : {
		"lastCommittedOpTime" : {
			"ts" : Timestamp(1614066965, 1),
			"t" : NumberLong(1)
		},
		"readConcernMajorityOpTime" : {
			"ts" : Timestamp(1614066965, 1),
			"t" : NumberLong(1)
		},
		"appliedOpTime" : {
			"ts" : Timestamp(1614066965, 1),
			"t" : NumberLong(1)
		},
		"durableOpTime" : {
			"ts" : Timestamp(1614066965, 1),
			"t" : NumberLong(1)
		}
	},
	"members" : [  ## 这里记录集群中所有实例的信息及其状态
		{
			"_id" : 0,
			"name" : "10.7.171.239:28017",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 421,
			"optime" : {
				"ts" : Timestamp(1614066965, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2021-02-23T07:56:05Z"),
			"syncingTo" : "",
			"syncSourceHost" : "",
			"syncSourceId" : -1,
			"infoMessage" : "could not find member to sync from",
			"electionTime" : Timestamp(1614066874, 1),
			"electionDate" : ISODate("2021-02-23T07:54:34Z"),
			"configVersion" : 1,
			"self" : true,
			"lastHeartbeatMessage" : ""
		},
		{
			"_id" : 1,
			"name" : "10.7.171.239:28018",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 106,
			"optime" : {
				"ts" : Timestamp(1614066965, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1614066965, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2021-02-23T07:56:05Z"),
			"optimeDurableDate" : ISODate("2021-02-23T07:56:05Z"),
			"lastHeartbeat" : ISODate("2021-02-23T07:56:10.130Z"),
			"lastHeartbeatRecv" : ISODate("2021-02-23T07:56:08.582Z"),
			"pingMs" : NumberLong(0),
			"lastHeartbeatMessage" : "",
			"syncingTo" : "10.7.171.239:28017",
			"syncSourceHost" : "10.7.171.239:28017",
			"syncSourceId" : 0,
			"infoMessage" : "",
			"configVersion" : 1
		},
		{
			"_id" : 2,
			"name" : "10.7.171.239:28019",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 106,
			"optime" : {
				"ts" : Timestamp(1614066965, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1614066965, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2021-02-23T07:56:05Z"),
			"optimeDurableDate" : ISODate("2021-02-23T07:56:05Z"),
			"lastHeartbeat" : ISODate("2021-02-23T07:56:10.130Z"),
			"lastHeartbeatRecv" : ISODate("2021-02-23T07:56:08.581Z"),
			"pingMs" : NumberLong(0),
			"lastHeartbeatMessage" : "",
			"syncingTo" : "10.7.171.239:28017",
			"syncSourceHost" : "10.7.171.239:28017",
			"syncSourceId" : 0,
			"infoMessage" : "",
			"configVersion" : 1
		}
	],
	"ok" : 1,
	"operationTime" : Timestamp(1614066965, 1),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1614066965, 1),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	}
}
```

## 特殊从节点 (arbiter)

arbiter 节点，翻译过来就是仲裁节点的意义，arbiter 主要负责选主过程中的投票，但是不存储任何数据，也不提供任何服务。

当我们想搭建一主一从的 MongoDB 复制集时就需要配置 arbiter 节点了。

搭建过程和搭建普通复制集基本是一样的，就是初始化配置多加一个配置。

###  arbiter 复制集

```bash
$ mongo --port 28017 admin
## 定义初始化信息
> config = {_id: 'my_repl', members: [
    {_id: 0, host: '10.7.171.239:28017'},
    {_id: 1, host: '10.7.171.239:28018'},
    {_id: 2, host: '10.7.171.239:28019', "arbiterOnly": true }]
}
## 初始化复制集
> rs.initiate(config)
```

### 将普通复制集更改为含有 arbiter 节点复制集

要想将普通节点改为 `arbiter` 节点，需要先移除，再添加为 `arbiter` 节点。 

此例我们将 `10.7.171.239:28019` 节点更改为 `arbiter` 节点

```bash
## 移除 10.7.171.239:28019 节点
my_repl:PRIMARY> rs.remove('10.7.171.239:28019')
{
	"ok" : 1,
	"operationTime" : Timestamp(1614069229, 1),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1614069229, 1),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	}
}

## 添加为 arbiter 节点
my_repl:PRIMARY> rs.addArb('10.7.171.239:28019')
{
	"ok" : 1,
	"operationTime" : Timestamp(1614069241, 1),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1614069241, 1),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	}
}
```

> 复制集中的节点被移除时服务会自动停止，需要手动开启服务

### 查看 arbiter 复制集

```bash
my_repl:PRIMARY> rs.status()
{
	"set" : "my_repl",
	"date" : ISODate("2021-02-23T08:38:56.291Z"),
	"myState" : 1,
	"term" : NumberLong(1),
	"syncingTo" : "",
	"syncSourceHost" : "",
	"syncSourceId" : -1,
	"heartbeatIntervalMillis" : NumberLong(2000),
	"optimes" : {
		"lastCommittedOpTime" : {
			"ts" : Timestamp(1614069535, 1),
			"t" : NumberLong(1)
		},
		"readConcernMajorityOpTime" : {
			"ts" : Timestamp(1614069535, 1),
			"t" : NumberLong(1)
		},
		"appliedOpTime" : {
			"ts" : Timestamp(1614069535, 1),
			"t" : NumberLong(1)
		},
		"durableOpTime" : {
			"ts" : Timestamp(1614069535, 1),
			"t" : NumberLong(1)
		}
	},
	"members" : [
		{
			"_id" : 0,
			"name" : "10.7.171.239:28017",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 2987,
			"optime" : {
				"ts" : Timestamp(1614069535, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2021-02-23T08:38:55Z"),
			"syncingTo" : "",
			"syncSourceHost" : "",
			"syncSourceId" : -1,
			"infoMessage" : "",
			"electionTime" : Timestamp(1614066874, 1),
			"electionDate" : ISODate("2021-02-23T07:54:34Z"),
			"configVersion" : 3,
			"self" : true,
			"lastHeartbeatMessage" : ""
		},
		{
			"_id" : 1,
			"name" : "10.7.171.239:28018",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 2672,
			"optime" : {
				"ts" : Timestamp(1614069535, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1614069535, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2021-02-23T08:38:55Z"),
			"optimeDurableDate" : ISODate("2021-02-23T08:38:55Z"),
			"lastHeartbeat" : ISODate("2021-02-23T08:38:56.010Z"),
			"lastHeartbeatRecv" : ISODate("2021-02-23T08:38:56.015Z"),
			"pingMs" : NumberLong(0),
			"lastHeartbeatMessage" : "",
			"syncingTo" : "10.7.171.239:28017",
			"syncSourceHost" : "10.7.171.239:28017",
			"syncSourceId" : 0,
			"infoMessage" : "",
			"configVersion" : 3
		},
		{
			"_id" : 2,
			"name" : "10.7.171.239:28019",
			"health" : 1,
			"state" : 7,
			"stateStr" : "ARBITER",
			"uptime" : 174,
			"lastHeartbeat" : ISODate("2021-02-23T08:38:56.047Z"),
			"lastHeartbeatRecv" : ISODate("2021-02-23T08:38:55.204Z"),
			"pingMs" : NumberLong(0),
			"lastHeartbeatMessage" : "",
			"syncingTo" : "",
			"syncSourceHost" : "",
			"syncSourceId" : -1,
			"infoMessage" : "",
			"configVersion" : 3
		}
	],
	"ok" : 1,
	"operationTime" : Timestamp(1614069535, 1),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1614069535, 1),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	}
}
```

> 注意 "10.7.171.239:28019" 节点 "stateStr" 字段的值，此为 "ARBITER"， 说明 arbiter 节点配置成功

## 复制集管理操作

### 查看复制集状态信息

```bash
> rs.status();    //查看整体复制集状态
> rs.isMaster();  // 查看当前是否是主节点
> rs.conf()；     //查看复制集配置信息
```

### 添加删除节点

```bash
> rs.remove("ip:port");   // 删除一个节点
> rs.add("ip:port");      // 新增从节点
> rs.addArb("ip:port");     // 新增仲裁节点
```

> 注意: 以下操作需要在主节点上进行