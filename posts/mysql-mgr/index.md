# 构建 MySQL 8.x MGR 集群



本文以 [`GreatSQL` 数据库](https://greatsql.cn/docs/8032/user-manual/4-install-guide/3-install-with-tarball.html) 为例，介绍构建 MGR 集群配置

## 1. MGR集群规划

本次计划在3台服务器上安装 GreatSQL 数据库并部署 MGR 集群：

| node	|   ip	|  datadir	|  port	| role |
| :---- | :---- | :-------- | :---- | :---- |
| GreatSQL-01	| 10.10.1.24	| /data/GreatSQL/  | 3306  | PRIMARY |
| GreatSQL-02	| 10.10.2.3	    | /data/GreatSQL/  | 3306  | SECONDARY |
| GreatSQL-03	| 10.10.2.4	    | /data/GreatSQL/  | 3306  | SECONDARY |

以下安装配置工作先在三个节点都同样操作一遍。

## 2. 下载安装包

[点击此处](https://gitee.com/GreatSQL/GreatSQL/releases/tag/GreatSQL-8.0.32-24) 下载最新的安装包，下载以下一个就可以：

- GreatSQL-8.0.32-24-Linux-glibc2.28-x86_64.tar.xz

将下载的二进制包放到安装目录下，并解压缩：

```bash
$ cd /usr/local/src
$ curl -o GreatSQL-8.0.32-24-Linux-glibc2.28-x86_64.tar.xz https://product.greatdb.com/GreatSQL-8.0.32-24/GreatSQL-8.0.32-24-Linux-glibc2.28-x86_64.tar.xz
$ tar xf GreatSQL-8.0.32-24-Linux-glibc2.28-x86_64.tar.xz -C /usr/local/
$ cd /usr/local/
$ ln -s GreatSQL-8.0.32-24-Linux-glibc2.28-x86_64 greatsql
```

同时修改设置，将 GreatSQL 加入 PATH 环境变量：

```bash
$ echo 'export PATH=/usr/local/greatsql/bin:$PATH' >> ~/.bash_profile
$ source ~/.bash_profile
```

> 提示： 安装 GreatSQL 需要先安装其他依赖包，可执行下面命令完成： yum install -y pkg-config perl libaio-devel numactl-devel numactl-libs net-tools openssl openssl-devel jemalloc jemalloc-devel perl-Data-Dumper perl-Digest-MD5 更详细的请参考：[安装准备](https://greatsql.cn/docs/8032/user-manual/4-install-guide/1-install-prepare.html)。

## 3. 启动前准备

修改 `/etc/my.cnf` 配置文件

可根据实际情况修改，一般主要涉及数据库文件分区、目录，内存配置等少数几个选项。以下面这份为例：

```ini
[client]
user = root
socket	= /data/GreatSQL/mysql.sock

[mysqld]
user = mysql
port = 3306
#主从复制或MGR集群中，server_id记得要不同
#另外，实例启动时会生成 auto.cnf，里面的 server_uuid 值也要不同
#server_uuid 的值还可以自己手动指定，只要符合uuid的格式标准就可以
server_id = 3306
basedir = /usr/local/greatsql
datadir	= /data/GreatSQL
socket	= /data/GreatSQL/mysql.sock
pid-file = mysql.pid
character-set-server = UTF8MB4
skip_name_resolve = 1

#若你的MySQL数据库主要运行在境外，请务必根据实际情况调整本参数
default_time_zone = "+8:00"

#performance setttings
lock_wait_timeout = 3600
open_files_limit    = 65535
back_log = 1024
max_connections = 512
max_connect_errors = 1000000
table_open_cache = 1024
table_definition_cache = 1024
thread_stack = 512K
sort_buffer_size = 4M
join_buffer_size = 4M
read_buffer_size = 8M
read_rnd_buffer_size = 4M
bulk_insert_buffer_size = 64M
thread_cache_size = 768
interactive_timeout = 600
wait_timeout = 600
tmp_table_size = 32M
max_heap_table_size = 32M
max_allowed_packet = 64M
net_buffer_shrink_interval = 180

#log settings
log_timestamps = SYSTEM
log_error = error.log
log_error_verbosity = 3

log_bin = binlog
binlog_format = ROW
sync_binlog = 1
binlog_cache_size = 4M
max_binlog_cache_size = 2G
max_binlog_size = 1G
# 控制binlog总大小，避免磁盘空间被撑爆
binlog_space_limit = 200G
binlog_rows_query_log_events = 1
binlog_expire_logs_seconds = 604800
# MySQL 8.0.22前，想启用MGR的话，需要设置binlog_checksum=NONE才行
binlog_checksum = CRC32
gtid_mode = ON
enforce_gtid_consistency = TRUE

# myisam settings
key_buffer_size = 32M
myisam_sort_buffer_size = 128M

# replication settings
relay_log_recovery = 1
slave_parallel_type = LOGICAL_CLOCK
# 可以设置为逻辑CPU数量的2倍
slave_parallel_workers = 64
binlog_transaction_dependency_tracking = WRITESET
slave_preserve_commit_order = 1
slave_checkpoint_period = 2

# mgr settings
loose-plugin_load_add = 'mysql_clone.so'
loose-plugin_load_add = 'group_replication.so'
loose-group_replication_group_name = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1"

# MGR本地节点IP:PORT，请自行替换
loose-group_replication_local_address = "10.10.1.24:33061"
report_host = "10.10.1.24"

##### MGR 集群所有节点IP:PORT，请自行替换
## MGR 集群主机白名单配置
loose-group_replication_ip_whitelist = "10.10.1.24,10.10.2.4,10.10.2.3"  # 或者 10.10.0.0/16
## 指定 MGR 集群主机列表
loose-group_replication_group_seeds = "10.10.1.24:33061,10.10.2.4:33061,10.10.2.3:33061"
#### 注意: 由于 mysql8.0 之后加密规则变成 caching_sha2_password，所以使用 MGR 方式复制时，需要打开公钥访问
loose-group_replication_recovery_get_public_key = ON
loose-group_replication_start_on_boot = OFF
loose-group_replication_bootstrap_group = OFF
loose-group_replication_exit_state_action = READ_ONLY
loose-group_replication_flow_control_mode = "DISABLED"
loose-group_replication_single_primary_mode = ON
loose-group_replication_majority_after_mode = ON
loose-group_replication_communication_max_message_size = 10M
loose-group_replication_arbitrator = 0
loose-group_replication_single_primary_fast_mode = 1
loose-group_replication_request_time_threshold = 100
loose-group_replication_primary_election_mode = GTID_FIRST
loose-group_replication_unreachable_majority_timeout = 30
loose-group_replication_member_expel_timeout = 5
loose-group_replication_autorejoin_tries = 288

# innodb settings
innodb_buffer_pool_size = 1G
innodb_buffer_pool_instances = 4
innodb_data_file_path = ibdata1:12M:autoextend
innodb_flush_log_at_trx_commit = 1
innodb_log_buffer_size = 32M
innodb_log_file_size = 2G
innodb_log_files_in_group = 3
innodb_redo_log_capacity = 6G
innodb_max_undo_log_size = 4G
```

新建 mysql 用户

```bash
$ /sbin/groupadd mysql
$ /sbin/useradd -g mysql mysql -d /dev/null -s /sbin/nologin
```

新建数据库主目录，并修改权限模式及属主

```bash
$ mkdir -p /data/GreatSQL
$ chown -R mysql:mysql /data/GreatSQL
$ chmod -R 700 /data/GreatSQL
```

增加 GreatSQL 系统服务

```bash 
$ vim /lib/systemd/system/mysqld.service

[Unit]
Description=GreatSQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
# some limits
# file size
LimitFSIZE=infinity
# cpu time
LimitCPU=infinity
# virtual memory size
LimitAS=infinity
# open files
LimitNOFILE=65535
# processes/threads
LimitNPROC=65535
# locked memory
LimitMEMLOCK=infinity
# total threads (user+kernel)
TasksMax=infinity
TasksAccounting=false

User=mysql
Group=mysql
#如果是GreatSQL 5.7版本，此处需要改成simple模式，否则可能服务启用异常
#如果是GreatSQL 8.0版本则可以使用notify模式
#Type=simple
Type=notify
TimeoutSec=0
PermissionsStartOnly=true
ExecStartPre=/usr/local/greatsql/bin/mysqld_pre_systemd
ExecStart=/usr/local/greatsql/bin/mysqld $MYSQLD_OPTS
EnvironmentFile=-/etc/sysconfig/mysql
LimitNOFILE = 10000
Restart=on-failure
RestartPreventExitStatus=1
Environment=MYSQLD_PARENT_PID=1
PrivateTmp=false
```

执行命令重载 systemd，加入 greatsql 服务，如果没问题就不会报错：

```bash
$ systemctl daemon-reload
```

这就安装成功并将 GreatSQL 添加到系统服务中，后面可以用 systemctl 来管理 GreatSQL 服务。

启动GreatSQL

执行下面的命令启动 GreatSQL 服务

```bash
$ systemctl start mysqld
```

如果是在一个全新环境中首次启动 GreatSQL 数据库，可能会失败，因为在 mysqld_pre_systemd 的初始化处理逻辑中，需要依赖 `/var/lib/mysql-files` 目录保存一个临时文件。
如果首次启动失败，可能会有类似下面的报错提示：

```bash
Nov  7 10:45:04 ruichang-backend-120 systemd[1]: Starting GreatSQL Server...
Nov  7 10:45:04 ruichang-backend-120 mysqld_pre_systemd[3444803]: mktemp: failed to create file via template ‘/var/lib/mysql-files/install-validate-password-plugin.XXXXXX.sql’: No such file or directory
Nov  7 10:45:04 ruichang-backend-120 mysqld_pre_systemd[3444804]: chmod: cannot access '': No such file or directory
Nov  7 10:45:04 ruichang-backend-120 mysqld_pre_systemd[3444801]: /usr/local/greatsql/bin/mysqld_pre_systemd: line 43: : No such file or directory
Nov  7 10:45:04 ruichang-backend-120 mysqld_pre_systemd[3444801]: /usr/local/greatsql/bin/mysqld_pre_systemd: line 44: $initfile: ambiguous redirect
Nov  7 10:45:05 ruichang-backend-120 systemd[1]: mysqld.service: Main process exited, code=exited, status=1/FAILURE
Nov  7 10:45:05 ruichang-backend-120 systemd[1]: mysqld.service: Failed with result 'exit-code'.
Nov  7 10:45:05 ruichang-backend-120 systemd[1]: Failed to start GreatSQL Server.
```

只需手动创建 `/var/lib/mysql-files` 目录，再次启动 GreatSQL 服务即可：

```bash
$ mkdir -p /var/lib/mysql-files && chown -R mysql:mysql /var/lib/mysql-files
$ systemctl start mysqld
```

检查服务是否已启动，以及进程状态：

```bash
$ systemctl status mysqld
● mysqld.service - GreatSQL Server
   Loaded: loaded (/usr/lib/systemd/system/mysqld.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2023-11-07 10:46:06 CST; 7s ago
     Docs: man:mysqld(8)
           http://dev.mysql.com/doc/refman/en/using-systemd.html
  Process: 3444896 ExecStartPre=/usr/local/greatsql/bin/mysqld_pre_systemd (code=exited, status=0/SUCCESS)
 Main PID: 3444986 (mysqld)
   Status: "Server is operational"
   Memory: 621.4M
   CGroup: /system.slice/mysqld.service
           └─3444986 /usr/local/greatsql/bin/mysqld

Nov 07 10:46:00 ruichang-backend-120.79.25.21 systemd[1]: Starting GreatSQL Server...
Nov 07 10:46:06 ruichang-backend-120.79.25.21 systemd[1]: Started GreatSQL Server.

$ ps -ef | grep mysqld
mysql    3444986       1  7 10:46 ?        00:00:05 /usr/local/greatsql/bin/mysqld
root     3445052 3415579  0 10:47 pts/0    00:00:00 grep --color=auto mysqld

$ ss -lntp | grep mysqld
LISTEN 0      70                 *:33060            *:*    users:(("mysqld",pid=3444986,fd=27))
LISTEN 0      128                *:3306             *:*    users:(("mysqld",pid=3444986,fd=31))

$ ls /data/GreatSQL
 auto.cnf        ca-key.pem        error.log           '#ib_16384_3.dblwr'  '#ib_16384_7.dblwr'  '#innodb_redo'   mysql.pid            private_key.pem   sys
 binlog.000001   ca.pem           '#ib_16384_0.dblwr'  '#ib_16384_4.dblwr'   ib_buffer_pool      '#innodb_temp'   mysql.sock           public_key.pem    sys_audit
 binlog.000002   client-cert.pem  '#ib_16384_1.dblwr'  '#ib_16384_5.dblwr'   ibdata1              mysql           mysql.sock.lock      server-cert.pem   undo_001
 binlog.index    client-key.pem   '#ib_16384_2.dblwr'  '#ib_16384_6.dblwr'   ibtmp1               mysql.ibd       performance_schema   server-key.pem    undo_002
```

## 4. 连接登入 GreatSQL

默认初始化密码在日志文件中查找

```bash
$ grep password /data/GreatSQL/error.log
2023-11-07T10:46:02.690847+08:00 0 [Note] [MY-010309] [Server] Auto generated RSA key files through --sha256_password_auto_generate_rsa_keys are placed in data directory.
2023-11-07T10:46:02.690881+08:00 0 [Note] [MY-010308] [Server] Skipping generation of RSA key pair through --caching_sha2_password_auto_generate_rsa_keys as key files are present in data directory.
2023-11-07T10:46:02.711070+08:00 0 [Note] [MY-010137] [Server] Execution of init_file '/var/lib/mysql-files/install-validate-password-plugin.CBx5Ta.sql' started.
2023-11-07T10:46:02.711286+08:00 6 [Note] [MY-010454] [Server] A temporary password is generated for root@localhost: Xd:hM8uq;Xyi  # 这是初始化密码
2023-11-07T10:46:03.728877+08:00 0 [Note] [MY-010138] [Server] Execution of init_file '/var/lib/mysql-files/install-validate-password-plugin.CBx5Ta.sql' ended.
```

登录修改 root 密码

```bash
$ mysql -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 11
Server version: 8.0.32-24

Copyright (c) 2021-2023 GreatDB Software Co., Ltd
Copyright (c) 2009-2023 Percona LLC and/or its affiliates
Copyright (c) 2000, 2023, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> set password='Test@123456';
Query OK, 0 rows affected (0.01 sec)
```

## 5. 安装 MySQL Shell

为了支持仲裁节点特性，需要安装 GreatSQL 提供的 MySQL Shell发行包。打开 GreatSQL [下载页面](https://gitee.com/GreatSQL/GreatSQL/releases/GreatSQL-8.0.32-24)，找到 7. GreateSQL MySQL Shell，下载相应的 MySQL Shell 安装包（目前只提供二进制安装包）。

> P.S，如果暂时不想使用仲裁节点特性的话，则可以继续使用相同版本的官方MySQL Shell安装包，可以直接用YUM方式安装，此处略过。

本文场景中，选择下面的二进制包：

- greatsql-shell-8.0.25-16-Linux-glibc2.28-x86_64.tar.xz

将二进制文件包放在 `/usr/local` 目录下，解压缩：

```bash
cd /usr/local/src
wget https://product.greatdb.com/GreatSQL-8.0.25-16/greatsql-shell-8.0.25-16-Linux-glibc2.28-x86_64.tar.xz
tar xf greatsql-shell-8.0.25-16-Linux-glibc2.28-x86_64.tar.xz -C /usr/local
cd .. && ln -s greatsql-shell-8.0.25-16-Linux-glibc2.28-x86_64 greatsql-shell
```

直接运行 `/usr/local/greatsql-shell-8.0.25-16-Linux-glibc2.28-x86_64/bin/mysqlsh` 会报如下错误

```bash
./bin/mysqlsh: error while loading shared libraries: libpython3.8.so.1.0: cannot open shared object file: No such file or directory
```

这是因为依赖于 python3.8 , 安装 python3.8 后 MySQL Shell 就可以正常使用

```bash
yum install -y python38
```

## 6. 利用 MySQL Shell 构建 MGR 集群

利用 MySQL Shell for GreatSQL 构建 MGR 集群比较简单，主要有几个步骤：

1. 检查实例是否满足条件。
2. 创建并初始化一个集群。
3. 逐个添加实例。

首先，用管理员账号 root 连接到第一个节点：

```bash
# ./bin/mysqlsh -S /data/GreatSQL/mysql.sock root@localhost
Please provide the password for 'root@/data%2FGreatSQL%2Fmysql.sock': ***********
MySQL Shell 8.0.25

Copyright (c) 2016, 2021, Oracle and/or its affiliates.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
Creating a session to 'root@/data%2FGreatSQL%2Fmysql.sock'
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 13
Server version: 8.0.32-24 GreatSQL, Release 24, Revision 3714067bc8c
No default schema selected; type \use <schema> to set one.
WARNING: Found errors loading plugins, for more details look at the log at: /root/.mysqlsh/mysqlsh.log
```

 执行命令 `\status` 查看当前节点的状态，确认连接正常可用。

```bash
 MySQL  localhost  Py > \status  
MySQL Shell version 8.0.25

Connection Id:                13
Current schema:
Current user:                 root@localhost
SSL:                          Not in use.
Using delimiter:              ;
Server version:               8.0.32-24 GreatSQL, Release 24, Revision 3714067bc8c
Protocol version:             Classic 10
Client library:               8.0.25
Connection:                   Localhost via UNIX socket
Unix socket:                  /data/GreatSQL/mysql.sock
Server characterset:          utf8mb4
Schema characterset:          utf8mb4
Client characterset:          utf8mb4
Conn. characterset:           utf8mb4
Result characterset:          utf8mb4
Compression:                  Disabled
Uptime:                       31 min 39.0000 sec

Threads: 4  Questions: 13  Slow queries: 0  Opens: 148  Flush tables: 3  Open tables: 64  Queries per second avg: 0.006
```

执行 `dba.configure_instance()` 命令开始检查当前实例是否满足安装MGR集群的条件，如果满足可以直接配置成为MGR集群的一个节点， 创建 MGR 集群用户: `mgr` 密码: `Test@123456`

```bash
 MySQL  localhost  Py > dba.configure_instance()
Configuring local MySQL instance listening at port 3306 for use in an InnoDB cluster...

This instance reports its own address as 10.10.1.24:3306

ERROR: User 'root' can only connect from 'localhost'. New account(s) with proper source address specification to allow remote connection from all instances must be created to manage the cluster.

1) Create remotely usable account for 'root' with same grants and password
2) Create a new admin account for InnoDB cluster with minimal required grants
3) Ignore and continue
4) Cancel

Please select an option [1]: 2   # 选择第二项，创建一个新管理账号用于 mgr 集群配置
Please provide an account name (e.g: icroot@%) to have it created with the necessary
privileges or leave empty and press Enter to cancel.
Account Name: mgr
Password for new account: **********
Confirm password: **********

applierWorkerThreads will be set to the default value of 4.

The instance '10.10.1.24:3306' is valid to be used in an InnoDB cluster.

Cluster admin user 'mgr'@'%' created.
The instance '10.10.1.24:3306' is already ready to be used in an InnoDB cluster.

WARNING: '@@slave_parallel_workers' is deprecated and will be removed in a future release. Please use replica_parallel_workers instead. (Code 1287).

Successfully enabled parallel appliers.
```

完成检查并创建完新用户后，退出当前的管理员账户，并用新创建的MGR专用账户登入，准备初始化创建一个新集群：

```bash
$ ./bin/mysqlsh -S /data/GreatSQL/mysql.sock mgr@localhost

Please provide the password for 'mgr@/data%2FGreatSQL%2Fmysql.sock': **********
MySQL Shell 8.0.25

Copyright (c) 2016, 2021, Oracle and/or its affiliates.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
Creating a session to 'mgr@/data%2FGreatSQL%2Fmysql.sock'
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 16
Server version: 8.0.32-24 GreatSQL, Release 24, Revision 3714067bc8c
No default schema selected; type \use <schema> to set one.
WARNING: Found errors loading plugins, for more details look at the log at: /root/.mysqlsh/mysqlsh.log

# 定义一个变量名c，方便下面引用
 MySQL  localhost  Py > c = dba.create_cluster('MGR1');
A new InnoDB cluster will be created on instance '/data%2FGreatSQL%2Fmysql.sock'.

Validating instance configuration at /data%2FGreatSQL%2Fmysql.sock...

This instance reports its own address as 10.10.1.24:3306

Instance configuration is suitable.
NOTE: Group Replication will communicate with other members using '10.10.1.24:33061'. Use the localAddress option to override.

Creating InnoDB cluster 'MGR1' on '10.10.1.24:3306'...

Adding Seed Instance...
Cluster successfully created. Use Cluster.add_instance() to add MySQL instances.
At least 3 instances are needed for the cluster to be able to withstand up to
one server failure.
```

接下来，用同样方法先用 root 账号分别登入到另外两个节点，完成节点的检查并创建最小权限级别用户（此过程略过。。。注意各节点上创建的用户名、密码都要一致）

用户创建完成后再回到第一个节点，执行 `add_instance()` 添加另外两个节点

> 提示： 如需要添加仲裁节点，需在实例配置中设置 `group_replication_arbitrator = 1` 配置项

添加 `mgr@10.10.2.4:3306` 实例

```bash
 MySQL  localhost  Py > c.add_instance('mgr@10.10.2.4:3306')

WARNING: A GTID set check of the MySQL instance at '10.10.2.4:3306' determined that it contains transactions that do not originate from the cluster, which must be discarded before it can join thecluster.

10.10.2.4:3306 has the following errant GTIDs that do not exist in the cluster:
0e65280a-7d37-11ee-9e36-00163e0aafd0:1

WARNING: Discarding these extra GTID events can either be done manually or by completely overwriting the state of 10.10.2.4:3306 with a physical snapshot from an existing cluster member. To use this method by default, set the 'recoveryMethod' option to 'clone'.

Having extra GTID events is not expected, and it is recommended to investigate this further and ensure that the data can be removed prior to choosing the clone recovery method.

Please select a recovery method [C]lone/[A]bort (default Abort): c
Validating instance configuration at 10.10.2.4:3306...

This instance reports its own address as 10.10.2.4:3306

Instance configuration is suitable.
NOTE: Group Replication will communicate with other members using '10.10.2.4:33061'. Use the localAddress option to override.

A new instance will be added to the InnoDB cluster. Depending on the amount of
data on the cluster this might take from a few seconds to several hours.

Adding instance to the cluster...

Monitoring recovery process of the new cluster member. Press ^C to stop monitoring and let it continue in background.
Clone based state recovery is now in progress.

NOTE: A server restart is expected to happen as part of the clone process. If the
server does not support the RESTART command or does not come back after a
while, you may need to manually start it back.

* Waiting for clone to finish...
NOTE: 10.10.2.4:3306 is being cloned from 10.10.1.24:3306
** Stage DROP DATA: Completed
** Clone Transfer
    FILE COPY  ############################################################  100%  Completed
    PAGE COPY  ############################################################  100%  Completed
    REDO COPY  ############################################################  100%  Completed

NOTE: 10.10.2.4:3306 is shutting down...

* Waiting for server restart... ready
* 10.10.2.4:3306 has restarted, waiting for clone to finish...
** Stage RESTART: Completed
* Clone process has finished: 73.36 MB transferred in about 1 second (~73.36 MB/s)

State recovery already finished for '10.10.2.4:3306'

The instance '10.10.2.4:3306' was successfully added to the cluster.
```

添加 `mgr@10.10.2.3:3306` 实例


```bash
 MySQL  localhost  Py > c.add_instance('mgr@10.10.2.3:3306')

WARNING: A GTID set check of the MySQL instance at '10.10.2.3:3306' determined that it contains transactions that do not originate from the cluster, which must be discarded before it can join thecluster.

10.10.2.3:3306 has the following errant GTIDs that do not exist in the cluster:
0fa623f1-7d37-11ee-80c4-00163e0656c4:1

WARNING: Discarding these extra GTID events can either be done manually or by completely overwriting the state of 10.10.2.3:3306 with a physical snapshot from an existing cluster member. To use this method by default, set the 'recoveryMethod' option to 'clone'.

Having extra GTID events is not expected, and it is recommended to investigate this further and ensure that the data can be removed prior to choosing the clone recovery method.

Please select a recovery method [C]lone/[A]bort (default Abort): c
Validating instance configuration at 10.10.2.3:3306...

This instance reports its own address as 10.10.2.3:3306

Instance configuration is suitable.
NOTE: Group Replication will communicate with other members using '10.10.2.3:33061'. Use the localAddress option to override.

A new instance will be added to the InnoDB cluster. Depending on the amount of
data on the cluster this might take from a few seconds to several hours.

Adding instance to the cluster...

Monitoring recovery process of the new cluster member. Press ^C to stop monitoring and let it continue in background.
Clone based state recovery is now in progress.

NOTE: A server restart is expected to happen as part of the clone process. If the
server does not support the RESTART command or does not come back after a
while, you may need to manually start it back.

* Waiting for clone to finish...
NOTE: 10.10.2.3:3306 is being cloned from 10.10.1.24:3306
** Stage DROP DATA: Completed
** Clone Transfer
    FILE COPY  ############################################################  100%  Completed
    PAGE COPY  ############################################################  100%  Completed
    REDO COPY  ############################################################  100%  Completed

NOTE: 10.10.2.3:3306 is shutting down...

* Waiting for server restart... ready
* 10.10.2.3:3306 has restarted, waiting for clone to finish...
** Stage RESTART: Completed
* Clone process has finished: 73.36 MB transferred in about 1 second (~73.36 MB/s)

State recovery already finished for '10.10.2.3:3306'

The instance '10.10.2.3:3306' was successfully added to the cluster.
```

使用 `select * from performance_schema.replication_group_members` 语句，查看 MGR 集群实例状态

```bash
$ mysql -p
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 48
Server version: 8.0.32-24 GreatSQL, Release 24, Revision 3714067bc8c

Copyright (c) 2021-2023 GreatDB Software Co., Ltd
Copyright (c) 2009-2023 Percona LLC and/or its affiliates
Copyright (c) 2000, 2023, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+----------------------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION | MEMBER_COMMUNICATION_STACK |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+----------------------------+
| group_replication_applier | 0cfacce0-7d37-11ee-a432-00163e02e944 | 10.10.1.24  |        3306 | ONLINE       | PRIMARY     | 8.0.32         | XCom                       |
| group_replication_applier | 0e65280a-7d37-11ee-9e36-00163e0aafd0 | 10.10.2.4   |        3306 | ONLINE       | SECONDARY   | 8.0.32         | XCom                       |
| group_replication_applier | 0fa623f1-7d37-11ee-80c4-00163e0656c4 | 10.10.2.3   |        3306 | ONLINE       | SECONDARY   | 8.0.32         | XCom                       |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+----------------------------+
3 rows in set (0.00 sec)

```

> 提示: 可以使用 `MySQL Router` 实现读写分离、读负载均衡，以及故障自动转移， 参考： https://greatsql.cn/docs/8032/user-manual/8-mgr/5-mgr-readwrite-split.html

## 7. 部署 MGR 集群配置项

### group_replication_start_on_boot 

初始配置 MGR 集群时 `group_replication_start_on_boot` 值，需要配置为 `OFF`

### group_replication_bootstrap_group

MGR 集群启动时需要一个引导节点，第一个节点先配置 `group_replication_bootstrap_group = ON`，第一个节点启动完毕后，记得重置选项 `group_replication_bootstrap_group=OFF`，避免在后续的操作中导致MGR集群分裂。

### group_replication_recovery_get_public_key

错误信息如下：

```
Authentication plugin 'caching_sha2_password' reported error: Authentication requires secure connection. Error_code: MY-002061
```

这是由于 `mysql8.0` 之后加密规则变成 `caching_sha2_password`，所以使用 MGR 方式复制时，需要打开公钥访问

添加 `group_replication_recovery_get_public_key = ON` 配置项即可解决

在从节点上执行下面命令，为了重启后还有效需要写入配置中文件中 (`my.cnf`)

```bash
mysql> STOP GROUP_REPLICATION;
mysql> SET GLOBAL group_replication_recovery_get_public_key=ON;
mysql> START GROUP_REPLICATION;
```

除了以上的方法，也可以将 MGR 集群用户密码加密插件改为: `mysql_native_password`

```sql
set session sql_log_bin=0;
alter user repl@'%' IDENTIFIED WITH mysql_native_password by 'repl';
set session sql_log_bin=1;
```

对于新创建的用户,执行以下命令

```sql
create user repl@'%' IDENTIFIED WITH mysql_native_password by 'repl';
```

### group_replication_ip_whitelist

组复制的 IP 白名单，如果 MGR 节点不在同一个子网段下需要显式指定 MGR 组内成员地址，例如:

```bash
group_replication_ip_whitelist = "10.10.1.24,10.10.2.4,10.10.2.3" # or 10.10.0.0/16
```

### 重启 MGR 集群

正常情况下，MGR 集群中的 `Primary` 节点退出时，剩下的节点会自动选出新的 `Primary` 节点。
当最后一个节点也退出时，相当于整个MGR集群都关闭了。
这时候任何一个节点启动MGR服务后，都不会自动成为 `Primary` 节点，需要在启动MGR服务前，先设置 `group_replication_bootstrap_group=ON`，使其成为引导节点，再启动 MGR 服务，它才会成为 `Primary` 节点，后续启动的其他节点也才能正常加入集群。
可自行测试，这里不再做演示。

> P.S，第一个节点启动完毕后，记得重置选项 `group_replication_bootstrap_group=OFF`，避免在后续的操作中导致 MGR 集群分裂。

如果是用 `MySQL Shell for GreatSQL` 重启 MGR 集群，调用 json: `rebootClusterFromCompleteOutage()` , python `reboot_cluster_from_complete_outage()` 函数即可，它会自动判断各节点的状态，选择其中一个作为 `Primary` 节点，然后拉起各节点上的 MGR 服务，完成MGR集群重启。

可以参考这篇文章：[万答#12，MGR 整个集群挂掉后，如何才能自动选主，不用手动干预](https://mp.weixin.qq.com/s/07o1poO44zwQIvaJNKEoPA)

**使用 `MySQL Shell for GreatSQL` 重启(启动) MGR 集群**

当 MGR 集群挂掉后，先启动 greatsql 实例，然后再使用 `MySQL Shell for GreatSQL` 恢复 MGR 集群

```bash
# 连接其中一个节点
/usr/local/mysqlsh/bin/mysqlsh --uri mgr@10.10.1.24
# 执行：dba.reboot_cluster_from_complete_outage() 恢复 MGR 集群
MySQL localhost  Py > dba.reboot_cluster_from_complete_outage()
Restoring the default cluster from complete outage...

The instance '10.10.2.4:3306' was part of the cluster configuration.
Would you like to rejoin it to the cluster? [y/N]: y

The instance '10.10.2.3:3306' was part of the cluster configuration.
Would you like to rejoin it to the cluster? [y/N]: y

Traceback (most recent call last):
  File "<string>", line 1, in <module>

# 错误信息提示我们当前节点上没有最新的数据，不能直接启动 MGR，错误信息中还提供了该去哪个节点启动的建议，所以我们改成在 10.10.2.3:3306 节点上执行拉起 MGR：
RuntimeError: Dba.reboot_cluster_from_complete_outage: The active session instance (10.10.1.24:3306) isn't the most updated in comparison with the ONLINE instances of the Cluster's metadata. Please use the most up to date instance: '10.10.2.3:3306'.

# 连接 10.10.2.3:3306 节点
/usr/local/mysqlsh/bin/mysqlsh --uri mgr@10.10.2.3

MySQL localhost  Py > dba.reboot_cluster_from_complete_outage()
Restoring the default cluster from complete outage...

The instance '10.10.1.24:3306' was part of the cluster configuration.
Would you like to rejoin it to the cluster? [y/N]: y

The instance '10.10.2.4:3306' was part of the cluster configuration.
Would you like to rejoin it to the cluster? [y/N]: y

10.10.2.3:3306 was restored.
Rejoining '10.10.1.24:3306' to the cluster.
Rejoining instance '10.10.1.24:3306' to cluster 'MGR1'...
The instance '10.10.1.24:3306' was successfully rejoined to the cluster.

Rejoining '10.10.2.4:3306' to the cluster.
Rejoining instance '10.10.2.4:3306' to cluster 'MGR1'...
The instance '10.10.2.4:3306' was successfully rejoined to the cluster.

The cluster was successfully rebooted.

<Cluster:MGR1>
```

可以看到，MGR 集群已经被正常启动了


