# MySQL mysqlbinlog 命令使用说明


## mysqlbinlog 参数说明

- `-d, --database`  指定截取日志的库名

- `--start-position` 截取日志起始 position 号
- `--stop-position`  截取日志最终 position 号

- `--start-datetime`  截取日志开始时间
- `--stop-datetime`   截取日志结束时间

- `--skip-gtids` 不保留全局事务标识符； 而是让服务器像执行新事务一样执行事务。 
- `--include-gtids=name`  截取日志起始和结束 GTID 号，例如: 09833d3f-4656-11eb-9892-000c2913c78e:1-4
- `--exclude-gtids=name`  截取日志排除的 GTID 号

> 注: <br />
> --skip-gtids 在启用 GTID 时需要加上，否则数据无法通过导出的 sql 还原, 这是由于 GTID 的特性（幂等性）导致的。<br />
> 截取标志可以混用，也可以只指定起始位置点，不指定结束位置点(默认到最新的点)


## 通过 BINLOG 恢复数据

BINLOG 一般配合备份一起使用，单独使用 BINLOG 恢复数据在数据量大的情况比较困难。
