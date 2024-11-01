# MySQL bin-log 日志


## binlog 作用

主要记录数据库变化(DDL,DML,DCL)性质的日志

- 用于数据恢复：如果你的数据库出问题了，而你之前有过备份，那么可以看日志文件，找出是哪个命令导致你的数据库出问题了，想办法挽回损失。
- 主从服务器之间同步数据：主服务器上所有的操作都在记录日志中，从服务器可以根据该日志来进行，以确保两个同步。

## 配置

MySQL 8.0 版本以前默认都没有开启，生产环境建议开启

*配置方法*

```ini
[mysqld]
# 主机编号，主从中使用，5.7 版本中 开启 binlog 必须设置 server_id
server_id = 1
# binlog 日志名前缀，『/data/mysql/binlog』 binlog 存储目录， 『mysql-bin』 binlog 文件名前缀，便如 mysql-bin.000001 mysql-bin.000002
log_bin = /data/mysql/binlog/mysql-bin
# binlog 日志写入磁盘策略，双1参数中的其中一个
sync_binlog = 1 
# binlog 日志记录格式为 row
binlog_format = row 
# binlog 保存天数
expire_logs_days = 7
```

> 注意: binlog 日志最好和数据分开存储

## 记录内容

binlog 是 SQL 层的功能。记录的是变更 SQL 语句，不记录查询语句。

### 记录 SQL 语句种类

- DDL：原封不动记录当前 DDL（statement 语句方式）
- DML：原封不动记录当前 DDL（statement 语句方式）
- DCL：只记录已提交事务的 DML (insert, update, delete)

### DML 三种语句记录方式

1. statement (5.6 默认) SBR (statement based replication): 原封不动的记录当前DML
2. ROW (5.7 默认) RBR (ROW based replication): 记录数据行的变化，用户看不懂（需要工具分析）
3. mixed (混合) MBR (mixed based replication): 以上两模式的混合 

- STATEMENT 模式 可读性较高，日志量小，不够严谨
- ROW 模式 可读性很低，日志量大，足够严谨

> 建议使用 ROW 模式

## 事件的简介

二进制日志的最小单元，对于 DML,DCL，一条语句就是一个事件(event)

对于 DML 语句来讲，只记录已提交的事务

例如: 以下列子，分为4个事件

```
begin;  101-320
DML;    320-630
DML;    630-740
commit; 740-810
```

### event 的组成

三部分构成

1. 事件的开始标识
2. 事件的内容
3. 事件的结束标识

Position

- 开始标记: at 1262
- 结束标记: end_log_pos 1312

作用: 为了方便截取日志

## 查看二进制日志

*查看一共有几个日志文件*

```bash
mysql> show binary logs;
+-----------------+-----------+
| Log_name        | File_size |
+-----------------+-----------+
| mybinlog.000001 |       177 |
| mybinlog.000002 |      1403 |
+-----------------+-----------+
```

*查看当前在用的日志文件*

```bash
mysql> show master status;
+-----------------+----------+--------------+------------------+-------------------+
| File            | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+-----------------+----------+--------------+------------------+-------------------+
| mybinlog.000002 |     1403 |              |                  |                   |
+-----------------+----------+--------------+------------------+-------------------+
```

*查看二进日志事件*

```bash
mysql> show binlog events in 'mybinlog.000002';
+-----------------+------+----------------+-----------+-------------+-----------------------------------------------------------------------------------------------------------------------+
| Log_name        | Pos  | Event_type     | Server_id | End_log_pos | Info                                                                                                                  |
+-----------------+------+----------------+-----------+-------------+-----------------------------------------------------------------------------------------------------------------------+
| mybinlog.000002 |    4 | Format_desc    |         1 |         123 | Server ver: 5.7.28-log, Binlog ver: 4                                                                                 |
| mybinlog.000002 |  123 | Previous_gtids |         1 |         154 |                                                                                                                       |
| mybinlog.000002 |  154 | Anonymous_Gtid |         1 |         219 | SET @@SESSION.GTID_NEXT= 'ANONYMOUS'                                                                                  |
| mybinlog.000002 |  219 | Query          |         1 |         407 | CREATE USER 'repl'@'10.10.1.%' IDENTIFIED WITH 'mysql_native_password' AS '*6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9' |
| mybinlog.000002 |  407 | Anonymous_Gtid |         1 |         472 | SET @@SESSION.GTID_NEXT= 'ANONYMOUS'
```

*导出查看二进制日志*

```bash
root@db1:~# mysqlbinlog /data/mysql/3306/mybinlog.000002 > /tmp/2.sql
# 或者， --base64-outpu=decode-rows 解码日志信息 
root@db1:~# mysqlbinlog --base64-outpu=decode-rows /data/mysql/3306/mybinlog.000002 > /tmp/2.sql
```

*通过 position 号截取日志*

```bash
root@db1:~# mysqlbinlog --start-position=219  --stop-position=1403 /data/mysql/3306/mybinlog.000002 > /tmp/r.sql
```

## 日志管理

### 日志滚动

1. 每次重启 MySQL 时 BINLOG 日志会自动滚动生成并使用新的日志文件
2. bin-log 文件大小达到参数 max_binlog_size 限制；
3. 手动滚动更新 

```bash
mysql> flush logs;
root@db1:~# mysqladmin flush-logs
```

> mysqldump 的 `-F` 参数也会触发自动滚动更新 BINLOG 日志文件，不建议使用

## 日志清理

### 自动清理方法1：（修改配置文件和在mysql内设置参数可无需重启服务）

```bash
root@db1:~# vim /etc/my.cnf
[mysqld]
expire_logs_days = 7 // 表示日志保留7天，超过7天则设置为过期的, 默认为 0 永不过期

root@db1:~# mysql -u root -p
mysql> show binary logs; 
mysql> show variables like '%log%';
mysql> set global expire_logs_days = 7;
```

> `expire_logs_days` 一般设置为一个全备周期 + 1，如果全备周期为7天，就设置为 7+1=8 <br/>
> 一般生产中至少保留2个全备周期

### 手动清理方法2：

如果没有主从复制，可以通过下面的命令重置数据库日志，清除之前所有的日志文件：

```bash
mysql> reset master
```

> 注: 此操作危险，请谨慎操作！！！

但是如果存在复制关系，应当通过 PURGE 的名来清理 bin-log 日志，语法如下：

```bash
# mysql -u root -p
mysql> purge master logs to 'mysql-bin.010’; //清除 mysql-bin.010 之前所有的日志
mysql> purge master logs before '2016-02-28 13:00:00'; //清除2016-02-28 13:00:00前的日志
mysql> purge master logs before date_sub(now(), interval 3 day); //清除3天前的bin日志
```

> 注意，不要轻易手动去删除 binlog，会导致 `binlog.index` 和真实存在的 `binlog` 不匹配，而导致 `expire_logs_day` 失效
