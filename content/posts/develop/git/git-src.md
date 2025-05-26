---
title: "Git 源码编译安装"
date: 2021-10-23T17:33:46+08:00
draft: false
categories: 
- devops
- git
tags:
- git
---

## 环境准备

```bash
yum install -y curl-devel openssl-devel expat-devel gettext-devel readline-devel zlib-devel asciidoc xmlto docbook2X autoconf
yum install -y gcc gcc-c++ make
```

*为了解决二进制命令名称不同*

```bash
ln -s /usr/bin/db2x_docbook2texi /usr/bin/docbook2x-texi
```

## 编译

```bash
wget --no-check-certificate https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.23.4.tar.gz 
tar xzf git-2.23.4.tar.gz
cd git-2.23.4/
./configure --prefix=/usr
make -j 4
make install
```

## fpm 打包

编译参数

```bash
make all doc info -j 4
make install install-doc install-html install-info DESTDIR=/tmp/installdir
make install DESTDIR=/tmp/installdir
```

打包命令

```bash
fpm -s dir -t rpm -n git -v 2.23.4 --iteration 1.el7 -C /tmp/installdir/ usr
```