---
title: "MySQL 使用二进制包进行部署"
date: "2020-12-20T14:55:04+08:00"
draft: false
categories:
- mysql
tags:
- mysql
---

## 下载 MySQL 5.7 二进制包

```bash
wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz
```

## 解压并建立软链接(/usr/local/mysql)

```bash
tar xzf mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz -C /usr/local/
ln -s /usr/local/mysql-5.7.28-linux-glibc2.12-x86_64/ /usr/local/mysql
```

## 配置环境变量

```bash
echo 'export PATH=/usr/local/mysql/bin:$PATH' > /etc/profile.d/mysql.sh
source /etc/profile
```

## 初始化前准备工作

```bash
# 安装依赖
yum install libaio
# 创建 mysql 用户
useradd -r -s /sbin/nologin mysql
# 创建数据存储目录
mkdir -p /data/mysql
chown -R mysql.mysql /data/mysql/
# 生成配置文件 my.cnf
cd /usr/local/mysql
mkdir etc
cat >etc/my.cnf<<EOF
[client]
port = 3306
socket = /data/mysql/mysql.sock

[mysqld]
user = mysql
port = 3306
basedir = /usr/local/mysql
datadir = /data/mysql
socket = /data/mysql/mysql.sock
pid-file = mysqldb.pid
character-set-server = utf8mb4
skip_name_resolve = 1
log-error = /data/mysql/error.log

server-id = 1

# binlog 配置
log-bin = /data/mysql/mybinlog
sync_binlog = 1
binlog_cache_size = 4M
max_binlog_cache_size = 2G
max_binlog_size = 1G
expire_logs_days = 7
binlog_format = row
binlog_checksum = 1

# 事务模式
transaction_isolation = REPEATABLE-READ

# InnoDB 配置
innodb_buffer_pool_size = 128M
innodb_buffer_pool_instances = 4
innodb_data_file_path = ibdata1:1G:autoextend
innodb_flush_log_at_trx_commit = 0
EOF
```

## 初始化数据库

**初始化参数**

- `--initialize`   # 初始化时会提供12位的 root 临时密码，使用mysql前必须重置此密码，密码管理使用严格模式。
- `--initialize-insecure`  # 不会为 root 用户生成临时密码

```bash
mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql
```

## 管理 mysql 服务

**使用自带脚本**

MySQL 默认提供服务管理脚本 `support-files/mysql.server` 使用方法

```bash
cp support-files/mysql.server /etc/init.d/mysqld
/etc/init.d/mysqld start
```

**使用 systemd 管理 MySQL 服务**

编写 `/usr/lib/systemd/system/mysqld.service` 文件，内容如下

```bash
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Service]
User=mysql
Group=mysql
Type=simple
EnvironmentFile=-/etc/sysconfig/mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/usr/local/mysql/etc/my.cnf
TimeoutSec=0
PermissionsStartOnly=true
LimitNOFILE=5000
Restart=on-failure
RestartPreventExitStatus=1

PrivateTmp=false

[Install]
WantedBy=multi-user.target
```

> 以上方法二选一即可

## 扩展部署多实例 MySQL

- 方法1: 多份 MySQL 程序，不同的配置文件，不同的数据存储目录
- 方法2: 一份 MySQL 程序，不同的配置文件，不同的数据存储目录 （*推荐*）

**实现方法**

在 MySQL 服务启动命令 `mysqld` 使用参数（--defaults-file）指定默认使用的配置文件(my.cnf)即可实现，数据存储目录在配置文件中配置.

查看 `mysqld` 参数方法: `mysqld --verbose --help`