---
title: "PostgreSQL 用户授权"
date: 2022-11-13T13:35:41+08:00
draft: false
categories: 
- postgresql
tags:
- postgresql
---

postgresql 权限分为 “用户” 和 “角色” 及 “database/schema/table...属主”

**举例说明:**

用户: postgresql 中两个用户， postgres 管理用户，test 普通用户
数据库: 使用 postgres 用户，创建 testdb 数据库

```bash
postgres=# create database testdb;
CREATE DATABASE
postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 testdb    | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
(4 rows)
```

数据库创建后，会自动创建 public schema，默认情况下所有用户都拥有 “public” schema 的 "create" 权限

使用 test 用户登录，在 testdb 的 public schema 下创建表

```bash
[root@MiWiFi-R3G-srv ~]# psql -h localhost -U test -W testdb
Password:
psql (13.9)
Type "help" for help.

testdb=> create table users(id int, name varchar(64));
CREATE TABLE
testdb=> \dt
       List of relations
 Schema | Name  | Type  | Owner
--------+-------+-------+-------
 public | users | table | test
```

为了安全，我们需要加收 public 的创建权限, 使用管理用户进行权限回收

```bash
revoke CREATE on SCHEMA public from PUBLIC;
```

再次使用 test 用户创建表会发现没有权限

```bash
testdb=> create table users2(id int, name varchar(64));
ERROR:  permission denied for schema public
LINE 1: create table users2(id int, name varchar(64));
```

使用管理用户在 testdb 创建 test_schema schema, 并在此 schema 下创建一张表

```bash
testdb=# create schema test_schema;
CREATE SCHEMA
testdb=# create table test_schema.id(id int);
CREATE TABLE
# 更新 search_path，不然 \dt 查不出数据
testdb=# set search_path = "$user", public, test_schema;
SET
testdb=# \dt
           List of relations
   Schema    | Name  | Type  |  Owner
-------------+-------+-------+----------
 public      | users | table | test
 test_schema | id    | table | postgres
(2 rows)
```

正常情况下 test 用户是无法在 test_schema 下创建任何对象的, 现在将 test_schema 的属主更改为 test 用户

```bash
testdb=# alter schema test_schema owner to test;
ALTER SCHEMA
testdb=# \dn
    List of schemas
    Name     |  Owner
-------------+----------
 public      | postgres
 test_schema | test
```

现在 tets 用户可以在 test_schema 下创建对象了，尝试创建个表

```bash
testdb=> create table test_schema.test(id int);
CREATE TABLE

testdb=> \dt
           List of relations
   Schema    | Name  | Type  |  Owner
-------------+-------+-------+----------
 public      | users | table | test
 test_schema | id    | table | postgres
 test_schema | test  | table | test

testdb=> \dn
    List of schemas
    Name     |  Owner
-------------+----------
 public      | postgres
 test_schema | test
```

从上面的查询结果可以看到 id 表的属主为 `postgres` 用户，test 表的属主用户为 `test` 用户

现在尝试使用 test 用户往 id 和 test 表中插入数据及删除 id 和 test 表

```bash
testdb=> insert into test_schema.id values (1);
ERROR:  permission denied for table id
testdb=> insert into test_schema.test values (1);
INSERT 0 1

testdb=> drop table test_schema.id ;
DROP TABLE
testdb=> drop table test_schema.test ;
DROP TABLE
```

可以发现 test 用户无法在 id 表中插入数据，但可以删除 id 表，这是因为 test_schema schema的属主用户是 test

现在给 test 授于 test_schema schema 下所有表的所有权限

```bash
testdb=# grant ALL privileges on all tables in schema test_schema to test;
GRANT
```

现在 test 拥有了 test_schema 下所有表的所有权限

通过管理用户在 test_schema 下创建表并插入数据

```bash
testdb=# create table test_schema.users(id int);
CREATE TABLE
testdb=# insert into test_schema.users values(1);
INSERT 0 1
```

通过 test 查看及插入新数据

```bash
testdb=> select * from test_schema.users;
ERROR:  permission denied for table users
testdb=> insert into test_schema.users values(2);
ERROR:  permission denied for table users
```

可以发现 test 用户没有权限操作 test_schema.users 表，为什么？？？ 上面明明给 test 用户授予于所有表所有权限。

这是因为授权只针对现有的资源对象，对新创建的资源对象是不生效的，为了让 test 用户对新创建的资源也拥有相应的权限可以设置默认权限的方式, 设置语句如下：

```bash
testdb=# alter default privileges in schema test_schema grant all privileges on tables to test;
ALTER DEFAULT PRIVILEGES
```

再次通过管理用户创建资源对象，test 用户也会拥有相应的权限