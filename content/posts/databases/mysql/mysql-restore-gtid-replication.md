---
title: MySQL GTID 从库快速恢复
date: "2021-01-13T14:41:02+08:00"
draft: false
categories:
- mysql
tags:
- mysql-replication
- xtrabackup
---

## 备份主库

为了节省恢复的时间我们使用 `xtrabackup` 备份主库，然后拷贝到从库再将数据恢复到从库中

### 完整备份主库

```bash
# 备份
xtrabackup --defaults-file=/usr/local/mysql/etc/my.cnf -S /data/mysql/mysql.sock -u root -p --backup --target-dir=/data/backup
```

## 恢复主从复制

### 恢复从库数据

```bash
# 恢复准备，应用日志
xtrabackup --prepare --target-dir=/data/backup/mysql
# 恢复备份
xtrabackup --defaults-file=/usr/local/mysql/etc/my.cnf --copy-back --target-dir=/data/backup/mysql
# 修改数据目录的权限
chown -R mysql:mysql /data/mysql
# 启动数据库
systemctl start mysqld
```

### 开始恢复主从复制

由于我们使用的是 `xtrabackup` 工具备份恢复的数据，`gtid_purged` 值可以从 `xtrabackup_binlog_info` 文件中获取。

如果是使用是 `mysqldump` 命令备份加上 `--master-data=1` 参数就可以在备份文件中看到 `SET @@GLOBAL.GTID_PURGED='d6f25a03-5d80-11eb-9fe8-000c29738b1d:1-4';` 语句，此时恢复从库数据时就会自动执行 `SET @@GLOBAL.GTID_PURGED='d6f25a03-5d80-11eb-9fe8-000c29738b1d:1-4';` 语句，在恢复主从复制时就不需要在手动执行 `set global gtid_purged=...` 命令啦~

```sql
stop slave;
reset master;
reset slave;
set global gtid_purged='cdb92087-ac64-11e9-bb08-20040ff98044:1-395071';
change master to master_host='10.10.1.11', master_user='repl', master_password='123456',master_port=3306, master_auto_position=1;
start slave;
```

> 注意: 设置 `gtid_purged` 是为了告诉从库与主库进行主从复制时的起始 GITD，
> 如果不加会默认从 gtid 的1号位置点执行，此时就会出现主从复制错误

## 检查，测试 

请自行检测，略...
