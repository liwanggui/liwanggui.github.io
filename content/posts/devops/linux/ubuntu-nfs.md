---
title: Ubuntu Server 网络文件系统（NFS）
date: "2021-04-24T11:04:36+08:00"
draft: false
categories:
- devops
- ubuntu
tags:
- ubuntu
- nfs
---

NFS 允许系统通过网络与他人共享目录和文件。通过使用 NFS，用户和程序可以访问远程系统上的文件，就好像它们是本地文件一样。

NFS 可以提供的一些最显著的好处是：

- 本地工作站使用较少的磁盘空间，因为常用数据可以存储在单台计算机上，并且仍然可以通过网络为其他人访问。
- 用户无需在每个网络机器上单独拥有 home 目录。home 目录可在 NFS 服务器上设置，并在整个网络中提供。
- 软盘、CDROM 驱动器和 USB 拇指驱动器等存储设备可用于网络上的其他计算机。这可能会减少整个网络中的可移动媒体驱动器的数量。

## 安装

在终端提示下输入以下命令以安装 NFS 服务器：

```bash
sudo apt install nfs-kernel-server
```

要启动 NFS 服务器，您可以在终端提示下运行以下命令：

```bash
sudo systemctl start nfs-kernel-server.service
```

## 配置

您可以通过将目录添加到 NFS 配置文件中来配置要共享的目录。默认配置文件：`/etc/exports`

```
/srv     *(ro,sync,subtree_check)
/home    *.hostname.com(rw,sync,no_subtree_check)
/scratch *(rw,async,no_subtree_check,no_root_squash,noexec)
```

确保已创建您添加的任何自定义安装点（`/srv` 和`/home` 将存在）：

```bash
sudo mkdir /scratch
```

重载 NFS 配置文件

```bash
sudo exportfs -a
```

您可以用具体的主机名替换 `*`。 使主机名声明尽可能具体。

同步/异步选项可控制更改是否在回复请求之前被限制为稳定存储。因此，async 会带来性能优势，但可能会造成数据丢失或损坏。尽管同步是默认的，但值得设置，因为如果未指定，`exportfs` 将发出警告。

`subtree_check` 和 `no_subtree_check` 启用或禁用安全验证，即客户端尝试为 `exported` 文件系统安装的子指示器是允许他们进行的安全验证。此验证步骤对某些使用案例（例如文件重命名频繁的家庭目录）有一些性能影响。仅读文件系统更适合启用 `subtree_check` 。与同步一样，如果未指定，`exportfs` 将发出警告。

NFS 有许多可选设置，用于调整性能、加强安全性或提供便利。这些设置各有其自身的权衡，因此谨慎使用它们非常重要，仅针对特定用例需要。例如， `no_root_squash` 增加了便利性，允许任何客户端系统的根用户修改根拥有的文件：在允许在共享安装点上执行可执行项的多用户环境中，这可能导致安全问题。`noexec` 阻止可执行文件从安装点运行。

## NFS 客户端配置

要启用客户端系统的 NFS 支持，请在终端提示下输入以下命令：

```bash
sudo apt install nfs-common
```

使用 `mount` 命令从另一台机器上挂载共享的 NFS 目录，在终端提示处键入类似于以下命令行：

```bash
sudo mkdir /opt/example
sudo mount example.hostname.com:/srv /opt/example
```

## 警告

挂载点目录必须存在。目录中不应有任何文件或子目录，否则它们将无法访问，直到 nfs 文件系统卸载。`/opt/example/opt/example`

挂载 NFS 共享目录的另一种方法是向 `/etc/fstab` 文件添加一行配置。该行必须说明 NFS 服务器的主机名、及 NFS 共享目录的路径(在 NFS 服务器上的路径)。

`/etc/fstab` 配置如下

```
example.hostname.com:/srv /opt/example nfs rsize=8192,wsize=8192,timeo=14,intr
```