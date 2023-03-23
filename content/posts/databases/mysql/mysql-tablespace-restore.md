---
title: MySQL 表空间方式(迁移/恢复)数据
date: "2021-01-05T10:15:20+08:00"
draft: false
categories:
- mysql
tags:
- mysql
---

MyISAM 引擎默认是支持通过拷贝文件方式迁移数据，InnoDB 引擎不支持。
如果需要迁移 InnoDB 引擎数据可以先将数据表的引擎由 InnoDB 更改为 MyISAM。
也可以通过管理 MySQL 独立表空间文件实现数据库的迁移。操作步骤如下:

## 准备测试数据 

可以使用 MySQL 官方提供的测试数据进行实验演示:  https://github.com/datacharmer/test_db

```bash 
git clone https://github.com/datacharmer/test_db.git
cd test_db
mysql -t < employees.sql
```

## 导出库中所有表结构

```bash
[root@10-13-90-34 ~]# mysqldump -d -B employees > employees_schema.sql
```

## 在目标数据库中创建与源库一样的表文件

```bash
[root@10-13-90-34 ~]# mysql -S /data/mysql/3308/mysql.sock
mysql> source employees_schema.sql;
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| employees          |
| mysql              |
| performance_schema |
| sys                |
+--------------------+

```
## 管理表空间文件，恢复数据

**删除表空间文件**

删除表空间文件时可能会由于外键约束导致失败，可以先暂时关闭外键约束 `SET foreign_key_checks = 0;`, 操作完成后在开启 `SET foreign_key_checks = 1;`

```bash
alter table employees.departments discard tablespace;
alter table employees.dept_emp discard tablespace;
alter table employees.dept_manager discard tablespace;
alter table employees.employees discard tablespace;
alter table employees.salaries discard tablespace;
alter table employees.titles discard tablespace;
```

**导入表空间文件**

将源库中所有表的 idb 文件拷贝到目标库中并修改权限

```bash
[root@10-13-90-34 employees]# cp -p /data/mysql/3306/employees/*.ibd /data/mysql/3308/employees
```

*导入表空间文件*

```bash
alter table employees.departments import tablespace;
alter table employees.dept_emp import tablespace;
alter table employees.dept_manager import tablespace;
alter table employees.employees import tablespace;
alter table employees.salaries import tablespace;
alter table employees.titles import tablespace;
```

*开启外键约束*

```
SET foreign_key_checks = 1;
```

*验证数据*

> 注意: 此方法操作有风险，不到万不得已不建议使用