---
title: "Mongodb 用户和权限管理"
date: "2021-02-05T09:27:29+08:00"
draft: false
categories:
- mongodb
tags:
- mongodb
---

## 什么是验证库？

验证库是`建立用户时 use 到的库`，在使用用户时，要加上验证库才能登陆。
对于管理员用户, 必须在 admin 下创建(先 use admin，再创建管理员用户)。

*需要注意点*

1. 建用户时, use 到的库, 就是此用户的验证库
2. 登录时,必须明确指定验证库才能登录
3. 通常,管理员用的验证库是 admin, 普通用户的验证库一般是所管理的库设置为验证库
4. 如果直接登录到数据库,不进行 use, 默认的验证库是 test, 不是我们生产建议的.
5. 从 3.6 版本开始，不添加 bindIp 参数，默认不让远程登录，只能本地管理员登录。

## 创建用户并赋于权限

**创建管理员用户**

```bash
> use admin 
> db.createUser(
{
    user: "root",
    pwd: "root123",
    roles: [
       { role: "root", db: "admin" }
    ]
})
```

**基本语法说明**

- user: 用户名
- pwd: 用户密码
- roles:
  - role: 角色名，常用角色名(`root`, `readWrite`,`read`)
  - db: 作用的库对象

**查看所有 roles 指令**

```javascript
use admin
show roles
```

## 启用 mongodb 用户验证

**在 `/etc/mongod.conf` 配置文件中加入以下配置以启用用户验证功能, 然后重启 MongoDB 服务**

```yaml
security:
  authorization: enabled
```

**测试连接**

```bash
mongo -u root -p root123 127.0.0.1/admin
```

**查看用户信息**

```bash
> use admin  # 先 use 到验证库
switched to db admin
> db.system.users.find().pretty()
{
	"_id" : "admin.root",
	"userId" : UUID("6bf7b26e-e41b-46a3-8d28-fb6b793ba1b7"),
	"user" : "root",
	"db" : "admin",
	"credentials" : {
		"SCRAM-SHA-1" : {
			"iterationCount" : 10000,
			"salt" : "aViob5trN+4saa+6/5Uiow==",
			"storedKey" : "6tAnFjGMtn5hamEbrioIS3eTydY=",
			"serverKey" : "iORLUz6Ay2alLzz6Z7YevOJzdIs="
		}
	},
	"roles" : [
		{
			"role" : "root",
			"db" : "admin"
		}
	]
}
```

## 删除用户

### 创建测试用户

```bash
> use test
switched to db test
> db.createUser({user: "test",pwd: "test123",roles: [ { role: "readWrite" , db: "test" }]})
Successfully added user: {
	"user" : "test",
	"roles" : [
		{
			"role" : "readWrite",
			"db" : "test"
		}
	]
}
```

### 删除用户

**查看所有用户**

```bash
> use admin
switched to db admin
> db.system.users.find().pretty()
{
	"_id" : "admin.root",
	"userId" : UUID("6bf7b26e-e41b-46a3-8d28-fb6b793ba1b7"),
	"user" : "root",
	"db" : "admin",
	"credentials" : {
		"SCRAM-SHA-1" : {
			"iterationCount" : 10000,
			"salt" : "aViob5trN+4saa+6/5Uiow==",
			"storedKey" : "6tAnFjGMtn5hamEbrioIS3eTydY=",
			"serverKey" : "iORLUz6Ay2alLzz6Z7YevOJzdIs="
		}
	},
	"roles" : [
		{
			"role" : "root",
			"db" : "admin"
		}
	]
}
{
	"_id" : "test.test",
	"userId" : UUID("505db884-397e-4eee-a050-2dab9a6dc500"),
	"user" : "test",
	"db" : "test",
	"credentials" : {
		"SCRAM-SHA-1" : {
			"iterationCount" : 10000,
			"salt" : "P0mVJ7NqhnXkzzXyWEfQFw==",
			"storedKey" : "JOjf0Xya+cOKTKuGCki7J7f7GNI=",
			"serverKey" : "TQLjC7FQabHjrZOtWuxIFv8kfZg="
		}
	},
	"roles" : [
		{
			"role" : "readWrite",
			"db" : "test"
		}
	]
}
```

**删除用户**

删除用户时需要先 use 到此用户的验证库，再执行删除命令

```bash
# 切换到 test 用户的验证库 test 库，删除 test 用户
> use test;
switched to db test
> db.dropUser('test')
true

# 切换到 admin 库查看所有用户
> use admin;
switched to db admin
> db.system.users.find()
{ "_id" : "admin.root", "userId" : UUID("6bf7b26e-e41b-46a3-8d28-fb6b793ba1b7"), "user" : "root", "db" : "admin", "credentials" : { "SCRAM-SHA-1" : { "iterationCount" : 10000, "salt" : "aViob5trN+4saa+6/5Uiow==", "storedKey" : "6tAnFjGMtn5hamEbrioIS3eTydY=", "serverKey" : "iORLUz6Ay2alLzz6Z7YevOJzdIs=" } }, "roles" : [ { "role" : "root", "db" : "admin" } ] }
```