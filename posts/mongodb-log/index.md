# Mongodb 日志切割


MongoDB 默认是不会进行切割日志的，除非我们配置了 logRotate = rename，并且重启 MongoDB 服务，才会进行切割日志的，那么为了避免实际中我们一个日志文件过大，我们需要对日志进行切割，可使用以下办法：

## 通过 MongoDB 管理命令进行切割

使用该命令时需要在 MongoDB 运行时指定日志文件路径。--logpath [file] ，或者在配置文件中指定。

```
use admin
db.runCommand({logRotate:1})
```

## 通过向进程发送 SIGUSR1 信号来切割日志

如果我们的进程 id 是 19555，那么我们可以通过以下命令来切割日志的。
只要我们执行了该命令，日志就会立即进行切割。

```bash
kill -SIGUSR1 19555
```

## 通过 Linux 系统自带的服务 logrotate 进行切割

首先我们需要配置 MongoDB 参数 `logRotate = reopen`， `logappend = true`，然后通过 Linux 系统自带的 logrotate。
配置文件放置在 `/etc/logrotate.d/`, 切割配置文件示例：

```
/var/log/mongo/*.log {
    rotate 180  
    daily
    size 100M
    olddir /var/log/mongo/oldlog
    copytruncate
    dateext
    compress
    notifempty
    missingok
}
```
