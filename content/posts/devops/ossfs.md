---
title: "使用 ossfs 挂载阿里云 OSS 至本地文件系统"
date: 2023-11-13T11:33:11+08:00
draft: false
categories: 
- devops
tags:
- ossfs
---

## 概述

ossfs 能让您在 Linux 系统中，将对象存储OSS的存储空间（Bucket）挂载到本地文件系统中，您能够像操作本地文件一样操作OSS的对象（Object），实现数据的共享。

## 运行环境

ossfs 基于 fuse 用户态文件系统开发，只能运行在支持 fuse 的机器上。OSS 提供了 Ubuntu 和 CentOS 系统的安装包，如果需要在其它环境下运行，可以通过源码方式构建目标程序。

ossfs 支持在阿里云内网以及互联网环境下使用。在内网环境下时，建议使用内网访问域名，以提升访问速度和稳定性。

## 安装 ossfs

以 CentOS 8.X 为例, ossfs 依赖 fuse ，使用 yum 安装可以解决依赖问题

```bash
yum install -y https://gosspublic.alicdn.com/ossfs/ossfs_1.91.1_centos8.0_x86_64.rpm
```

[ossfs 下载地址](https://help.aliyun.com/zh/oss/developer-reference/ossfs-installation#section-8tz-qyn-88v)

## 配置 ossfs

**配置账号访问信息**

将 Bucket 名称以及具有该 Bucket 访问权限的 AccessKey ID 和 AccessKey Secret 信息存放在 /etc/passwd-ossfs 文件中。文件的权限建议设置为640。

```bash
sudo echo BucketName:yourAccessKeyId:yourAccessKeySecret > /etc/passwd-ossfs
sudo chmod 640 /etc/passwd-ossfs
```

BucketName、yourAccessKeyId、yourAccessKeySecret 请按需替换为您实际的Bucket名称、AccessKey ID和AccessKey Secret，例如：

```bash
sudo echo bucket-test:LTAIbZcdVCmQ****:MOk8x0y9hxQ31coh7A5e2MZEUz**** > /etc/passwd-ossfs
sudo chmod 640 /etc/passwd-ossfs
```

**将Bucket挂载到指定目录**

```bash
sudo ossfs BucketName mountfolder -o url=Endpoint
```

示例: 将杭州地域名称为 bucket-test 的 Bucket 挂载到 /tmp/ossfs 目录下的示例如下：

```bash
sudo mkdir /tmp/ossfs
sudo ossfs bucket-test /tmp/ossfs -o url=http://oss-cn-hangzhou.aliyuncs.com
```

如果您不希望继续挂载此 Bucket，您可以将其卸载

```bash
sudo fusermount -u /tmp/ossfs
```

## 高级配置

### 挂载指定文件目录

ossfs 除了可以把整个存储空间挂载到本地文件系统外，还可以通过设置前缀，把存储空间下的某个文件目录挂载到本地文件系统。命令格式如下：

```bash
ossfs bucket:/prefix mount_point -ourl=endpoint
```

通过这个方式挂载时，需要确保存储空间里存在 `${prefix}/` 对象。您可以通过 `ossutil` 的 stat（查看Bucket和Object信息）命令查询该对象是否存在

示例：将位于杭州地域的存储空间 `bucket-ossfs-test` 下的 `folder` 目录挂载到 `/tmp/ossfs-folder` 下

```bash
ossfs bucket-ossfs-test:/folder /tmp/ossfs-folder -ourl=http://oss-cn-hangzhou.aliyuncs.com
```

### 开机自动挂载目录

**通过 fstab 的方式自动挂载**

在 `/etc/fstab` 中加入如下命令：

```bash
ossfs#zr-repo mount_point fuse _netdev,url=url,allow_other,nonempty 0 0
```

保存 `/etc/fstab` 文件。 执行 `mount -a`命令，如果没有报错，则说明设置正常

**通过 systemd 开机自动进行挂载**

创建 `/usr/lib/systemd/system/ossfs.service` 和 `/etc/sysconfig/ossfs`

*/usr/lib/systemd/system/ossfs.service*

```ini
[Unit]
Description=Mount an Alibaba Cloud OSS bucket as a file system
After=syslog.target network.target remote-fs.target

[Service]
Type=forking
EnvironmentFile=-/etc/sysconfig/ossfs
ExecStartPre=
ExecStart=/usr/local/bin/ossfs $BUCKETNAME $MOUNTPOINT -o url=$ENDPOINT
ExecReload=
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

*/etc/sysconfig/ossfs*

```bash
BUCKETNAME=bucket-ossfs-test
MOUNTPOINT=/tmp/ossfs-folder
ENDPOINT=http://oss-cn-hangzhou.aliyuncs.com
```

> 注意：值需要替换为自己的当前的配置

*启动并设置开机自动挂载*

```bash
systemctl enable --now ossfs.service
```

> 更新高级配置参考: https://help.aliyun.com/zh/oss/developer-reference/advanced-configurations