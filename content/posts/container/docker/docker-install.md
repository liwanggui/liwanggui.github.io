---
title: "docker - 快速安装"
date: "2021-03-06T10:39:29+08:00"
draft: false
categories:
- container
tags:
- docker
---

## 一键安装 docker

`Docker` 官方提供了一键安装 docker 脚本工具: [https://github.com/docker/docker-install](https://github.com/docker/docker-install)

### 安装 docker

```bash
curl -fsSL https://get.docker.com | bash
```

> 默认下载源是 docker 官方境外的源，在国内下载很慢

### 指定阿里源安装 docker

```bash
curl -fsSL https://get.docker.com | bash -s -- --mirror=Aliyun
```

> 通过传递 `VERSION=20.10.5` 变量，可以安装指定版本的 docker

## 配置阿里源安装 docker

```bash
# step 1: 安装必要的一些系统工具
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common

# step 2: 安装GPG证书
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

# Step 3: 写入软件源信息
sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"

# Step 4: 更新并安装Docker-CE
sudo apt-get -y update
sudo apt-get -y install docker-ce
```

### 安装指定版本的Docker-CE

*1: 查找 Docker-CE的版本:*

```bash
root@ops:~# apt-cache madison docker-ce
 docker-ce | 5:20.10.5~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:20.10.4~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:20.10.3~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:20.10.2~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:20.10.1~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:20.10.0~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:19.03.15~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:19.03.14~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:19.03.13~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:19.03.12~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:19.03.11~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:19.03.10~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:19.03.9~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:19.03.8~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
 docker-ce | 5:19.03.7~3-0~ubuntu-bionic | https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
...
```

*2: 安装指定版本的 Docker-CE: (VERSION 例如上面的 5:19.03.15~3-0~ubuntu-bionic)*

```bash
root@ops:~# apt-get -y install docker-ce=5:19.03.15~3-0~ubuntu-bionic
```

> 注意: 如果部署 kubernetes 集群，就是需要安装经过 kubernetes 验证过的 docker 版本

### 配置 docker 命令自动补全

配置前需要先安装 `bash-completion` 工具包

```bash
curl -o /etc/bash_completion.d/docker -fsSL https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker
source /etc/profile
```