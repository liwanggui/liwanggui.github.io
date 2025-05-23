# MySQL 经典主从复制配置


## 安装 MySQL 5.7

*服务器列表*

- master: 10.10.1.2/24
- slave1: 10.10.1.3/24

### 下载 MySQL

```bash
root@db2:/usr/local/src# wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz
root@db1:/usr/local/src# tar xzf mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz -C /usr/local/
root@db1:/usr/local# ln -s /usr/local/mysql-5.7.28-linux-glibc2.12-x86_64/ /usr/local/mysql
```

### 环境准备

```bash
# 安装依赖
root@db1:/usr/local/mysql# apt-get install libaio1
# 创建程序用户
root@db1:/usr/local/mysql# useradd -r -s /sbin/nologin mysql
# 创建数据目录
root@db1:/usr/local/mysql# mkdir -p /data/mysql/3306
# 更改数据目录权限
root@db1:/usr/local/mysql# chown -R mysql.mysql /data/mysql/3306/
# 配置环境变量
root@db1:/usr/local/mysql# echo 'export PATH=/usr/local/mysql/bin:$PATH' > /etc/profile.d/mysql.sh
root@db1:/usr/local/mysql# source /etc/profile
```

### 初始化数据库

*准备 my.cnf 配置文件*

```bash
root@db1:/usr/local/mysql# mkdir etc
root@db1:/usr/local/mysql# cat > etc/my.cnf << EOF
[client]
port = 3306
socket = /data/mysql/3306/mysql.sock

[mysqld]
user = mysql
port = 3306
basedir = /usr/local/mysql
datadir = /data/mysql/3306
socket = /data/mysql/3306/mysql.sock
pid-file = mysqldb.pid
character-set-server = utf8mb4
log-error = /data/mysql/3306/error.log
skip_name_resolve = 1

# 不同实例设置不同数字，不能相同
server-id = 1

# BINGLO 配置，主从同步必须启用 BINLOG 日志
log-bin = /data/mysql/3306/mybinlog
binlog_cache_size = 4M
max_binlog_cache_size = 2G
max_binlog_size = 1G
expire_logs_days = 7
binlog_format = row
binlog_checksum = 1
sync_binlog = 1

# 事务模式
transaction_isolation = REPEATABLE-READ

# InnoDB 配置
innodb_buffer_pool_size = 128M
innodb_buffer_pool_instances = 4
innodb_data_file_path = ibdata1:1G:autoextend
innodb_flush_log_at_trx_commit = 0
```

*初始化数据库*

```bash
root@db1:/usr/local/mysql# mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql/3306
```

> 另一台数据库同样的方法安装初始化，就是配置文件 server_id 的值需要修改

## 配置主从同步

### 主库操作

*启用主库的 binlog*

```bash
root@db1:/usr/local/mysql# cat etc/my.cnf
[mysqld]
# 不同实例设置不同数字，不能相同
server-id = 1
# BINGLO 配置，主从同步必须启用 BINLOG 日志
log-bin = /data/mysql/3306/mybinlog
binlog_cache_size = 4M
max_binlog_cache_size = 2G
max_binlog_size = 1G
expire_logs_days = 7
binlog_format = row
binlog_checksum = 1
sync_binlog = 1
```

*创建同步账号*

```bash
mysql> create user 'repl'@'10.10.1.%' identified by '123456';
mysql> grant replication slave on *.* to 'repl'@'10.10.1.%';
mysql> flush privileges;
```

*导出数据用于创建 `slave`*

```bash
root@db1:~# mysqldump -uroot -p -A -R -E -B -x --master-data=2 | gzip > all.sql.gz
```

- -A, –all-databases: 备份所有数据库
- -E, –events: 备份事件
- -B, –databases: 备份的数据库
- -x, –lock-all-tables：锁定所有数据库的所有表
- –master-data=2: 等于2时会将 CHANGE MASTER 命令以注释的方式加入备份文件中

> 将备份文件拷贝到从库还原

### 从库操作

