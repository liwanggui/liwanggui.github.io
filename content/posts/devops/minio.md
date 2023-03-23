---
title: "Minio 高性能对象存储"
date: 2023-03-09T12:00:30+08:00
draft: false
categories: 
- minio
tags:
- minio
---

## 部署 minio

> 官方文档: [https://min.io/docs/minio/linux/index.html](https://min.io/docs/minio/linux/index.html)

*下载安装*

```bash
wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio
chmod +x /usr/local/bin/minio
```

*创建 systemd service 文件 `/usr/lib/systemd/system/minio.service`*


```
[Unit]
Description=MinIO
Documentation=https://min.io/docs/minio/linux/index.html
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
WorkingDirectory=/usr/local

User=minio
Group=minio

EnvironmentFile=-/etc/default/minio
ExecStartPre=/bin/bash -c "if [ -z \"${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"
ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

# Let systemd restart this service always
Restart=always

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Specifies the maximum number of threads this process can create
TasksMax=infinity

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
```

*创建用户和组*

```bash
groupadd -r minio
useradd -M -r -g minio minio
```

*创建环境变量文件 `/etc/default/minio`*

```bash
# MINIO_ROOT_USER and MINIO_ROOT_PASSWORD sets the root account for the MinIO server.
# This user has unrestricted permissions to perform S3 and administrative API operations on any resource in the deployment.
# Omit to use the default values 'minioadmin:minioadmin'.
# MinIO recommends setting non-default values as a best practice, regardless of environment

MINIO_ROOT_USER=myminioadmin
MINIO_ROOT_PASSWORD=minio-secret-key-change-me

MINIO_ADDRESS=":9000"
MINIO_CONSOLE_ADDRESS=":9001"

# MINIO_VOLUMES sets the storage volume or path to use for the MinIO server.

MINIO_VOLUMES="/mnt/data"

# MINIO_SERVER_URL sets the hostname of the local machine for use with the MinIO Server
# MinIO assumes your network control plane can correctly resolve this hostname to the local machine

# Uncomment the following line and replace the value with the correct hostname for the local machine.
# 配置 API 域名
#MINIO_SERVER_URL="http://minio.example.net"
```

- `MINIO_ROOT_USER`: 管理用户名
- `MINIO_ROOT_PASSWORD`: 管理用户密码，长度最小8位
- `MINIO_ADDRESS`: 指定 API 监听地址和端口
- `MINIO_CONSOLE_ADDRESS`: 指定控制台监听地址和端口

*准备数据目录*

```bash
chown minio:minio /mnt/data
```

*启动 Minio 服务*

```bash
systemctl start minio.service
systemctl enable minio.service
```

## 使用 Minio 和 nginx 部署静态站点

1. 创建存储桶

{{< image src="/images/minio/3af4d53d-4e4c-426b-891f-16211b23141e.png" caption="创建存储桶 (`wglee`)" >}}

2. 存储桶开启匿名访问, 开启后可以直接通过 http://<api-address>:<port>/<buckets-name>/<filename> 访问存储桶中的文件

{{< image src="/images/minio/65ef5ad7-a990-4683-bbac-e1a614a49da1.png" caption="存储桶开启匿名访问 (`wglee`)" >}}

3. 上传站点文件

{{< image src="/images/minio/4ad93807-d524-4df2-b424-987ea05cba8a.png" caption="上传站点文件 (`wglee`)" >}}

4. 配置 nginx 

```
server {
    listen 80;
    server_name localhost;

    rewrite  ^/$  /index.html  last;  # 默认访问索引页  index.html 
    rewrite  ^/(.*)/$  /$1/index.html  last;  # 设置子路径下默认索引页 index.html 

    location / {
        # 反代 wglee 存储桶, 路径最后一个斜杠不能少
        proxy_pass http://localhost:9000/wglee/;
        include proxy.conf;
    }
}
```