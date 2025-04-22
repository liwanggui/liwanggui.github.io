# MySQL 主从复制优化


## 优化参数

```ini
[mysqld]
# 从库配置优化
master_info_repository = TABLE
relay_log_info_repository = TABLE
relay_log_recovery = 1
relay-log-purge = 1
read_only = 1
super_read_only = 1
```

- master.info: 存储连接主库的信息，已经接收的 binlog 位置点信息 (默认在从库数据目录中)

配置项: `master_info_repository = FILE/TABLE`

`master_info_repository` 默认值为 FILE 存储文件名为 `master.info`，值为改为 TABLE 时 `master.info` 信息将存储在表中，可以提高性能

- relay-log.info: 记录从库回放 relay-log 位置点 (默认在从库数据目录中)

配置项: `relay_log_info_repository = FILE/TABLE`

`relay_log_info_repository` 默认值为 FILE 存储文件名为 `relay-log.info`，值为改为 TABLE 时 `relay-log.info` 信息将存储在表中，可以提高性能

- relay_log_purge: 自动清理 `relay-log` 文件
- read_only: 禁止写操作，从库配置可以防止误写操作
- super_read_only: 禁止管理员写操作，从库配置可以防止误写操作
