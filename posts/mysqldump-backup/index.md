# Mysqldump 备份 MySQL


## mysqldump 参数说明

*-A, --all-databases*: 备份所有库

*-B, --databases*: 使用此参数可以同时备份多个库

> 单库备份可以加上 `-B` 参数，这样备份文件中加会加入 `create database ...` 及 `use DATABASE` 语句.

*--master-data=2*: 加入此参数可以记录 binlog 日志文件位置和文件名 (生产中建议加上此参数)

1. 备份时会自动记录 binlog 日志信息在备份文件中，值为2时以注释的形式记录，值为1时以语句形式记录。
2. 会自动锁全表及解锁
3. 加 --single-transaction 参数，可以减少锁表时间

> `--master-data` 在生产中建议使用的值为 `2`

*--single-transaction*

对于 Innodb引擎表备份时，开启一个独立事务，获取一个一致性快照进行备份。

*-R*: 备份存储过程，函数

*-E*: 备份事件

*-triggers*: 备份触发器

*-d, --no-data*: 不备份数据，只备份数据结构

*-n, --no-create-db*: 不生成创建数据库语句

*-t, --no-create-info*:  不生成创建表语句

> mysqldump 可选参数 `--max_allowed_packet=64M`

> 建议使用 mysqldump 命令参数: `mysqldump -uroot -p --master-data=2 --single-transaction --triggers -R -E`


## 数据库备份

### 备份所有库

```bash
[root@localhost ~]# mysqldump -uroot -p --master-data=2 --single-transaction --triggers -R -E -A > all.sql
```

### 只备份所有库的结构

```bash
[root@localhost ~]# mysqldump -uroot -p -A -d > all.sql
```

### 备份单个数据库

```bash
[root@localhost ~]# mysqldump -uroot -p --master-data=2 --single-transaction --triggers -R -E -B DATABASENAME > DATABASENAME.sql
```

### 一次备份多个数据库 (-B, --databases)

```bash
[root@localhost ~]# mysqldump -uroot -p --master-data=2 --single-transaction --triggers -R -E --databases db1 db2 > dbs.sql
```

### 备份数据库中指定的表

```bash
[root@localhost ~]# mysqldump -uroot -p DATABASENAME TABLENAME > DATABASENAME_TABLENAME.sql
```

### 一次备份数据库中指定的多张表

```bash
[root@localhost ~]# mysqldump -uroot -p DATABASENAME t1 t2 > DATABASENAME_ts.sql
```

### 导出函数或者存储过程

```bash
mysqldump -h HOSTNAME -u USERNAME -p PASSWORD -ntd --triggers -R -E DATABASENAME > DATABASENAME.sql
```

- `-ntd` 表示不导出数据及创建库和表的语句；

## 数据库恢复

当我们需要还原数据时可以通过以下命令进行还原

*方法1*

直接还原数据库，如果备份语句中没有禁用记录 binlog 会产生大量无用的 binlog 信息增加还原时长

```bash
[root@localhost ~]# mysql -uroot -p < all.sql
```

*方法2*

先连接上数据库，然后临时禁止记录 binlog 日志，再还原数据库文件，最后在开启 binlog 日志记录功能(断开重连也会恢复)

```bash
[root@localhost ~]# mysql -uroot -p
mysql> set sql_log_bin=0;
mysql> source /data/bak/backup.sql;
mysql> set sql_log_bin=0;
```
