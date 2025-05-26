# 部署 ElasticSearch 集群


## 环境准备

本文使用 Ubuntu 20.04 安装 elasticsearch 集群，准备三台机。

- 192.168.16.102
- 192.168.16.103
- 192.168.16.104

## 安装配置 elasticsearch 集群

### 安装 elasticsearch

```bash
root@ubuntu:/opt# wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.12.0-linux-x86_64.tar.gz
root@ubuntu:/opt# tar xzf elasticsearch-7.12.0-linux-x86_64.tar.gz
root@ubuntu:/opt# ln -s elasticsearch-7.12.0 elasticsearch
```

### 配置 elasticsearch

```bash
root@ubuntu:/opt# cd elasticsearch/config
root@ubuntu:/opt/elasticsearch/config# cat > elasticsearch.yml <<EOF
# 集群名
cluster.name: my-application
# 集群内同时启动的数据任务个数，默认是2个
cluster.routing.allocation.cluster_concurrent_rebalance: 16
# 添加或删除节点为及负载均衡时并发恢复的线程个数，默认是4个
cluster.routing.allocation.node_concurrent_recoveries: 16
# 初始化数据恢复时，并发恢复线程的个数，默认4个
cluster.routing.allocation.node_initial_primaries_recoveries: 16

# 节点名
node.name: node-1
# 是否有资格成为主节点
node.master: true
# 是否为数据节点
node.data: true

path.data: /data/elasticsearch/data
path.logs: /data/elasticsearch/logs

# 监听的网络地址
network.host: 0.0.0.0
network.tcp.keep_alive: true
network.tcp.no_delay: true

transport.tcp.compress: true
gateway.recover_after_nodes: 2

# 用于 HTTP 客户端通信的端口
http.port: 9200

# 用于节点之间通信的端口
transport.port: 9300

# head 管理插件需要打开跨域配置
http.cors.allow-origin: "*"
http.cors.enabled: true
http.max_content_length: 200mb

# 节点发现
discovery.seed_hosts: ["192.168.16.102:9300","192.168.16.103:9300","192.168.16.104:9300"]

# 初始化一个集群时需要此配置来选举 master
cluster.initial_master_nodes: ["node-1"]
EOF
# 配置 jvm 堆内存大小
root@ubuntu:/opt/elasticsearch/config# grep '^-Xm' jvm.options
-Xms4g
-Xmx4g
```

### 系统配置

```bash
root@ubuntu:/opt/elasticsearch# useradd -m -s /bin/bash elasticsearch
root@ubuntu:/opt/elasticsearch# mkdir -p /data/elasticsearch/{data,logs}
root@ubuntu:/opt/elasticsearch# chown -R elasticsearch.elasticsearch /data/elasticsearch
root@ubuntu:/opt/elasticsearch# chown -R elasticsearch.elasticsearch /opt/elasticsearch-7.12.0
root@ubuntu:/opt/elasticsearch/config# cat >> /etc/security/limits.conf <<EOF
*   soft   nproc   unlimited
*   hard   nproc   unlimited
*   soft   core    unlimited
*   soft   nofile  65535
*   hard   nofile  65535
EOF
root@ubuntu:/opt/elasticsearch/config# echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
root@ubuntu:/opt/elasticsearch/config# sysctl -p
```

### 启动 elasticsearch 服务

```bash
root@ubuntu:~# su - elasticsearch
elasticsearch@ubuntu:~$ cd /opt/elasticsearch
elasticsearch@ubuntu:/opt/elasticsearch$ ./bin/elasticsearch
```

> `elasticsearch` 默认不允许使用 `root` 用户启动， 需要切换至 `elasticsearch` 用户启动； `-d` 选项可以将程序设置为守护进程

> 提示：以相同的操作方法配置另两台节点，注意节点名不要重复

## elasticsearch 安全验证

elasticsearch 7.7 以后的版本将安全认证功能免费开放了。 并将 X-pack 插件集成了到了开源的 ElasticSearch 版本中。下面介绍如何利用 X-pack 给 ElasticSearch 相关组件设置用户名和密码

```bash
# 配置 xpack, 启用验证功能
root@ubuntu:/opt/elasticsearch# cat >>config/elasticsearch.yml <<EOF
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
EOF
# 重启 elasticsearch 服务
root@ubuntu:/opt/elasticsearch# kill <elasticsearch-pid>
root@ubuntu:/opt/elasticsearch# su - elasticsearch
elasticsearch@ubuntu:~$ cd /opt/elasticsearch
elasticsearch@ubuntu:/opt/elasticsearch$ ./bin/elasticsearch -d
# 使用交互命令行模式配置验证密码
elasticsearch@ubuntu:/opt/elasticsearch$ ./bin/elasticsearch-setup-passwords interactive
Initiating the setup of passwords for reserved users elastic,apm_system,kibana,kibana_system,logstash_system,beats_system,remote_monitoring_user.
You will be prompted to enter passwords as the process progresses.
Please confirm that you would like to continue [y/N]y

Enter password for [elastic]:
Reenter password for [elastic]:
Enter password for [apm_system]:
Reenter password for [apm_system]:
Enter password for [kibana_system]:
Reenter password for [kibana_system]:
Enter password for [logstash_system]:
Reenter password for [logstash_system]:
Enter password for [beats_system]:
Reenter password for [beats_system]:
Enter password for [remote_monitoring_user]:
Reenter password for [remote_monitoring_user]:
```

> 到此已经完成ES及相关组件的加密了, 后续访问和使用相关组件都需要验证用户名和密码了 (`请记好你配置的密码`)

> 验证密码信息存储在 `.security-7` 索引中

*不带密码访问时*

```bash
root@ubuntu:~# curl -I localhost:9200
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Basic realm="security" charset="UTF-8"
content-type: application/json; charset=UTF-8
content-length: 381
```

*带密码访问*

```bash
root@ubuntu:~#  curl -i localhost:9200 -u elastic:JEd01cn6hj0qm2mO
HTTP/1.1 200 OK
content-type: application/json; charset=UTF-8
content-length: 530

{
  "name" : "node-1",
  "cluster_name" : "my-application",
  "cluster_uuid" : "G6jxloWFR1SpCJ5cqb4EKA",
  "version" : {
    "number" : "7.12.0",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "78722783c38caa25a70982b5b042074cde5d3b3a",
    "build_date" : "2021-03-18T06:17:15.410153305Z",
    "build_snapshot" : false,
    "lucene_version" : "8.8.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

## 重置 elasticsearch 密码

- 官方文档: [https://www.elastic.co/guide/en/elasticsearch/reference/7.4/security-api-change-password.html](https://www.elastic.co/guide/en/elasticsearch/reference/7.4/security-api-change-password.html)

*修改 `elastic` 用户的密码*

```bash
root@ubuntu:~# curl -X POST localhost:9200/_security/user/elastic/_password \
-d '{"password":"123456"}' \
-u elastic:JEd01cn6hj0qm2mO \
-H 'content-type: application/json'
```

> 也可以使用 `./bin/elasticsearch-setup-passwords interactive` 命令重新设置
