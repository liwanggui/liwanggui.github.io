# MySQL 慢日志


## slowlog 慢日志

### 作用

记录 MySQL 运行过程运行过慢的语句，通过一个文本的文件记录下来。
帮助我们进行语句优化工作。

### 配置慢日志

```bash
root@db1:~# cat /usr/local/mysql/etc/my.cnf
[mysqld]
# 慢语句开关
slow_query_log = 1
# 慢日志存储路径
slow_query_log_file = /data/mysql/3306/slow.log
# 定义慢语句时间阈值单位为秒
long_query_time = 1 
# 记录不走索引的语句
log_queries_not_using_indexes = 1
```

## 查看慢日志

### mysqldumpslow 参数说明

```bash
root@db1:~# mysqldumpslow -h
-s ORDER  日志排序方式, 默认排序为 'at'
            al: 平均锁定时间
            ar: 发送的平均行数
            at: 平均查询时间
             c: 执行次数
             l: 锁定时间
             r: 发送行数
             t: 查询时间
-r           反向排序
-t NUM       只显示前n个查询
```

*查看执行次数最多的前5条慢语句*

```bash
root@db1:~# mysqldumpslow -s c -t 5 /data/mysql/3306/slow.log
```

### 可视化展示慢日志 slow-log

工具: pt-query-digest + Amemometer
