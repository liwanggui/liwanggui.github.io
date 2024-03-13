---
title: "Linux 环境下构建可移植 Python 二进制文件"
date: 2024-03-13T09:26:34+08:00
draft: false
categories: 
- python
tags:
- portable-python
---

本文介绍如何在 linux 系统构建一个可移植的 Python 二进制文件

- 工具: [portable-python](https://github.com/codrsquad/portable-python)

## 安装 portable-python

portable-python 是一个常规的 python 命令行工具，它可以通过以下方式安装：

*pickley:*

```bash
pickley install portable-python
portable-python --help
portable-python inspect /usr/bin/python3
```

*Or pipx:*

```bash
pipx install portable-python
portable-python inspect /usr/bin/python3
```

*Or pip:*

```bash
/usr/bin/python3 -mvenv /tmp/pp
/tmp/pp/bin/python -mpip install portable-python
/tmp/pp/bin/portable-python --help
/tmp/pp/bin/portable-python inspect /usr/bin/python3
```

## 构建可移植 Python

1. 安装依赖

```bash
yum install -y zlib-devel libffi-devel readline-devel bzip2-devel openssl-devel libuuid-devel gdbm-devel tk-devel
```

2. 查看当前最新的 Python 版本

```bash
$ portable-python list
cpython:
  3.12: 3.12.2
  3.11: 3.11.8
  3.10: 3.10.13
  3.9: 3.9.18
  3.8: 3.8.18
  3.7: 3.7.17
```

3. 构建一个可移植的 python

```bash
# 创建工作目录
$ mkdir 3.10.13
$ cd 3.10.13

# 开始构建 Python 3.10.13 版本
$ portable-python build 3.10.13

# 构建完成后生成的二进制文件压缩包
$ ls -l dist/cpython-3.10.13-linux-x86_64.tar.gz
```

*构建工作目录结构*

portable-python 使用此文件结构（build 和 dist 文件夹可配置）：

```
build/
    ppp-marker/3.10.13/                    # 完整安装（构建完成后）
    components/                            # 静态编译扩展模块的构建在这里
    deps/                                  # --prefix=.../deps 传递给所有组件 ./configure 脚本
    sources/
        xz-5.4.6.tar.gz                    # 下载的程序码源包（仅下载一次）
dist/
    cpython-3.10.13-linux-x86_64.tar.gz    # 随时可用的便携式二进制压缩包
```