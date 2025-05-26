# 通过 rsync + inotify 搭建实时文件同步系统


## 任务需求

需要将一台服务器指定目录中的文件实时同步到另一台服务器上，目录路径 `/data/www/pic`, 此时我们通过 `Rsync` + `Inotify` 来实现。 服务器如下

- 192.168.145.131: 文件发布推送，客户端
- 192.168.145.132: 文件同步接收，服务端

由于我们需要将 `192.168.145.131` 上的文件实时同步至 `192.168.145.132` 服务器，所以 `192.168.145.132` 为服务端，`192.168.145.131` 为客户端

## 配置服务端

### 安装 rsync

```bash
yum install rsync
```

### 配置 rsync

编辑文件 `/etc/rsyncd.conf`，写入如下配置信息

```bash
# /etc/rsyncd: configuration file for rsync daemon mode
# See rsyncd.conf man page for more options.
# configuration example:

uid = nobody
gid = nobody
use chroot = yes
max connections = 10
pid file = /var/run/rsyncd.pid
# exclude = lost+found/
transfer logging = yes
timeout = 900
fake super = yes  # 不要漏了这项配置，否则会报 Operation not permitted 错误
# ignore nonreadable = yes
# dont compress   = *.gz *.tgz *.zip *.z *.Z *.rpm *.deb *.bz2

[www]
# 同步文件存放目录
path = /data/www/
comment = Files synced in real time
ignore errors
read only = no
write only = no
# 允许连接的IP地址
hosts allow = 192.168.145.131
# 拒绝连接的 IP 地址，* 号匹配所有
hosts deny = *
list = false
# 同步过来文件的属主和属组，记得修改同步目录的的权限：  chown -R www.www /data/www
uid = www
gid = www
# 客户端连接使用的用户名
auth users = www
# 客户端连接使用的用户名及密码，格式  <username>:<password> 以普通文本文件存放，注意权限
secrets file = /etc/www.pass
```

生成 rsync 客户端连接使用的验证文件

```bash
echo 'www:123456' > /etc/www.pass
chmod 600 /etc/www.pass
```

创建同步目录，并授权（根据配置文件的批定的uid，gid）于相应的权限

```bash
mkdir -p /data/www
chown -R www.www /data/www
```

### 启动 rsync

```bash
systemctl start rsyncd.service
systemctl enable rsyncd.service
```

## 配置客户端

由于客户端是文件推送端，需要实时检测文件目录的变化并同步至服务端，所以需要安装 `rsync` 和 `inotify-tools` 工具

### 安装 rsync

```bash
yum install rsync
```

### 安装 inotify-tools

由于 inotify 特性需要 Linux 内核的支持，在安装 inotify-tools 前要先确认 Linux 系统内核是否达到了 2.6.13 以上，如果 Linux 内核低于 2.6.13 版本，就需要重新编译内核加入 inotify 的支持，也可以用如下方法判断，内核是否支持 inotify

```bash
[root@localhost ~]# uname -r
3.10.0-862.el7.x86_64
[root@localhost ~]# ll /proc/sys/fs/inotify
total 0
-rw-r--r-- 1 root root 0 Jun 12 21:10 max_queued_events
-rw-r--r-- 1 root root 0 Jun 12 21:10 max_user_instances
-rw-r--r-- 1 root root 0 Jun 12 21:10 max_user_watches
```

> 如果有上面三项输出，表示系统已经默认支持 inotify，接着就可以开始安装 inotify-tools 了

```bash
yum install inotify-tools
```

`inotify-tools` 安装完成后，会生成 `inotifywait` 和 `inotifywatch` 两个指令。

- `inotifywait` 用于等待文件或文件集上的一个特定事件，它可以监控任何文件和目录设置，并且可以递归地监控整个目录树。
- `inotifywatch` 用于收集被监控的文件系统统计数据，包括每个 `inotify` 事件发生多少次等信息。

### inotify 相关参数

inotify 定义了下列的接口参数，可以用来限制 inotify 消耗 kernel memory 的大小。由于这些参数都是内存参数，因此，可以根据应用需求，实时的调节其大小。下面分别做简单介绍。

- `/proc/sys/fs/inotify/max_queued_evnets`：表示调用 `inotify_init` 时分配给 `inotify instance` 中可排队的 `event` 的数目的最大值，超出这个值的事件被丢弃，但会触发 `IN_Q_OVERFLOW` 事件。
- `/proc/sys/fs/inotify/max_user_instances`: 表示每一个 `real user` ID可创建的 `inotify instatnces` 的数量上限。
- `/proc/sys/fs/inotify/max_user_watches`: 表示每个 `inotify instatnces` 可监控的最大目录数量。 如果监控的文件数目巨大，需要根据情况，适当增加此值的大小, 例如: 

