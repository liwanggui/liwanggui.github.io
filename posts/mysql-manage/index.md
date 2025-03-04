# MySQL 基础管理命令


##  一、用户权限管理

### 1. 查看帮助信息

使用 mysql 命令连接上 MySQL 服务后可以使用 help 命令查看帮助信息，例如:

```
mysql> help
For information about MySQL products and services, visit:
   http://www.mysql.com/
For developer information, including the MySQL Reference Manual, visit:
   http://dev.mysql.com/
To buy MySQL Enterprise support, training, or other products, visit:
   https://shop.mysql.com/

List of all MySQL commands:
Note that all text commands must be first on line and end with ';'
?         (\?) Synonym for `help'.
clear     (\c) Clear the current input statement.
connect   (\r) Reconnect to the server. Optional arguments are db and host.
delimiter (\d) Set statement delimiter.
edit      (\e) Edit command with $EDITOR.
ego       (\G) Send command to mysql server, display result vertically.
exit      (\q) Exit mysql. Same as quit.
go        (\g) Send command to mysql server.
help      (\h) Display this help.
nopager   (\n) Disable pager, print to stdout.
notee     (\t) Don't write into outfile.
pager     (\P) Set PAGER [to_pager]. Print the query results via PAGER.
print     (\p) Print current command.
prompt    (\R) Change your mysql prompt.
quit      (\q) Quit mysql.
rehash    (\#) Rebuild completion hash.
source    (\.) Execute an SQL script file. Takes a file name as an argument.
status    (\s) Get status information from the server.
system    (\!) Execute a system shell command.
tee       (\T) Set outfile [to_outfile]. Append everything into given outfile.
use       (\u) Use another database. Takes database name as argument.
charset   (\C) Switch to another charset. Might be needed for processing binlog with multi-byte charsets.
warnings  (\W) Show warnings after every statement.
nowarning (\w) Don't show warnings after every statement.
resetconnection(\x) Clean session context.

For server side help, type 'help contents'
```

**例如查看 select 语句的用法**

可以使用 `help select；` 命令查看帮助信息

```
mysql> help select;
Name: 'SELECT'
Description:
Syntax:
SELECT
    [ALL | DISTINCT | DISTINCTROW ]
      [HIGH_PRIORITY]
      [STRAIGHT_JOIN]
      [SQL_SMALL_RESULT] [SQL_BIG_RESULT] [SQL_BUFFER_RESULT]
      [SQL_CACHE | SQL_NO_CACHE] [SQL_CALC_FOUND_ROWS]
    select_expr [, select_expr ...]
    [FROM table_references
      [PARTITION partition_list]
    [WHERE where_condition]
    [GROUP BY {col_name | expr | position}
      [ASC | DESC], ... [WITH ROLLUP]]
    [HAVING where_condition]
    [ORDER BY {col_name | expr | position}
      [ASC | DESC], ...]
    [LIMIT {[offset,] row_count | row_count OFFSET offset}]
    [PROCEDURE procedure_name(argument_list)]
    [INTO OUTFILE 'file_name'
        [CHARACTER SET charset_name]
        export_options
      | INTO DUMPFILE 'file_name'
      | INTO var_name [, var_name]]
    [FOR UPDATE | LOCK IN SHARE MODE]]

SELECT is used to retrieve rows selected from one or more tables, and
can include UNION statements and subqueries. See [HELP UNION], and
https://dev.mysql.com/doc/refman/5.7/en/subqueries.html.

The most commonly used clauses of SELECT statements are these:

o Each select_expr indicates a column that you want to retrieve. There
  must be at least one select_expr.

o table_references indicates the table or tables from which to retrieve
  rows. Its syntax is described in [HELP JOIN].

o SELECT supports explicit partition selection using the PARTITION with
  a list of partitions or subpartitions (or both) following the name of
  the table in a table_reference (see [HELP JOIN]). In this case, rows
  are selected only from the partitions listed, and any other
  partitions of the table are ignored. For more information and
  examples, see
  https://dev.mysql.com/doc/refman/5.7/en/partitioning-selection.html.

  SELECT ... PARTITION from tables using storage engines such as MyISAM
  that perform table-level locks (and thus partition locks) lock only
  the partitions or subpartitions named by the PARTITION option.

  For more information, see
  https://dev.mysql.com/doc/refman/5.7/en/partitioning-limitations-lock
  ing.html.

o The WHERE clause, if given, indicates the condition or conditions
  that rows must satisfy to be selected. where_condition is an
  expression that evaluates to true for each row to be selected. The
  statement selects all rows if there is no WHERE clause.

  In the WHERE expression, you can use any of the functions and
  operators that MySQL supports, except for aggregate (summary)
  functions. See
  https://dev.mysql.com/doc/refman/5.7/en/expressions.html, and
  https://dev.mysql.com/doc/refman/5.7/en/functions.html.

SELECT can also be used to retrieve rows computed without reference to
any table.

URL: https://dev.mysql.com/doc/refman/5.7/en/select.html
```

### 2. 用户创建

```
# 创建用户（默认密码为空）
mysql> create user 'username'@'host';

# 创建用户并设置密码
mysql> create user 'username'@'host' identified by 'password';
```

### 3. 删除用户

```
mysql> drop user 'username'@'host';
```

### 4. 更改密码

```
# 更改密码 （只对当前登录账号有效）
mysql> set password=password('123456');

# 2. 更改指定用户的密码
mysql> set password for 'username'@'host'=password('123456');
```

### 5. 查询用户权限

```
# 查询当前账号的权限
mysql> show grants;

# 查询指定账号的权限
mysql> show grants for 'user'@'host';
```

### 6. 用户授权

```
# 对用户授权（如果用户存在就增加权限，不存在就创建用户不过密码为空）
mysql> grant privileges on databasename.tablename to 'username'@'host';

# 对用户授权并设置密码（如果用户存在就增加权限，不存在就创建用户）
# mysql 8.0 版本以后需要先创建用户在授权
mysql> grant privileges on databasename.tablename 
    -> to 'username'@'host' identified by 'password';
```

> privileges: 权限列表以逗号隔开，例如： `select, insert, update` <br />
> 注意: 进行数据库基本信息相关更改后请使用 `flush privileges;` 刷新数据库信息

### 7. 用户权限回收

```
mysql> revoke privilege on databasename.tablename from 'user'@'host';
```

> 注：数据库名要用反撇号引起，或者不用


## 二、数据库

### 1. 数据库的基本操作

```
# 显示数据库
mysql> show databases;

# 创建数据库
mysql> create database DATABASENAME charset utf8mb4;;

# 查看数据库创建语句
mysql> show create database DATABASENAME;

# 删除数据库
mysql> drop database DATABASENAME;
```

### 2. 备份数据库数据及表结构

```
# 备份整个数据库
[root@localhost ~]# mysqldump -uroot -p -A > all.sql

# 备份整个数据库的结构
[root@localhost ~]# mysqldump -uroot -p -A -d > all.sql

# 备份单个数据库
[root@localhost ~]# mysqldump -uroot -p DATABASENAME > DATABASENAME.sql

# 一次备份多个数据库, 同时备份 db1, db2 二个库的数据 (-B, --databases)
[root@localhost ~]# mysqldump -uroot -p --databases db1 db2 > dbs.sql

# 备份数据库中指定的表
[root@localhost ~]# mysqldump -uroot -p DATABASENAME TABLENAME > DATABASENAME_TABLENAME.sql

# 一次备份数据库中指定的多张表
[root@localhost ~]# mysqldump -uroot -p DATABASENAME t1 t2 > DATABASENAME_ts.sql
```

- `-B, --databases`: 单库备份可以加上 `-B` 参数，这样备份文件中加会加入 `create database ...` 及 `use DATABASE` 语句.
- `-A`, `--all-databases` : 备份所有数据库
- `-d`, `--no-data` ：只导出表结构

### 3. 导出函数或者存储过程

```
mysqldump -hHOSTNAME -uUSERNAME -pPASSWORD -ntd -R DATABASENAME > DATABASENAME.sql
```

- `-ntd` 是表示导出存储过程；
- `-R` 是表示导出函数

### 4. 恢复数据库数据

** 使用系统命令**

```bash
[root@localhost ~]# mysql -uroot DATABASENAME < DATABASENAME.sql
```

**使用 source 命令**

```
# 禁止记录 binlog 日志，恢复数据就没必要记录 binlog 了
mysql> set sql_log_bin=0
mysql> use lwg;
mysql> source /root/lwg.sql;
```

> 注意: 恢复数据时，如果数据库不存在需要先创建

## 三、数据表

### 1. 表的基本操作

```
# 查看数据库下所有的表
mysql> show tables;

# 创建表
mysql> CREATE TABLE `TABLENAME` (
  `id` int(10) NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `user` varchar(30) NOT NULL,
  `password` varchar(30) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

# 显示表结构
mysql> desc TABLENAME;

# 显示表创建语句
mysql> show create table TABLENAME;

# 清空表数据
mysql> truncate table TABLENAME;
mysql> delete from TABLENAME;
```

> 不带 `where` 参数的 `delete` 语句可以删除 `mysql` 表中所有内容 <br />
> 使用 `truncate table` 也可以清空 `mysql` 表中所有内容。 <br />
> 效率上 `truncate` 比 `delete` 快，但 `truncate` 删除后不记录 `mysql` 日志，不可以恢复数据。 <br />
> `delete` 的效果有点像将 `mysql` 表中所有记录一条一条删除到删完， <br />
> 而 `truncate` 相当于保留 `mysql` 表的结构，重新创建了这个表，所有的状态都相当于新表。 <br />
> 所以 `delete` 不会重置 ID 列，而 `truncat` 会重置。 <br />
> `delete` 删除是逻辑上的删除，并不会真正的释放硬盘空间，而 `truncat` 是物理上的删除操作会真正的释放硬盘空间 <br />

### 2. 表 `alter` 的相关操作

```
# 增加一个字段(一列),并放到第一列的位置 (first)
mysql> desc users;
+------------+----------+------+-----+---------+-------+
| Field      | Type     | Null | Key | Default | Extra |
+------------+----------+------+-----+---------+-------+
| username   | char(30) | NO   | PRI | NULL    |       |
| userpasswd | char(20) | NO   |     | 123456  |       |
+------------+----------+------+-----+---------+-------+
2 rows in set (0.00 sec)

mysql> alter table users add column id int not null first;
Query OK, 0 rows affected (0.08 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> desc users;
+------------+----------+------+-----+---------+-------+
| Field      | Type     | Null | Key | Default | Extra |
+------------+----------+------+-----+---------+-------+
| id         | int(11)  | NO   |     | NULL    |       |
| username   | char(30) | NO   | PRI | NULL    |       |
| userpasswd | char(20) | NO   |     | 123456  |       |
+------------+----------+------+-----+---------+-------+
3 rows in set (0.00 sec)

# 删除一个字段
mysql> alter table users drop userpasswd;
Query OK, 0 rows affected (0.05 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> desc users;
+----------+----------+------+-----+---------+-------+
| Field    | Type     | Null | Key | Default | Extra |
+----------+----------+------+-----+---------+-------+
| id       | int(11)  | NO   |     | NULL    |       |
| username | char(30) | NO   | PRI | NULL    |       |
+----------+----------+------+-----+---------+-------+
2 rows in set (0.00 sec)

# 更改列的字段类型
mysql> alter table users modify username varchar(100);
Query OK, 2 rows affected (0.14 sec)
Records: 2  Duplicates: 0  Warnings: 0

mysql> desc users;
+----------+--------------+------+-----+---------+-------+
| Field    | Type         | Null | Key | Default | Extra |
+----------+--------------+------+-----+---------+-------+
| id       | int(11)      | NO   |     | NULL    |       |
| username | varchar(100) | NO   | PRI |         |       |
+----------+--------------+------+-----+---------+-------+
2 rows in set (0.00 sec)

# 更改列名及字段类型
mysql> alter table users change username user varchar(20);
Query OK, 2 rows affected (0.03 sec)
Records: 2  Duplicates: 0  Warnings: 0

mysql> desc users;
+-------+-------------+------+-----+---------+-------+
| Field | Type        | Null | Key | Default | Extra |
+-------+-------------+------+-----+---------+-------+
| id    | int(11)     | NO   |     | NULL    |       |
| user  | varchar(20) | NO   | PRI |         |       |
+-------+-------------+------+-----+---------+-------+
2 rows in set (0.00 sec)

# 修改表的存储引擎
mysql> show create table users;
+-------+---------------------------------------+
| Table | Create Table                          |
+-------+---------------------------------------+
| users | CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `user` varchar(20) NOT NULL DEFAULT '',
  PRIMARY KEY (`user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 |
+-------+---------------------------------------+
1 row in set (0.00 sec)

mysql> alter table users ENGINE=myisam;
Query OK, 2 rows affected (0.01 sec)
Records: 2  Duplicates: 0  Warnings: 0

# 这里我们使用另一种方法查询表的默认引擎
mysql> show table status from lwg where name='users'\G
*************************** 1. row ***************************
           Name: users
         Engine: MyISAM
        Version: 10
     Row_format: Dynamic
           Rows: 2
 Avg_row_length: 20
    Data_length: 40
Max_data_length: 281474976710655
   Index_length: 2048
      Data_free: 0
 Auto_increment: NULL
    Create_time: 2017-08-25 04:15:46
    Update_time: 2017-08-25 04:15:46
     Check_time: NULL
      Collation: utf8_general_ci
       Checksum: NULL
 Create_options:
        Comment:
1 row in set (0.00 sec)
```
