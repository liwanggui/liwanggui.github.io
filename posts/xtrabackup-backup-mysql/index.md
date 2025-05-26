# Xtrabackup 备份 MySQL (全备)


`percona-xtrabackup` 是物理备份工具，拷贝数据文件。

原生态支持全备和增量备份。

会记录二进制日志文件及位置。

- InnoDB 表: 热备份，业务正常发生时，影响较小的备份方式
- 非 InnoDB 表: 温备份，会锁表

## 安装 percona-xtrabackup

下载地址: [https://www.percona.com/downloads/Percona-XtraBackup-2.4/LATEST/](https://www.percona.com/downloads/Percona-XtraBackup-2.4/LATEST/)

## xtrabackup 使用

使用 xtrabackup 命令前提条件

1. 数据库必须启动
2. 能连接上数据库，指定用户名，密码，socket
3. 配置文件 my.cnf 中必须配置 datadir 参数

*配置 my.cnf*

```ini
[client]
# 配置客户端工具连接 socket 文件路径，有此参数 xtrabackup 可以省略 -S 参数
socket = /data/mysql/3306/mysql.sock 

[mysqld]
# 配置数据目录
datadir = /data/mysql/3306
```

### 全量备份

```bash
root@db1:/data/bak# xtrabackup --defaults-file=/usr/local/mysql/etc/my.cnf -u root -p --backup --target-dir=/data/bak/full-$(date +%F)
```

- --defaults-file: 指定 my.cnf 配置文件，此参数必须放在第一位
- -u: 数据库用户名
- -p: 用户密码
- --target-dir: 指定备份存储目录

> 如果 my.cnf 配置文件的 [client] 配置项中没有指定 socket 参数，需要指定 `-S` 指定 mysql.sock 文件路径

### 还原数据

*准备数据*

此步操作主要应用那些还没有应用的事务，该回滚的事务回滚，该提交的事务提交。 该步骤可以使文件在单个时间点上完全一致。

```bash
root@db1:/data/bak# xtrabackup --prepare --target-dir=/data/bak/full-2020-12-25
```

> 注: 准备数据操作过程不能被中断，否则备份将不可用。

*还原数据*

1. 可以直接修改 my.cnf 的 datadir 值，将路径修改为备份路径，然后修改备份目录的权限即可
2. 直接拷贝文件到 MySQL 数据目录中，然后修改数据目录下所有文件的权限即可

> 可以直接使用 `cp` or `rsync` 命令，也可以使用 xtrabackup 命令。

```bash
root@db1:/data/bak# xtrabackup --defaults-file=/usr/local/mysql/etc/my.cnf --copy-back --target-dir=/data/bak/full-2020-12-25
root@db1:/data/bak# chown -R mysql.mysql /data/mysql/3306/
```

**也可以使用如下命令**

- `cp -a /data/bak/full-2020-12-25  /data/mysql/3306`
- `rsync -avrP /data/bak/full-2020-12-25/  /data/mysql/3306/`