```bash
echo 30000000 > /proc/sys/fs/inotify/max_user_watches
```

### inotifywait 相关参数

`inotifywait` 是一个监控等待事件，可以配合 shell 脚本使用它，下面介绍一下常用的一些参数：

- `-m`， 即 `--monitor`，表示始终保持事件监听状态。
- `-r`， 即 `--recursive`，表示递归查询目录。
- `-q`， 即 `--quiet`，表示打印出监控事件。
- `-e`， 即 `--event`，通过此参数可以指定要监控的事件，常见的事件有 `modify`、`delete`、`create`、`attrib` 等。

> 更详细的请参看 `man  inotifywait`

### 配置 inotify

在 `/data/scripts` 目录中写入以下脚本文件，文件名为 `inotify-rsync.sh`

```bash
#!/bin/bash
#
#***************************************************************************
# Author: liwanggui
# Date: 2017-03-24
# FileName: inotify-rsync.sh
# Description: Real-time file synchronization
# Copyright (C): 2021 All rights reserved
#***************************************************************************
#

host=192.168.145.132
src=/data/www/pic
# rsyncd.conf 配置项名称
dst=www
# 连接验证的用户名
user=www

/usr/bin/inotifywait -mrq --timefmt '%y/%m/%d %H:%M:%S ' --format '%T %w%f %e ' -e close_write,delete,create,attrib  $src \
| while read files
        do
        /usr/bin/rsync -vzrtopg --delete --progress --password-file=/etc/www.pass $src $user@$host::$dst
        echo "${files} was rsynced" &>>/tmp/rsync.log
        done
```

### 启动测试

使用 `nohup` 将脚本以守护进程的方式的运行在后台

```bash
nohup bash /data/scripts/inotify-rsync.sh &
```

在 `/data/www/pic` 目录生成一些文件

```bash
cp /etc/yum.repos.d/* /data/www/pic/
```

查看脚本日志, 使用 `cat /tmp/rsync.log` 命令查看

```bash
17/03/24 22:15:43  /data/www/pic/CentOS-Base.repo CREATE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-Base.repo CLOSE_WRITE,CLOSE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-CR.repo CREATE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-CR.repo CLOSE_WRITE,CLOSE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-Debuginfo.repo CREATE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-Debuginfo.repo CLOSE_WRITE,CLOSE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-fasttrack.repo CREATE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-fasttrack.repo CLOSE_WRITE,CLOSE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-Media.repo CREATE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-Media.repo CLOSE_WRITE,CLOSE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-Sources.repo CREATE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-Sources.repo CLOSE_WRITE,CLOSE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-Vault.repo CREATE was rsynced
17/03/24 22:15:43  /data/www/pic/CentOS-Vault.repo CLOSE_WRITE,CLOSE was rsynced
17/03/24 22:15:43  /data/www/pic/epel.repo CREATE was rsynced
17/03/24 22:15:43  /data/www/pic/epel.repo CLOSE_WRITE,CLOSE was rsynced
17/03/24 22:15:43  /data/www/pic/epel-testing.repo CREATE was rsynced
17/03/24 22:15:43  /data/www/pic/epel-testing.repo CLOSE_WRITE,CLOSE was rsynced
```

在服务端查看文件同步情况, `ls -l /data/www/pic`

```bash
-rw-r--r-- 1 www www 1572 Jun 12 22:15 CentOS-Base.repo
-rw-r--r-- 1 www www 1309 Jun 12 22:15 CentOS-CR.repo
-rw-r--r-- 1 www www  649 Jun 12 22:15 CentOS-Debuginfo.repo
-rw-r--r-- 1 www www  314 Jun 12 22:15 CentOS-fasttrack.repo
-rw-r--r-- 1 www www  630 Jun 12 22:15 CentOS-Media.repo
-rw-r--r-- 1 www www 1331 Jun 12 22:15 CentOS-Sources.repo
-rw-r--r-- 1 www www 4768 Jun 12 22:15 CentOS-Vault.repo
-rw-r--r-- 1 www www  951 Jun 12 22:15 epel.repo
-rw-r--r-- 1 www www 1050 Jun 12 22:15 epel-testing.repo
```

> 我们可以看到文件同步过来了，而且文件 `UID` 和 `GID` 也是配置文件设置的 `www`
> 参考网址：[http://ixdba.blog.51cto.com/2895551/580280](http://ixdba.blog.51cto.com/2895551/580280)
