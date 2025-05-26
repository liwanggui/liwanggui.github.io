# MySQL GTID 主从复制配置


## 环境准备

准备两台服务器安装 MySQL 5.7, 参考 [安装 MySQL 5.7](/mysql-install/)

*服务器列表*

- master: 10.10.1.11/24
- slave1: 10.10.1.12/24

## 配置 MySQL

配置基于 GTID 的主从复制需要启动 gtid 和 binlog 功能，具体配置如下

*主库: my.cnf*

```ini
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

# gtid 配置
server_id=11
gtid_mode=on
enforce-gtid-consistency = true
master-info-repository = TABLE
relay-log-info-repository = TABLE
relay_log_recovery = on
sync-master-info = 1

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
```


*从库: my.cnf*

```ini
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

# gtid 配置
server_id=12
gtid_mode=on
enforce-gtid-consistency = true
master-info-repository = TABLE
relay-log-info-repository = TABLE
relay_log_recovery = on
sync-master-info = 1

# binlog 配置
log-bin = /data/mysql/mybinlog
sync_binlog = 1
binlog_cache_size = 4M
max_binlog_cache_size = 2G
max_binlog_size = 1G
expire_logs_days = 7
binlog_format = row
binlog_checksum = 1

## 禁止从库数据写入
read_only = 1

# 事务模式
transaction_isolation = REPEATABLE-READ

# InnoDB 配置
innodb_buffer_pool_size = 128M
innodb_buffer_pool_instances = 4
innodb_data_file_path = ibdata1:1G:autoextend
innodb_flush_log_at_trx_commit = 0
```


## 配置主从同步

### 创建主从同步用户

在主库上操作

```sql
create user 'repl'@'10.10.1.%' identified by '123456';
grant replication slave on *.* to 'repl'@'10.10.1.%';
flush privileges;
```

### 主从数据同步

由于当前 MySQL 环境是全新搭建的，没有任何数据，此步可以忽略。

如果是在已经运行了很久的数据库或者数据库存在数据的情况下，需要对主库进行全备然后恢复到从库，在配置启动主从复制

### 启动主从同步

在从库上执行以下命令

```sql
change master to
master_host='10.10.1.11',
master_user='repl',
master_password='123456',
master_port=3306,
master_auto_position=1;

start slave;
```

> GTID 主从复制只需指定 `master_auto_position=1` 参数即可，相比经典主从复制更简单

### 查看主从同步状态

```bash
mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 10.10.1.11
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mybinlog.000003
          Read_Master_Log_Pos: 763
               Relay_Log_File: db2-relay-bin.000002
                Relay_Log_Pos: 974
        Relay_Master_Log_File: mybinlog.000003
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 763
              Relay_Log_Space: 1179
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 10
                  Master_UUID: d6f25a03-5d80-11eb-9fe8-000c29738b1d
             Master_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set: d6f25a03-5d80-11eb-9fe8-000c29738b1d:1-3
            Executed_Gtid_Set: d6f25a03-5d80-11eb-9fe8-000c29738b1d:1-3
                Auto_Position: 1
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)
```

## 主从同步测试

请自行测试, 略...
