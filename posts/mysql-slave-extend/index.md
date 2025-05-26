# MySQL 从库扩展


## 延时从库

应用场景：普通主从正常情况可以应对物理损坏，但无法应用逻辑损坏。例如: drop 和 delete 等操作。
延时从库可以应对这种逻辑损坏场景： 主库做了某项操作后，等多少秒后从库再应用。

> 注: 延时从库延时的是 sql 线程回放 relay 日志的时间，不是与主库传输二进制日志的时间

### 配置延时从库

主要参数:  MASTER_DELAY

```bash
mysql> stop slave;
mysql> CHANGE MASTER TO MASTER_DELAY=10800;
mysql> start slave;
```

### 恢复思路

- 1.先停业务，挂维护页
- 2.停从库 SQL 线程, stop slave sql_thread; 看 relay_log 位置点; stop slave;

这里只是停止 sql 线程，io 线程并没有停，也就是说主库与从库的二进制日志传输是一直存在的。
最后停止从库时注意观察主从复制二进制日志的情况是否一至。

- 3.追加后续缺失的日志到从库。（相当于手工替代 sql 线程工作）

日志文件: relay-log 
日志文件起始位置确认:  
查看命令: `show slave status\G`
也可以通过查看relay-log.info 文件 `cat /data/mysql/3306/relay-log.info`
日志文件终点确认:
查看命令: `show relaylog events in 'db2-relay-bin.000002'`

> 查看 relaylog 日志事件，只需要看 Pos 列； End_log_pos 列是对应主库的 binlog 位置点。

- 4.恢复业务，直接将业务指向从库或者将数据导回到主库

## 过滤复制

### 主库配置

binlog_do_db: 需要记录二进制的库
binlog_ignore_db: 不需要记录二进制的库

```ini
[mysqld]
binlog_do_db=test
```

> 二选一即可

### 从库配置

如果使用 `replicate-ignore-db` 参数设置不同步的库，需要注意: 使用 use 语句选库后执行的操作才会被忽略不同步，如果 sql 直接通过 库名.表名 执行的操作还是会被同步的。

如果希望不管选不选库的操作都会被忽略可以使用 `replicate-wild-ignore-table` 配置项

*库级别*

- replicate_do_db: 需要复制的库名
- replicate_ignore_db: 忽略复制的库名

*表级别*

- replicate_do_table: 需要复制的库中的表
- replicate_ignore_table: 忽略复制的库中的表

*带有模糊匹配的配置项*

- replicate_wild_do_table
- replicate_wild_ignore_table

## 半同步复制

经典主从复制使用的异步复制工作模型，会导致主从数据不一致的情况
MySQL 5.5 版本为了保证主从数据的一致性问题，加入半同步复制的组件(插件)
在主从复制结构中都需要启用半同步复制插件。
半同步复制主要是控制从库io是否将 relay-log 写入磁盘，一旦落盘通过插件返回 ACK 给主库的 ACK_rec， 接收到 ACK 之后，主库的事务才能提交成功。 在默认情况下,如果超过 10s 没有返回 ACK，此次复制行为会切换为异步复制。

> 半同步复制会影响数据库性能，也并不能完全保证主从复制的数据一致性。并不推荐使用

