# 使用 ncdu 查找 linux 下最占空间的文件


Ncdu 是一个具有 ncurses 接口的磁盘使用率分析器。它的目的是在没有完整图形设置的远程服务器上查找空间占用者，但即使在常规桌面系统上，它也是一个有用的工具。
Ncdu 的目标是快速、简单和易于使用，并且应该能够在安装了 ncurses 的任何最小的类似 POSIX 的环境中运行。

> 软件官网地址：[https://dev.yorhel.nl/ncdu](https://dev.yorhel.nl/ncdu)

## 安装

```bash
yum install ncdu
```

你也可以使用源码包进行编译安装

```bash
wget https://dev.yorhel.nl/download/ncdu-1.15.1.tar.gz
tar xzvf ncdu-1.15.1.tar.gz
cd ncdu-1.15.1
./configure
make && make install
```

## 使用方法

```bash
ncdu  [dirname]
```

![ncdu](/images/cli/ncdu.jpg)

> 提示: 按 `j` `k` 进行上下移动或者使用上下方向键，`Enter` 键进行
