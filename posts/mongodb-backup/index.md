# Mongodb 数据备份与恢复


## 备份工具介绍

MongoDB 自带两种备份工具, 以备份出的文件区分为文本备份工具与二进制备份工具，各有不同的适用场景。

### 文本备份工具

使用此工具备份出的文件是可读的，备份格式可选为 json 或 csv。 

*适用场景*

1. 异构平台: 当我们需要迁移 mysql 数据至 mongodb 时就可以选用此工具了(相反亦可)。
2. 同平台，跨大版本升级：mongodb2 --> mongodb3

- mongoexport: 以 CSV 或 JSON 格式从 MongoDB 导出数据
- mongoimport: 将 CSV，TSV 或 JSON 数据导入 MongoDB。 如果未提供文件，则 mongoimport 从 stdin 中读取。

*在 test 库中生成测试数据*

```javascript
ues test
for (var i=1; i<=10000; i++){
    db.rands.insert({id: i, date: new Date()})
}
```

#### mongoexport

**json 格式**

mongoexport 默认导入数据为 json 格式

```bash
$ mongoexport -u root -p root123 --authenticationDatabase admin -d test -c rands -o rands.json
2021-02-24T10:38:15.398+0800	connected to: localhost
2021-02-24T10:38:15.557+0800	exported 10000 records
```

**csv 格式**

导出 `csv` 格式需要加上 `--type` 选项并指定要导出的键名使用 `-f` 选项

```bash
$ mongoexport -u root -p root123 --authenticationDatabase admin -d test -c rands --type=csv -f id,date -o rands.csv
2021-02-24T10:44:01.075+0800	connected to: localhost
2021-02-24T10:44:01.144+0800	exported 10000 records
```

#### mongoimport

**导入 json 数据**

```bash
$ mongoimport -u root -p root123 --authenticationDatabase admin -d test -c rands --file rands.json
2021-02-24T10:52:55.845+0800	connected to: localhost
2021-02-24T10:52:55.935+0800	imported 10000 documents
```

**导入 csv 数据**

如果 csv 文件首行是为列名，需要加入 `--headerline` 选项，如果不是需要使用 `-f` 选项指定列名.

- `--headerline`: 指明第一行是列名，不需要导入

```bash
mongoimport -u root -p root123 --authenticationDatabase admin -d test -c rands --type=csv --headerline --file rands.csv
2021-02-24T10:55:23.714+0800	connected to: localhost
2021-02-24T10:55:23.776+0800	imported 10000 documents
```

> 注意: 数据导入是追加导入，所以不重复导入以免数据重复

### 二进制备份工具

日常备份恢复推荐使用此工具

mongodump 能够在 Mongodb 运行时进行备份，它的工作原理是对运行的 Mongodb 做查询，然后将所有查到的文档写入磁盘。

但是存在的问题时使用 mongodump 产生的备份不一定是数据库的实时快照，如果我们在备份时对数据库进行了写入操作，
则备份出来的文件可能不完全和 Mongodb 实时数据相等。另外在备份时可能会对其它客户端性能产生不利的影响。

#### mongodump

**参数说明**

- `-h`: 指明数据库宿主机的 IP
- `-u`: 指明数据库的用户名
- `-p`: 指明数据库的密码
- `--authenticationDatabase`: 指明验证库名
- `-d`: 指明数据库的名字
- `-c`: 指明 collection 的名字
- `-o`: 指明到要导出到的路径名
- `-q`: 指明导出数据的过滤条件
- `-j, --numParallelCollections`:  并行转储的集合数（默认为4个）
- `--oplog`: 备份的同时备份 oplog

##### 全库备份

不指定 `-d` 和 `-c` 选项时备份全库

```bash
$ mongodump -u root -p root123 --authenticationDatabase admin -o ./full
2021-02-24T11:13:12.997+0800	writing admin.system.users to
2021-02-24T11:13:12.997+0800	done dumping admin.system.users (1 document)
2021-02-24T11:13:12.997+0800	writing admin.system.version to
2021-02-24T11:13:12.998+0800	done dumping admin.system.version (2 documents)
2021-02-24T11:13:12.998+0800	writing test.rands to
2021-02-24T11:13:13.035+0800	done dumping test.rands (20000 documents)
```

> mongodump 备份的是 bson 格式的二进制文件, 备份目录不存在自动创建，目录结构按库名分

**备份 test 库**

```bash
$ mongodump -u root -p root123 --authenticationDatabase admin -d test -o /backup
2021-02-24T11:28:11.957+0800	writing test.rands to
2021-02-24T11:28:12.045+0800	done dumping test.rands (20000 documents)
```

#### mongorestore

**恢复 test 库**

```bash
$ mongorestore -u root -p root123 --authenticationDatabase admin -d test /backup/test
2021-02-24T11:34:47.061+0800	the --db and --collection args should only be used when restoring from a BSON file. Other uses are deprecated and will not exist in the future; use --nsInclude instead
2021-02-24T11:34:47.061+0800	building a list of collections to restore from test dir
2021-02-24T11:34:47.062+0800	reading metadata for test.rands from test/rands.metadata.json.gz
2021-02-24T11:34:47.067+0800	restoring test.rands from test/rands.bson.gz
2021-02-24T11:34:47.153+0800	no indexes to restore
2021-02-24T11:34:47.153+0800	finished restoring test.rands (20000 documents)
2021-02-24T11:34:47.153+0800	done
```

当我们恢复数据库出现这样的错误信息 `  - E11000 duplicate key error collection: test.rands index: _id_ dup key: { : ObjectId('6035c17ea0af461fd150f74c') }` 时，是因为数据重复无法写入此可以加入 `--drop` 选项解决, 但不建议使用 `--drop` 选项，此操作危险，可能会有数据丢失的风险。


