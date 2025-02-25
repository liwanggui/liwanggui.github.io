---
title: YUM 下载全量依赖 rpm 包
date: "2024-04-01T15:31:06+08:00"
draft: false
categories:
- devops
- centos
tags:
- yum
---

## 简介

通常生产环境由于安全原因都无法访问互联网。此时就需要进行离线安装，主要有两种方式：源码编译、rpm 包安装。 源码编译耗费时间长且缺乏编译环境，所以一般都选择使用离线 rpm 包安装。

## 查看依赖包

可以使用 `yum deplist` 命令来查找 rpm 包的依赖列表。例如，要查找 "ansible" rpm 的依赖包：

```bash
yum deplist ansible
```

## 离线安装方案

### 方案一：repotrack（推荐）

安装 yum-utils

```bash
yum -y install yum-utils
```

下载 ansible 全量依赖包

```bash
repotrack ansible
```

### 方案二：yumdownloader

安装 yum-utils

```bash
yum -y install yum-utils
```

下载 ansible 依赖包

```bash
yumdownloader --resolve --destdir=/tmp ansible
```

**参数说明：**

- `--destdir`：指定 rpm 包下载目录（不指定时，默认为当前目录）
- `--resolve`：下载依赖的 rpm 包

> **注意：** 仅会将主软件包和基于你现在的操作系统所缺少的依赖关系包一并下载。

### 方案三：yum 的 downloadonly 插件

安装插件

```bash
yum -y install yum-download
```

下载 ansible 依赖包

```bash
yum -y install ansible --downloadonly --downloaddir=/tmp
```

> **注意：** 与 yumdownloader 命令一样，也是仅会将主软件包和基于你现在的操作系统所缺少的依赖关系包一并下载。
