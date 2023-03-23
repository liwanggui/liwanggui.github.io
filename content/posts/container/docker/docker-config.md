---
title: "docker - 基本配置项"
date: "2021-03-06T10:48:43+08:00"
draft: false
categories:
- container
tags:
- docker
---

完整的配置项参考: [https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file][1]

## docker 常用的配置项

> `docker` 默认配置文件路径为:  `/etc/docker/daemon.json`

```bash
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn", "http://hub-mirror.c.163.com"], # 镜像加速器
  "insecure-registries":["harbor.host.com"],  # 第三方仓库或自建仓库地址，可以配置为 http
  "data-root": "/data/docker",  # docker 数据存储目录
  "exec-opts": ["native.cgroupdriver=systemd"], # 额外参数,部署 k8s 时需要指定此选项
  "bip": "10.10.0.1/16",  # 配置 docker 网桥 ip
  "log-driver": "json-file",
  "log-opts": { "max-size": "100m"},
  "live-restore": true
}
```

[1]: https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file