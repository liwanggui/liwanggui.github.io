# 部署 etcd 集群


准备 3 台服务器，确保服务器之间网络通信正常，关闭防火墙(或者开放 `2379` 和 `2380` 端口), 服务器列表如下

| ip 地址           | etcd 名称 | 
| :--------------- | :----- |
| 192.168.142.11  | etcd-1 |
| 192.168.142.12  | etcd-2 |
| 192.168.142.13  | etcd-3 |

## 安装 etcd

```bash
wget https://github.com/etcd-io/etcd/releases/download/v3.5.9/etcd-v3.5.9-linux-amd64.tar.gz
tar xzf etcd-v3.5.9-linux-amd64.tar.gz
cd etcd-v3.5.9-linux-amd64/
mv  etcd  etcdctl  etcdutl /usr/bin/
```

## 配置 etcd 

*配置 etcd-1*

```bash
useradd -r -d /var/lib/etcd -m etcd
mkdir /etc/etcd

cat >/etc/etcd/etcd.conf<<EOF
name: etcd-1
data-dir: /var/lib/etcd/data
listen-client-urls: http://0.0.0.0:2379
advertise-client-urls: http://192.168.142.11:2379,http://localhost:2379
listen-peer-urls: http://192.168.142.11:2380
initial-advertise-peer-urls: http://192.168.142.11:2380
initial-cluster: etcd-1=http://192.168.142.11:2380,etcd-2=http://192.168.142.12:2380,etcd-3=http://192.168.142.13:2380
initial-cluster-token: etcd-cluster
initial-cluster-state: new
EOF

cat >/usr/lib/systemd/system/etcd.service<<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
User=etcd
ExecStart=/usr/bin/etcd --config-file /etc/etcd/etcd.conf
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

*配置 etcd-2*

```bash
useradd -r -d /var/lib/etcd -m etcd
mkdir /etc/etcd

cat >/etc/etcd/etcd.conf<<EOF
name: etcd-2
data-dir: /var/lib/etcd/data
listen-client-urls: http://0.0.0.0:2379
advertise-client-urls: http://192.168.142.12:2379,http://localhost:2379
listen-peer-urls: http://192.168.142.12:2380
initial-advertise-peer-urls: http://192.168.142.12:2380
initial-cluster: etcd-1=http://192.168.142.11:2380,etcd-2=http://192.168.142.12:2380,etcd-3=http://192.168.142.13:2380
initial-cluster-token: etcd-cluster
initial-cluster-state: new
EOF

cat >/usr/lib/systemd/system/etcd.service<<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
User=etcd
ExecStart=/usr/bin/etcd --config-file /etc/etcd/etcd.conf
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```


*配置 etcd-3*

```bash
useradd -r -d /var/lib/etcd -m etcd
mkdir /etc/etcd

cat >/etc/etcd/etcd.conf<<EOF
name: etcd-1
data-dir: /var/lib/etcd/data
listen-client-urls: http://0.0.0.0:2379
advertise-client-urls: http://192.168.142.13:2379,http://localhost:2379
listen-peer-urls: http://192.168.142.13:2380
initial-advertise-peer-urls: http://192.168.142.13:2380
initial-cluster: etcd-1=http://192.168.142.11:2380,etcd-2=http://192.168.142.12:2380,etcd-3=http://192.168.142.13:2380
initial-cluster-token: etcd-cluster
initial-cluster-state: new
EOF

cat >/usr/lib/systemd/system/etcd.service<<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
User=etcd
ExecStart=/usr/bin/etcd --config-file /etc/etcd/etcd.conf
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

**etcd 配置项说明**

```yaml
#etcd名称，自定义
name: etcd-1

#存放etcd数据的目录，自定义
data-dir: /opt/etcd-v3.5.0/data

#监听URL，用户客户端和SERVER进行通信
listen-client-urls: http://192.168.210.15:2379,http://127.0.0.1:2379

#告知客户端自身的URL，TCP 2379端口用于监听客户端请求
advertise-client-urls: http://192.168.210.15:2379,http://127.0.0.1:2379

#监听URL，用于和其他节点通信
listen-peer-urls: http://192.168.210.15:2380

#告知集群其他节点，端口2380用于集群通信
initial-advertise-peer-urls: http://192.168.210.15:2380

#定义了集群内所有成员
initial-cluster: etcd-1=http://192.168.210.15:2380,etcd-2=http://192.168.108.81:2380,etcd-3=http://192.168.108.33:2380

#集群ID，唯一标识
initial-cluster-token: etcd-cluster-token

#集群状态，new为新创建集群，existing为已经存在的集群
initial-cluster-state: new
```

## 启动 etcd 集群

在 3 台服务器分别执行以下命令, 启动 etcd

```bash
systemctl start etcd.service
```

**查看集群成员信息**

```bash
[root@localhost etcd]# etcdctl endpoint status --endpoints=192.168.142.11:2379,192.168.142.12:2379,192.168.142.13:2379 -w table
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|          ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| http://192.168.142.11:2379 | 60f0df9302fbd5e2 |   3.5.4 |   20 kB |      true |      false |         2 |         10 |                 10 |        |
| http://192.168.142.12:2379 | fc3fb054d5b9a580 |   3.5.4 |   20 kB |     false |      false |         2 |         10 |                 10 |        |
| http://192.168.142.13:2379 | 875d90cd443032bb |   3.5.4 |   20 kB |     false |      false |         2 |         10 |                 10 |        |
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
[root@localhost etcd]# etcdctl endpoint health --endpoints=192.168.142.11:2379,192.168.142.12:2379,192.168.142.13:2379 -w table
+----------------------------+--------+------------+-------+
|          ENDPOINT          | HEALTH |    TOOK    | ERROR |
+----------------------------+--------+------------+-------+
| http://192.168.142.11:2379 |   true | 4.485896ms |       |
| http://192.168.142.12:2379 |   true | 6.322733ms |       |
| http://192.168.142.13:2379 |   true | 6.230848ms |       |
+----------------------------+--------+------------+-------+
[root@localhost etcd]# etcdctl member list --endpoints=192.168.142.11:2379,192.168.142.12:2379,192.168.142.13:2379 -w table
+------------------+---------+-------+----------------------------+--------------------------------------------------+------------+
|        ID        | STATUS  | NAME  |         PEER ADDRS         |                   CLIENT ADDRS                   | IS LEARNER |
+------------------+---------+-------+----------------------------+--------------------------------------------------+------------+
| 60f0df9302fbd5e2 | started | etcd0 | http://192.168.142.11:2380 | http://192.168.142.11:2379,http://localhost:2379 |      false |
| 875d90cd443032bb | started | etcd2 | http://192.168.142.13:2380 | http://192.168.142.13:2379,http://localhost:2379 |      false |
| fc3fb054d5b9a580 | started | etcd1 | http://192.168.142.12:2380 | http://192.168.142.12:2379,http://localhost:2379 |      false |
+------------------+---------+-------+----------------------------+--------------------------------------------------+------------+
```

> 管理 etcd cluster 成员注意事项参考: https://www.modb.pro/db/153295

