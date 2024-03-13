# MySQL GITD 模式


## GTID 的概述

是对一个已提交事务的编号，并且是全局唯一的编号

1. 全局事物标识：global transaction identifieds。
2. GTID事物是全局唯一性的，且一个事务对应一个GTID。
3. 一个GTID在一个服务器上只执行一次，避免重复执行导致数据混乱或者主从不一致。
4. GTID 用来代替 经典 (classic) 的复制方法，不在使用 binlog + pos 开启复制。而是使用master_auto_postion=1 的方式自动匹配 GTID 断点进行复制。
5. MySQL-5.6.5 开始支持的，MySQL-5.6.10 后开始完善。
6. 在传统的 slave 端，binlog 是不用开启的，但是在 GTID 中，slave 端的 binlog 是必须开启的，目的是记录执行过的GTID（强制）.

## GTID 的组成部分

GTID 由 `server_uuid` 和 `sequence number` 组成，通过 `:` 连接

例如：`7800a22c-95ae-11e4-983d-080027de205a:10`

- server_uuid: 每个mysql实例的唯一ID，由于会传递到 slave，所以也可以理解为源 ID。
- sequence number：在每台MySQL服务器上都是从1开始自增长的序列，一个数值对应一个事务。

## GTID 比传统复制的优势

1. 更简单的实现 failover，不用以前那样在需要找 log_file 和 log_Pos。
2. 更简单的搭建主从复制。
3. 比传统复制更加安全。
4. GTID是连续没有空洞的，因此主从库出现数据冲突时，可以用添加空事物的方式进行跳过。

## GTID 的工作原理

1. master 更新数据时，会在事务前产生 GTID，一同记录到 binlog 日志中。
2. slave 端的 i/o 线程将变更的 binlog，写入到本地的 relay-log 中。
3. sql 线程从 relay-log 中获取 GTID，然后对比 slave 端的 binlog 是否有记录。
4. 如果有记录，说明该 GTID 的事务已经执行，slave 会忽略(幂等性)。
5. 如果没有记录，slave 就会从 relay-log 中执行该 GTID 的事务，并记录到 binlog。
6. 在解析过程中会判断是否有主键，如果没有就用二级索引，如果没有就用全部扫描。

> 要点：
> 1. slave 在接受 master 的 binlog 时，会校验 master 的 GTID 是否已经执行过（一个服务器只能执行一次）。
> 2. 为了保证主从数据的一致性，多线程只能同时执行一个 GTID。
> 3. 由于幂等性特点，开启 GTID 后，MySQL 恢复 binlog 时，重复的 GTID 事务不会执行.
> 所以在导出 binlog 日志时需要加上 `--skip-gtid` 参数，从而让导出 binlog 语句中不保留全局事务标识符；
> 而是让服务器像执行新事务一样执行事务。


## 配置 GITD

启用 GTID 主要配置参数

```bash
root@db1:~# cat /usr/local/mysql/etc/my.cnf
[mysqld]
gtid-mode = on
enforce-gtid-consistency = true
```
