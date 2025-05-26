# MySQL root 密码重置


## 适用于 `MySQL5.6` 及之前的版本

### 1. 停止MySQL服务

执行： `/etc/init.d/mysql stop`，你的机器上不一定是 `/etc/init.d/mysql` 也可能是 `/etc/init.d/mysqld`

### 2. 跳过验证启动MySQL

```
/usr/local/mysql/bin/mysqld_safe --skip-grant-tables >/dev/null 2>&1 &
```

> 注：如果 `mysqld_safe` 命令所在的路径和上面不一样需要修改成你的，如果不清楚可以用find命令查找。

### 3. 重置密码

1. 等一会儿，然后执行： `/usr/local/mysql/bin/mysql -u root`
2. 出现mysql提示符后输入：`update mysql.user set password=password('要设置的密码') where user='root'`;
3. 回车后执行：`flush privileges;` 刷新 `MySQL` 系统权限相关的表。再执行：`exit`;  退出。

### 4. 重启MySQL

1. 杀死 MySQL 进程： `killall mysqld`
2. 重启 MySQL： `/etc/init.d/mysql start`

## MySQL5.7 重置 root 密码

*编辑 `my.cnf` 文件加入以下配置*

```
[mysqld]
skip-grant-tables
```

重启 mysql，正常连接 mysql 使用如下命令修改 root 密码

```sql
update mysql.user set authentication_string=PASSWORD('123456') where user='root';
flush privilegs;
```

最后在去除 `my.cnf` 配置文件中的 `skip-grant-tables` 配置项,重启 mysql 即可。
