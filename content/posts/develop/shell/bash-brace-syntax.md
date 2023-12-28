---
title: "Bash {} 的特殊用法"
date: 2023-12-28T10:32:00+08:00
draft: false
categories: 
- bash
tags:
- bash
---

本文主要介绍 `Bash` `{}` 的特殊用法


## 1. 输出变量的值

```bash
root@DESKTOP-Q3T526A:~# var="hello world"
root@DESKTOP-Q3T526A:~# echo ${var}
hello world
```

## 2. 设置变量默认值

1. 语法: `${var:-default}` 变量 var 没有定义或者值为空时，输出 `default`，变量的值保持不变(不会对变量进行赋值操作)

```bash
# 变量未定义时
root@DESKTOP-Q3T526A:~# echo ${var:-default}
default

# 变量值为空时
root@DESKTOP-Q3T526A:~# var=
root@DESKTOP-Q3T526A:~# echo ${var:-default2}
default2
```

2. 语法：`${var:=default}` 变量 var 没有定义或者为空时，输出 default，同时变量 var 的值被设置为 default

```bash
root@DESKTOP-Q3T526A:~# echo ${var:=default}
default
root@DESKTOP-Q3T526A:~# echo ${var}
default
```

## 3. 判断变量是否定义及非空

1. 语法: `${var+value}`  变量 var 被定义时输出 value, 未定义时输出空字符串, 变量 var 保持不变

```bash
# var 未定义时
root@DESKTOP-Q3T526A:~# echo ${var+define}

# var 定义时
root@DESKTOP-Q3T526A:~# var=
root@DESKTOP-Q3T526A:~# echo ${var+define}
define
```

2. 语法: `${var:+value}`  变量 var 被定义且非空时时输出 value, 未定义时输出空字符串, 变量 var 保持不变

```bash
# var 未定义时
root@DESKTOP-Q3T526A:~# echo ${var:+define}

# var 定义为空时
root@DESKTOP-Q3T526A:~# var=
root@DESKTOP-Q3T526A:~# echo ${var:+define}

#var 定义且非空时
root@DESKTOP-Q3T526A:~# var=1
root@DESKTOP-Q3T526A:~# echo ${var:+define}
define
```

## 4. 查看变量

语法: `${!PREFIX*}` or `${!PREFIX@}` 匹配输出所有以 `PREFIX` 开头的变量名

```bash
root@DESKTOP-Q3T526A:~# echo ${!SSH*}
SSH_CLIENT SSH_CONNECTION SSH_TTY

root@DESKTOP-Q3T526A:~# echo ${!SSH@}
SSH_CLIENT SSH_CONNECTION SSH_TTY
```

## 5. 变量嵌套（间接）引用

语法: `${!var}`  变量间接引入

```bash
root@DESKTOP-Q3T526A:~# teacher=ZhangSan
root@DESKTOP-Q3T526A:~# job=teacher
root@DESKTOP-Q3T526A:~# echo ${!job}
ZhangSan
```

> 等同于 `eval \$$`


## 6. 获取变量长度

语法: `${#var}` 返回变量字符长度

```bash
${#var}
```

## 7. 转换变量值的大小写

变量值的大小写转换，不改原变量的值

**语法:**
- `${var,,}`  将 var 的值转为小写
- `${var^^}`  将 var 的值转为大写

```bash
root@DESKTOP-Q3T526A:~# var1=HELLO
root@DESKTOP-Q3T526A:~# var2=hello
root@DESKTOP-Q3T526A:~# echo ${var1,,}
hello
root@DESKTOP-Q3T526A:~# echo ${var2^^}
HELLO
```

## 8. 变量字符截取

语法: `${var:start_position:length}` 
- start_position: 截取字符起始点，以索引 0 开始
- length：截取字符的长度

```bash
root@DESKTOP-Q3T526A:~# var2=hello
root@DESKTOP-Q3T526A:~# echo ${var2:1}
ello
root@DESKTOP-Q3T526A:~# echo ${var2:1:2}
el
```

## 9. 查找删除字符串

### 1. 从头开始查找

语法:
- `${str#substr}` : 从头开始查找匹配，删除最短匹配 substr 的子串
- `${str##substr}`: 从头开始查找匹配，删除最长匹配 substr 的子串

```bash
root@DESKTOP-Q3T526A:~# str="/usr/local/src"
# 删除最短匹配
root@DESKTOP-Q3T526A:~# echo ${str#/*/}
local/src
# 删除最长匹配
root@DESKTOP-Q3T526A:~# echo ${str##/*/}
src
```

### 2. 从尾部开始查找

- `${str%substr}` : 从尾部开始查找匹配，删除最短匹配 substr 的子串
- `${str%%substr}`: 从尾部开始查找匹配，删除最长匹配 substr 的子串

```bash
root@DESKTOP-Q3T526A:~# str="/usr/local/src/"
# 删除最短匹配
root@DESKTOP-Q3T526A:~# echo ${str%*/}
/usr/local/src
# 删除最长匹配
root@DESKTOP-Q3T526A:~# echo ${str%%*/}
# 没有输出,删除了所有匹配的字符
```

## 10. 字符串替换

**语法:**
- `${str/substr/replace}`   使用 replace 替换第一个匹配 substr 的字符串
- `${str//substr/replace}`  使用 replace 替换所有匹配 substr 的字符串

```bash
root@DESKTOP-Q3T526A:~# str="/usr/local/src/test/src"
# 替换第一个
root@DESKTOP-Q3T526A:~# echo ${str/src/bin}
/usr/local/bin/test/src
# 替换所有
root@DESKTOP-Q3T526A:~# echo ${str//src/bin}
/usr/local/bin/test/bin
```

**语法:**
- `${str/#substr/replace}`  以 substr 字符开头时，使用 replace 替换一次匹配的 substr 的字符串
- `${str/%substr/replace}`  以 substr 字符结尾时，使用 replace 替换一次匹配的 substr 的字符串

```bash
root@DESKTOP-Q3T526A:~# str="hello world, hello welcome, he"
root@DESKTOP-Q3T526A:~# echo ${str/#he/ha}
hallo world, hello welcome, he
root@DESKTOP-Q3T526A:~# echo ${str/%he/ha}
hello world, hello welcome, ha
```

