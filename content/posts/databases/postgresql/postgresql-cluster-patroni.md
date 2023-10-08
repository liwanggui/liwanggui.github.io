---
title: "PostgreSQL 高可用集群之 patroni"
date: 2023-10-08T16:44:39+08:00
draft: false
categories: 
- postgresql
tags:
- postgresql
- patroni
---

*服务器列表*

| 节点名	| IP	         | 操作系统	      | 安装软件	                                | 备注 |
| :---     | :---           | :---          | :---                                      | :--- |
| pg1  | 192.168.142.11 | uos server 20	| PostgreSQL 13.3/patroni 3.1.2/etcd 3.5.4	| 初始主节点 |
| pg2  | 192.168.142.12 | uos server 20	| PostgreSQL 13.3/patroni 3.1.2/etcd 3.5.4	| 初始备节点 |
| pg3  | 192.168.142.13 | uos server 20	| PostgreSQL 13.3/patroni 3.1.2/etcd 3.5.4	| 初始备节点 |

> VIP: 192.168.142.10

## 安装 postgresql 

由于 `uos server 20` 仓库源中的 `postgresql` 版本过低，这里通过源码编译安装 `postgresql`, 编译安装过程如下

```bash
yum install -qy gcc gcc-c++ make readline-devel zlib-devel

cd /usr/local/src
wget https://ftp.postgresql.org/pub/source/v13.3/postgresql-13.3.tar.gz
tar xzf postgresql-13.3.tar.gz
cd postgresql-13.3

./configure --prefix=/usr/local/pg13
make -j`nproc`
make install

cd contrib/
make install

echo '/usr/local/pg13/lib' > /etc/ld.so.conf.d/postgresql.conf
ldconfig

echo 'export PATH=/usr/local/pg13/bin:$PATH' > /etc/profile.d/postgresql.sh
source /etc/profile

# 创建 postgres 用户
useradd -r -d /var/lib/pg13 -m postgres
echo 'postgres  ALL=(ALL)  NOPASSWD: ALL' > /etc/sudoers.d/postgres
```

## 部署 etcd 

*安装配置 etcd*

```bash
yum install -y etcd

# 配置 etcd
cat /etc/etcd/etcd.conf | grep -v ^#
ETCD_NAME=e1
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://192.168.142.11:2380"
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://192.168.142.11:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.142.11:2380"
ETCD_INITIAL_CLUSTER="e1=http://192.168.142.11:2380,e2=http://192.168.142.12:2380,e3=http://192.168.142.13:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://localhost:2379,http://192.168.142.11:2379"
```

> 注意: 在另外两台主机进行相同操作时，注意配置项 IP 地址的不同

*启动 etcd*

```bash
systemctl enable --now etcd
```

> 提示: 关于 etcd 集群详细信息参考 [部署 etcd 集群](/posts/etcd-cluster/)

## 部署 patroni

*配置 pip 加速*

```bash
mkdir ~/.pip

cat >~/.pip/pip.conf<<EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
EOF
```

*安装 patroni*

```bash
yum install -y python36-devel

pip3 install psycopg2-binary
pip3 install patroni[etcd]
```

> 详细安装信息参考: https://patroni.readthedocs.io/en/latest/README.html

*安装 watchdog, patroni 使用 watchdog 为防止出现脑裂, **可选***

```bash
yum install -y watchdog

# 初始化 watchdog 字符设备
modprobe softdog

# 启动 watchdog 服务
systemctl start watchdog
systemctl enable watchdog
```

*配置 patroni, 创建 `/etc/patroni` 目录，编辑 `/etc/patroni/patroni.yml` 配置文件*

```yaml
scope: pgcluster
namespace: /service/
name: pg1

restapi:
  listen: 0.0.0.0:8008
  connect_address: 192.168.142.11:8008

etcd3:
  hosts: 192.168.142.11:2379,192.168.142.12:2379,192.168.142.13:2379

log:
  dir: /etc/patroni
  file_size: 50000000
  file_num: 10
  dateformat: '%Y-%m-%d %H:%M:%S'
  loggers:
    patroni.postmaster: WARNING

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    primary_start_timeout: 300
    synchronous_mode: true
    postgresql:
      use_pg_rewind: true
      use_slots: true
      pg_hba:
      - local all all trust
      - local replication all trust
      - host all all 127.0.0.1/32 trust
      - host all all ::1/128 trust
      - host all all 0.0.0.0/0 scram-sha-256
      - host replication all 127.0.0.1/32 trust
      - host replication all ::1/128 trust
      - host replication replicator 192.168.142.0/24 scram-sha-256
      parameters:
        wal_level: logical
        log_directory: "pg_log"
        log_destination: "csvlog"
        hot_standby: "on"
        wal_keep_segments: 1000
        max_connections: 1000
        max_wal_senders: 10
        max_replication_slots: 10
        wal_log_hints: "on"

  initdb:  # Note: It needs to be a list (some options need values, others are switches)
  - encoding: UTF8
  - locale: C
  - lc-ctype: zh_CN.UTF-8
  - data-checksums

  users:
    admin:
      password: admin%123
      options:
        - createrole
        - createdb

postgresql:
  listen: 0.0.0.0:5432
  connect_address: 192.168.142.11:5432
  data_dir: /var/lib/pg13/data
  bin_dir: /usr/local/pg13/bin
  pgpass: /var/lib/pg13/.pgpass
  authentication:
    replication:
      username: replicator
      password: repl@123
    superuser:
      username: postgres
      password: 123456
    rewind:  # Has no effect on postgres 10 and lower
      username: postgres
      password: 123456

  callbacks:
    on_start: /bin/bash /etc/patroni/loadvip.sh
    on_stop: /bin/bash /etc/patroni/loadvip.sh
    on_restart: /bin/bash /etc/patroni/loadvip.sh
    on_role_change: /bin/bash /etc/patroni/loadvip.sh

watchdog:
  mode: automatic # Allowed values: off, automatic, required
  device: /dev/watchdog
  safety_margin: 5

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
```

