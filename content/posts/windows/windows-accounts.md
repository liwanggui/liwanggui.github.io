---
title: "Windows 本地用户密码过期策略设置"
date: 2024-01-25T17:11:00+08:00
draft: false
categories: 
- windows
tags:
- cmd
---

配置 Windows 家庭版 本地用户，密码到期策略为 “永不过期”

## 添加用户
```cmd
# net user test 123456 /add
```

## 查看本地账户默认过期时间

默认到期时间为 42 天

```cmd
# net accounts
强制用户在时间到期之后多久必须注销?:     从不
密码最短使用期限(天):                    0
密码最长使用期限(天):                    42
密码长度最小值:                          0
保持的密码历史记录长度:                  None
锁定阈值:                                从不
锁定持续时间(分):                        30
锁定观测窗口(分):                        30
计算机角色:                              WORKSTATION
```

## 查看具体用户 test，默认创建 42 天后到期


```cmd
# net user test
用户名                 test
全名
注释
用户的注释
国家/地区代码          000 (系统默认值)
帐户启用               Yes
帐户到期               从不

上次设置密码           2024/1/25 星期四 17:13:55
密码到期               2024/3/7 星期四 17:13:55
密码可更改             2024/1/25 星期四 17:13:55
需要密码               Yes
用户可以更改密码       Yes

允许的工作站           All
登录脚本
用户配置文件
主目录
上次登录               从不

可允许的登录小时数     All

本地组成员             *Users
全局组成员             *None
```

## 设置用户 test 密码策略为永不过期

```cmd
# wmic useraccount where "Name="test"" set PasswordExpires=false
正在更新“\\DESKTOP-Q3T526A\ROOT\CIMV2:Win32_UserAccount.Domain="DESKTOP-Q3T526A",Name="test"”的属性
属性更新成功。
```

## 查看具体用户 test，密码到期时间 

“帐户到期” 已设置为 “从不”

```cmd
# net user test
用户名                 test
全名
注释
用户的注释
国家/地区代码          000 (系统默认值)
帐户启用               Yes
帐户到期               从不

上次设置密码           2024/1/25 星期四 17:13:55
密码到期               从不
密码可更改             2024/1/25 星期四 17:13:55
需要密码               Yes
用户可以更改密码       Yes

允许的工作站           All
登录脚本
用户配置文件
主目录
上次登录               从不

可允许的登录小时数     All

本地组成员             *Users
全局组成员             *None
```

## 设置系统策略中默认密码最长时间为无限制

```cmd
# net accounts /maxpwage:unlimited
```

## 查看本地账户默认过期时间

“密码最长使用期限(天)” 已设置为 “Unlimited”

```cmd
# net accounts
强制用户在时间到期之后多久必须注销?:     从不
密码最短使用期限(天):                    0
密码最长使用期限(天):                    Unlimited
密码长度最小值:                          0
保持的密码历史记录长度:                  None
锁定阈值:                                从不
锁定持续时间(分):                        30
锁定观测窗口(分):                        30
计算机角色:                              WORKSTATION
```
