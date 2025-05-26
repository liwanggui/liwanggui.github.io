# 部署 rabbitmq 集群


由于 `rabbitmq` 是 `erlang` 开发的所以依赖 `erlang`, 准备三台服务器并配置好主机名, 并以下信息写入三台服务器的 `hosts`.

```bash
mq1 192.168.1.11
mq2 192.168.1.12
mq3 192.168.1.13
```

## 1. 配置 erlang, rabbitmq YUM 仓库

```bash
curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash
```

## 2. 安装 eple 扩展

```bash
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
```

## 3. 安装 rabbitmq

```bash
yum install -y erlang rabbitmq-server
```

## 4. 开启 rabbitmq WEB 管理

```bash
rabbitmq-plugins enable rabbitmq_management
```

## 5. 后台启动 rabbitmq

```bash
rabbitmq-server -detached
```

## 6. 配置 rabbitmq 集群

```bash
rabbitmqctl stop_app
rabbitmqctl join_cluster --disc rabbit@mq1
rabbitmqctl start_app
```

> --ram 为内存节点

## 7. 修改 rabbitmq 用户

```bash
rabbitmqctl add_user jpuser 'G6JzIC3ifipGIMa'
rabbitmqctl set_user_tags jpuser administrator
rabbitmqctl set_permissions -p '/' jpuser '.*' '.*' '.*'
```

## 8. 配置为高可用集群

```bash
rabbitmqctl set_policy ha-all-queue "^" '{"ha-mode":"all","ha-sync-mode":"automatic"}'
```

> 设置 `policy`，以 `ha.` 开头的队列将会被镜像到集群其他所有节点,一个节点挂掉然后重启后会自动同步队列消息（生产环境采用这个方式）