**另外两台服务器配置项修改点**

```yaml
name: pg1  # 不同节点的名称，需要不一样

restapi:
  connect_address: 192.168.142.11:8008 # 修改 IP 地址

postgresql:
  connect_address: 192.168.142.11:5432  # 修改 IP 地址
```

> 注意: `/etc/patroni` 目录权限需要赋于 `postgres` 用户，`patroni` 服务日志写在此目录下


*创建 `patroni_callback` 脚本 `/etc/patroni/loadvip.sh`, 通过 `patroni_callback` 实现 `postgresql` 集群高可用*

```bash
#!/bin/bash

VIP=192.168.142.10
GATEWAY=192.168.142.2
DEV=ens33

action=$1
role=$2
cluster=$3

log() {
  echo "loadvip: $*" | logger
}

load_vip() {
    ip address show ${DEV}| grep -w ${VIP} >/dev/null

    if [ $? -eq 0 ] ; then
        log "vip exists, skip load vip"
    else
        sudo ip addr add ${VIP}/32 dev ${DEV} >/dev/null
        rc=$?
        if [ $rc -ne 0 ] ;then
            log "fail to add vip ${VIP} at dev ${DEV} rc=$rc"
            exit 1
        fi

        log "added vip ${VIP} at dev ${DEV}"

        arping -U -I ${DEV} -s ${VIP} ${GATEWAY} -c 5 >/dev/null
        rc=$?

        if [ $rc -ne 0 ] ;then
            log "fail to call arping to gateway ${GATEWAY} rc=$rc"
            exit 1
        fi

        log "called arping to gateway ${GATEWAY}"
    fi
}

unload_vip() {
    ip address show ${DEV} | grep -w ${VIP} >/dev/null

    if [ $? -eq 0 ] ;then
        sudo ip addr del ${VIP}/32 dev ${DEV} >/dev/null
        rc=$?
        
        if [ $rc -ne 0 ] ;then
            log "fail to delete vip ${VIP} at dev ${DEV} rc=$rc"
            exit 1
        fi

        log "deleted vip ${VIP} at dev ${DEV}"
    else
        log "vip not exists, skip delete vip"
    fi
}

log "loadvip start args:'$*'"

case $action in
  on_start|on_restart|on_role_change)
    case $role in
      master)
        load_vip
        ;;
      replica)
        unload_vip
        ;;
      *)
        log "wrong role '$role'"
        exit 1
        ;;
    esac
    ;;
  on_stop)
    unload_vip
    ;;
  *)
    log "wrong action '$action'"
    exit 1
    ;;
esac

```

*创建 `/usr/lib/systemd/system/patroni.service` 服务单元文件*

```ini
[Unit]
Description=Runners to orchestrate a high-availability PostgreSQL
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
EnvironmentFile=-/etc/patroni/patroni_env.conf

# 使用 watchdog 进行服务监控
ExecStartPre=/sbin/modprobe softdog
ExecStartPre=/bin/chown 666 /dev/watchdog

ExecStart=/usr/local/bin/patroni /etc/patroni/patroni.yml
ExecReload=/bin/kill -s HUP $MAINPID

PermissionsStartOnly=true
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.target
```


## 启动 postgresql 集群

启动 `postgresql` 集群很简单，只需运行 `patroni` 服务即可

```bash
systemctl start patroni.service
systemctl enable patroni.service
```

*查看集群状态*

```bash
[root@localhost ~]# patronictl -c /etc/patroni/patroni.yml list
+ Cluster: pgcluster (7287503432727295215) ----------+----+-----------+
| Member | Host           | Role         | State     | TL | Lag in MB |
+--------+----------------+--------------+-----------+----+-----------+
| pg1    | 192.168.142.11 | Replica      | streaming |  2 |         0 |
| pg2    | 192.168.142.12 | Leader       | running   |  2 |           |
| pg3    | 192.168.142.13 | Sync Standby | streaming |  2 |         0 |
+--------+----------------+--------------+-----------+----+-----------+
```
