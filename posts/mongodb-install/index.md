# Mongodb 3.6 安装


## 下载 mongodb

> [MongoDB 社区版下载地址](https://www.mongodb.com/download-center/community/releases/archive)

```bash
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.6.20.tgz
```

## 配置 mongodb 

将下载的 `tar` 包解压至 `/usr/local` 路径下，创建软链接并配置好环境变量

```bash
cd /usr/local/src
tar xzf mongodb-linux-x86_64-rhel62-3.6.20.tgz -C /usr/local/
cd /usr/local/
ln -s /usr/local/mongodb-linux-x86_64-rhel62-3.6.20 /usr/local/mongodb
# 加入环境变量
echo 'export PATH=/usr/local/mongodb/bin:$PATH' > /etc/profile.d/mongo.sh
source /etc/profile
```

创建配置文件 `/etc/mongod.conf`, 配置如下

```yaml
# mongod.conf
# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# Where and how to store data.
storage:
  dbPath: /data/mongo
  journal:
    enabled: true
#  engine:
#  mmapv1:
#  wiredTiger:

# how the process runs
processManagement:
  fork: true  # fork and run in background
  pidFilePath: /var/run/mongodb/mongod.pid  # location of pidfile
  timeZoneInfo: /usr/share/zoneinfo

# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1  # Listen to local interface only, comment to listen on all interfaces.

#security:    
#  authorization: enabled              # 是否打开用户名和密码验证

#operationProfiling:

#replication:

#sharding:
```

创建数据目录并授权

```bash
useradd -r -s /bin/false mongod 
mkdir -p /data/mongo 
chown mongod:mongod /data/mongo 
```

## 管理 mongodb 服务

为 mongodb 编写 systemd unit 文件 `/usr/lib/systemd/system/mongod.service`

```bash
[Unit]
Description=MongoDB Database Server
Documentation=https://docs.mongodb.org/manual
After=network.target

[Service]
User=mongod
Group=mongod
Environment="OPTIONS=-f /etc/mongod.conf"
ExecStart=/usr/local/mongodb/bin/mongod $OPTIONS
ExecStartPre=/usr/bin/mkdir -p /var/run/mongodb
ExecStartPre=/usr/bin/chown mongod:mongod /var/run/mongodb
ExecStartPre=/usr/bin/chmod 0755 /var/run/mongodb
Restart=on-failure
PermissionsStartOnly=true
PIDFile=/var/run/mongodb/mongod.pid
Type=forking
# file size
LimitFSIZE=infinity
# cpu time
LimitCPU=infinity
# virtual memory size
LimitAS=infinity
# open files
LimitNOFILE=64000
# processes/threads
LimitNPROC=64000
# locked memory
LimitMEMLOCK=infinity
# total threads (user+kernel)
TasksMax=infinity
TasksAccounting=false
# Recommended limits for for mongod as specified in
# http://docs.mongodb.org/manual/reference/ulimit/#recommended-settings

[Install]
WantedBy=multi-user.target
EOF
```

启动 MongoDB 服务, 并设置为开机自启

```bash
systemctl enable --now mongod.service
```


## 连接 mongodb

使用以下命令连接至 mongodb

```bash
mongo 
# 或
mongo localhost:27017/admin
```
