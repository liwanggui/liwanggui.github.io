# MaxScale：实现MySQL读写分离与负载均衡的中间件利器


- 参考资料: [DBAplus 社区](http://dbaplus.cn/news-11-627-1.html)

## 搭建主从集群

参考 [MySQL GTID 主从复制配置](/posts/mysql-gtid-replication)

## 安装 MaxScale

- [MaxScale Github 地址](https://github.com/mariadb-corporation/MaxScale)
- [MaxScale 下载地址](https://downloads.mariadb.com/MaxScale)

```bash
yum install https://downloads.mariadb.com/MaxScale/2.5.6/centos/7/x86_64/maxscale-2.5.6-1.rhel.7.x86_64.rpm
```

## 配置 MaxScale

*在主库创建监控用户，路由用户*

```sql
# 监控账号
create user scalemon@'%' identified by "123456";
grant replication slave, replication client on *.* to scalemon@'%';

# 路由用户
create user maxscale@'%' identified by "123456";
grant select on mysql.* to maxscale@'%';
grant show databases on *.* to maxscale@'%';
```

> 从库会自动同步账号

*开始配置*

由于我们只使用 `Read-Write-Service`，不需要 `Read-Only-Service`，将其注释即可。 `Read-Only-Listener` 也需要同时注释

```bash
[root@db-proxy ~]# cat /etc/maxscale.cnf
# MaxScale documentation:
# https://mariadb.com/kb/en/mariadb-maxscale-24/

# Global parameters
#
# Complete list of configuration options:
# https://mariadb.com/kb/en/mariadb-maxscale-24-mariadb-maxscale-configuration-guide/

[maxscale]
threads=auto
log_info=1
logdir=/tmp/
admin_host=0.0.0.0
admin_secure_gui=false

# Server definitions
#
# Set the address of the server to the network
# address of a MariaDB server.
#

[server1]
type=server
address=10.10.1.11
port=3306
protocol=MariaDBBackend

[server2]
type=server
address=10.10.1.12
port=3306
protocol=MariaDBBackend

[server3]
type=server
address=10.10.1.13
port=3306
protocol=MariaDBBackend

# Monitor for the servers
#
# This will keep MaxScale aware of the state of the servers.
# MariaDB Monitor documentation:
# https://mariadb.com/kb/en/mariadb-maxscale-24-mariadb-monitor/

[MariaDB-Monitor]
type=monitor
module=mariadbmon
servers=server1,server2,server3
user=scalemon
password=123456
monitor_interval=2000

# Service definitions
#
# Service Definition for a read-only service and
# a read/write splitting service.
#

# ReadConnRoute documentation:
# https://mariadb.com/kb/en/mariadb-maxscale-24-readconnroute/

#[Read-Only-Service]
#type=service
#router=readconnroute
#servers=server1,server2,server3
#user=maxscale
#password=123456
#router_options=slave

# ReadWriteSplit documentation:
# https://mariadb.com/kb/en/mariadb-maxscale-24-readwritesplit/

[Read-Write-Service]
type=service
router=readwritesplit
servers=server1,server2,server3
user=maxscale
password=123456

# Listener definitions for the services
#
# These listeners represent the ports the
# services will listen on.
#

#[Read-Only-Listener]
#type=listener
#service=Read-Only-Service
#protocol=MariaDBClient
#port=4008

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port=4006
```

*启动检查状态*

```bash
[root@db-proxy ~]# systemctl start maxscale.service
[root@MHA_Maxscale ~]# netstat -anptl | grep maxscale
[root@db-proxy ~]# ss -anptl | grep maxscale
LISTEN     0      128          *:8989                     *:*                   users:(("maxscale",pid=1498,fd=23))
LISTEN     0      128         :::4006                    :::*                   users:(("maxscale",pid=1498,fd=28))
```

- 4006: 是 MaxScale 实现 MySQL 读写分离时连接使用的端口
- 8989: 是 MaxScale web 管理页面端口

使用 `maxctrl` 命令查看数据库连接状态

```bash
[root@db-proxy ~]# maxctrl list services
┌────────────────────┬────────────────┬─────────────┬───────────────────┬───────────────────────────┐
│ Service            │ Router         │ Connections │ Total Connections │ Servers                   │
├────────────────────┼────────────────┼─────────────┼───────────────────┼───────────────────────────┤
│ Read-Write-Service │ readwritesplit │ 0           │ 0                 │ server1, server3, server2 │
└────────────────────┴────────────────┴─────────────┴───────────────────┴───────────────────────────┘
[root@db-proxy ~]# maxctrl list servers
┌─────────┬────────────┬──────┬─────────────┬─────────────────┬──────┐
│ Server  │ Address    │ Port │ Connections │ State           │ GTID │
├─────────┼────────────┼──────┼─────────────┼─────────────────┼──────┤
│ server2 │ 10.10.1.12 │ 3306 │ 0           │ Slave, Running  │      │
├─────────┼────────────┼──────┼─────────────┼─────────────────┼──────┤
│ server1 │ 10.10.1.11 │ 3306 │ 0           │ Master, Running │      │
├─────────┼────────────┼──────┼─────────────┼─────────────────┼──────┤
│ server3 │ 10.10.1.13 │ 3306 │ 0           │ Slave, Running  │      │
└─────────┴────────────┴──────┴─────────────┴─────────────────┴──────┘
```

> 也可以登录 Web 页面查看，地址: http://maxscale_server_ip:8989, 默认的用户名和密码是 `admin/mariadb`

## 测试读写分离

使用 `mysql` 命令连接 `maxscale` `4006` 端口进行测试，应用端也是使用此地址和端口进行连接数据库

```bash
[root@db-proxy ~]# mysql -h 10.10.1.10 -P 4006 -u lwg -p123456
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 1
Server version: 5.7.28-log MySQL Community Server (GPL)

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> select @@hostname;  # 默认读操作会发送至从库，重复多次执行可以看到两台从库轮询的效果
+------------+
| @@hostname |
+------------+
| db2        |
+------------+
1 row in set (0.01 sec)

MySQL [(none)]> begin; select @@hostname; rollback;  # 使用开启事务方式，模拟写操作，可以看到写操作被发送到主库
Query OK, 0 rows affected (0.01 sec)

+------------+
| @@hostname |
+------------+
| db1        |
+------------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)
```
