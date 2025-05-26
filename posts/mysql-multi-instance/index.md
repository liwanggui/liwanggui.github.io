# MySQL 多实例安装


当数据库服务器资源有剩余时，为了充分利用剩余资源可以通过部署 MySQL 多实例提升资源利用率，
下面演示如何在一台机上安装 `MySQL` 多实例

## 下载 MySQL 5.7 二进制包

```bash
[root@10-13-90-34 src]# wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz
```

## 解压并建立软链接(/usr/local/mysql)

```bash
[root@10-13-90-34 src]# tar xzf mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz -C /usr/local/
[root@10-13-90-34 local]# ln -s /usr/local/mysql-5.7.28-linux-glibc2.12-x86_64/ /usr/local/mysql
```

## 配置环境变量

```bash
echo 'export PATH=/urs/local/mysql/bin:$PATH' > /etc/profile.d/mysql.sh
source /etc/profile
```

## 准备多实例环境

**创建用户**

```bash
[root@10-13-90-34 mysql]# useradd -r -s /sbin/nologin mysql
```

**创建数据目录**

```bash
[root@10-13-90-34 mysql]# mkdir -p /data/mysql/{3306,3307}
[root@10-13-90-34 mysql]# chown -R mysql.mysql /data/mysql
```

**准备多实例配置文件**

*实例1：3307*

```bash
cat > /usr/local/mysql/etc/my-3307.cnf <<EOF
[client]
port    = 3307
socket    = /data/mysql/3307/mysql.sock

[mysqld]
user    = mysql
port    = 3307
basedir    = /usr/local/mysql
datadir    = /data/mysql/3307
socket    = /data/mysql/3307/mysql.sock
pid-file = mysqldb.pid
character-set-server = utf8mb4
skip_name_resolve = 1
log-error = /data/mysql/3307/error.log

server-id = 1

# binlog 配置
log-bin = /data/mysql/3307/mybinlog
#sync_binlog = 1
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

*实例2：3308*

```bash
cat > /usr/local/mysql/etc/my-3308.cnf <<EOF
[client]
port    = 3308
socket    = /data/mysql/3307/mysql.sock

[mysqld]
user    = mysql
port    = 3308
basedir    = /usr/local/mysql
datadir    = /data/mysql/3308
socket    = /data/mysql/3308/mysql.sock
pid-file = mysqldb.pid
character-set-server = utf8mb4
skip_name_resolve = 1
log-error = /data/mysql/3308/error.log

server-id = 1

# binlog 配置
log-bin = /data/mysql/3308/mybinlog
#sync_binlog = 1
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

## 多实例初始化

```bash
[root@10-13-90-34 3307]# mysqld --defaults-file=/usr/local/mysql/etc/my-3307.cnf --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql/3307

[root@10-13-90-34 3307]# mysqld --defaults-file=/usr/local/mysql/etc/my-3308.cnf --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql/3308
```

> `--defaults-file=` 参数必须放在最前面或者初始化不会成功

## 使用 systemd 管理多实例服务

*3307*

```bash
cat > /usr/lib/systemd/system/mysqld-3307.service << EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/usr/local/mysql/etc/my-3307.cnf
LimitNOFILE = 5000
EOF
```

*3308*

```bash
cat > /usr/lib/systemd/system/mysqld-3308.service << EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/usr/local/mysql/etc/my-3308.cnf
LimitNOFILE = 5000
EOF
```

## 启动 MySQL 多实例

```bash
[root@10-13-90-34 ~]# systemctl start mysqld-3307
[root@10-13-90-34 ~]# systemctl start mysqld-3308
[root@10-13-90-34 ~]# systemctl status mysqld-3307.service
● mysqld-3307.service - MySQL Server
   Loaded: loaded (/usr/lib/systemd/system/mysqld-3307.service; disabled; vendor preset: disabled)
   Active: active (running) since 四 2020-12-24 13:44:18 CST; 14s ago
     Docs: man:mysqld(8)
           http://dev.mysql.com/doc/refman/en/using-systemd.html
 Main PID: 40145 (mysqld)
   CGroup: /system.slice/mysqld-3307.service
           └─40145 /usr/local/mysql/bin/mysqld --defaults-file=/usr/local/mysql/etc/my-3307.cnf

12月 24 13:44:18 10-13-90-34 systemd[1]: Started MySQL Server.
[root@10-13-90-34 ~]# systemctl status mysqld-3308.service
● mysqld-3308.service - MySQL Server
   Loaded: loaded (/usr/lib/systemd/system/mysqld-3308.service; disabled; vendor preset: disabled)
   Active: active (running) since 四 2020-12-24 13:44:20 CST; 16s ago
     Docs: man:mysqld(8)
           http://dev.mysql.com/doc/refman/en/using-systemd.html
 Main PID: 40179 (mysqld)
   CGroup: /system.slice/mysqld-3308.service
           └─40179 /usr/local/mysql/bin/mysqld --defaults-file=/usr/local/mysql/etc/my-3308.cnf

12月 24 13:44:20 10-13-90-34 systemd[1]: Started MySQL Server.
```

## 连接 MySQL 多实例

```bash
[root@10-13-90-34 ~]# mysql -S /data/mysql/3307/mysql.sock
```
