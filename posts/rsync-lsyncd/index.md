# lsyncd 配合 rsync 实现目录实时双向同步


*需求*

有两台 `A`, `B` 服务器其中有个目录需要实时双向同步，即 `服务器A` 目录添加或删除文件需同步给 `服务器B`，同理 `服务器B` 也一样

## 安装

```bash
yum install epel-release
yum install lsyncd
```

## rsync

### rsyncd.conf 配置示例

*以下给出其中一台服务器的配置，另一台只需要修改下 `hosts allow` 配置即可， 配置文件 `/etc/rsyncd.conf`*

```bash
uid = nobody
gid = nobody
use chroot = no
max connections = 10
strict modes = yes
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsync.lock
log file = /data/rsync/rsyncd.log

[pu]
path = /data/www/platform_admin/Uploads
comment = platform uploads
ignore errors
read only = no
write only = no
hosts allow = 10.100.1.16
hosts deny = *
list = false
uid = www
gid = www
```

> 注意用户权限

### 启动 rsyncd 服务

```bash
systemctl start rsyncd.service
systemctl enable rsyncd.service
```

### 配置密钥

```bash
ssh-keygen -t rsa -C rsync
ssh-copy-id -i ~/.ssh/id_rsa.pub localhost
ssh-copy-id -i ~/.ssh/id_rsa.pub 10.100.1.16
scp -r .ssh 10.100.1.16:/root/
```

> 注意: 将公钥加两台机的 `~/.ssh/authorized_keys` 文件中，并复制私钥至另一台的 `~/.ssh` 目录下

## lsyncd

[Lysncd](https://github.com/axkibe/lsyncd) 实际上是 lua 语言封装了 `inotify` 和 `rsync` 工具，采用了 Linux 内核（2.6.13 及以后）里的 `inotify` 触发机制，然后通过 `rsync` 去差异同步，达到实时的效果。我认为它最令人称道的特性是，完美解决了 `inotify + rsync` 海量文件同步带来的文件频繁发送文件列表的问题 —— 通过时间延迟或累计触发事件次数实现。另外，它的配置方式很简单，`lua` 本身就是一种配置语言，可读性非常强。`lsyncd` 也有多种工作模式可以选择，本地目录 `cp`，本地目录 `rsync`，远程目录 `rsyncssh` 。

### lsyncd.conf 配置

编辑配置文件 `/etc/lsyncd.conf`

```bash
----
-- User configuration file for lsyncd.
--
-- Simple example for default rsync, but executing moves through on the target.
--
-- For more examples, see /usr/share/doc/lsyncd*/examples/
--
-- sync{default.rsyncssh, source="/var/www/html", host="localhost", targetdir="/tmp/htmlcopy/"}

settings {
    logfile ="/var/log/lsyncd/lsyncd.log",
    statusFile ="/var/local/lsyncd.status",
    inotifyMode = "CloseWrite",
    maxProcesses = 7,
    -- nodaemon =true,
}

sync {
    default.rsync,
    source = "/data/www/platform_admin/Uploads",
    target = "www@10.100.1.16::pu",
    rsync = {
        binary = "/usr/bin/rsync",
        archive = true,
        compress = true,
        verbose = true
    }
}
```

### 启动 lsyncd 服务

```bash
systemctl start lsyncd
systemctl enable lsyncd
```

## 测试

只需要在其中一台服务器的 `/data/www/platform_admin/Uploads` 中添加文件，然后在另一台服务器查看是否有同步过来，最后在颠倒顺序测试即可。