*配置 my.cnf*

> 从库(slave)如果用于备份可以启用 binlog, 如果用于读操作可以不启用, 只配置 server-id 即可.

```
[root@slave1 ~]# cat /usr/local/mysql/etc/my.cnf
[mysqld]
server-id = 2
# binlog 配置
log-bin = /data/mysql/3306/mybinlog
binlog_cache_size = 4M
max_binlog_cache_size = 2G
max_binlog_size = 1G
expire_logs_days = 7
binlog_format = row
binlog_checksum = 1
sync_binlog = 1
```

*从 master 恢复数据*

```bash
root@db2:~# gzip -d all.sql.gz
root@db2:~# mysql -uroot < all.sql
```

*设置主从同步*

```bash
# 从备份文件找到 CHANGE MASTER 命令
root@db2:~# more all.sql
-- CHANGE MASTER TO MASTER_LOG_FILE='mybinlog.000002', MASTER_LOG_POS=763;
# 配置 slave
mysql> CHANGE MASTER TO 
    -> MASTER_HOST='10.10.1.2',
    -> MASTER_PORT=3306,
    -> MASTER_USER='repl',
    -> MASTER_PASSWORD='123456',
    -> MASTER_LOG_FILE='mybinlog.000002',
    -> MASTER_LOG_POS=763;
mysql> start slave;
mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 10.10.1.2
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mybinlog.000002
          Read_Master_Log_Pos: 763
               Relay_Log_File: db2-relay-bin.000002
                Relay_Log_Pos: 319
        Relay_Master_Log_File: mybinlog.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
...
```

> 查看从库 Slave_IO_Running 和 Slave_SQL_Running 两IO线程状态是否为 YES，为 YES 表示主从复制成功

## 测试主从同步

### 在主库查看从库

```bash
mysql> SHOW SLAVE HOSTS;
+-----------+------+------+-----------+--------------------------------------+
| Server_id | Host | Port | Master_id | Slave_UUID                           |
+-----------+------+------+-----------+--------------------------------------+
|         2 |      | 3306 |         1 | 2cc18b4b-4658-11eb-adf4-000c2955408a |
+-----------+------+------+-----------+--------------------------------------+
1 row in set (0.00 sec)

mysql> show processlist;
+----+------+-----------------+------+-------------+------+---------------------------------------------------------------+------------------+
| Id | User | Host            | db   | Command     | Time | State                                                         | Info             |
+----+------+-----------------+------+-------------+------+---------------------------------------------------------------+------------------+
|  5 | root | localhost       | NULL | Query       |    0 | starting                                                      | show processlist |
|  6 | repl | 10.10.1.3:57800 | NULL | Binlog Dump |  215 | Master has sent all binlog to slave; waiting for more updates | NULL             |
+----+------+-----------------+------+-------------+------+---------------------------------------------------------------+------------------+
2 rows in set (0.00 sec)
```

- `SHOW SLAVE HOSTS`: 查看所有从库信息
- `show processlist`: 查看当前所有线程信息， `Binlog Dump` 是主库和从库主从复制专用线程，如果有多个从库会有多个 `Binlog Dump` 线程

### 测试主从复制

在主从库创建 test 库和 test 表，插入一些数据，然后到从库查看数据是否存在

*主库*
```bash
mysql> create database test charset utf8mb4;
Query OK, 1 row affected (0.01 sec)

mysql> use test;
Database changed
mysql> create table test (id int, username varchar(60));
Query OK, 0 rows affected (0.05 sec)

mysql> insert into test values(1,'lisi'), (2, 'zhangshan');
Query OK, 2 rows affected (0.01 sec)
Records: 2  Duplicates: 0  Warnings: 0
```

*从库*

```bash
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| test               |
+--------------------+
5 rows in set (0.00 sec)

mysql> use test;
mysql> select * from test;
+------+-----------+
| id   | username  |
+------+-----------+
|    1 | lisi      |
|    2 | zhangshan |
+------+-----------+
2 rows in set (0.00 sec)
```
