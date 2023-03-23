---
title: "Bash - while read 问题"
date: 2022-01-06T15:22:08+08:00
draft: false
categories: 
- bash
tags:
- while
---

## 问题: while read line 无法读取最后一行

使用 shell 脚本读取文本文件时，发现无法读取到最后一行，通过使用 hexdump 查看文件内容, 发文件结尾没有 `\n`

```bash
$ hexdump -c iccids.csv
0000000   8   9   8   6   0   6   5   3   9   8   7   5   9   8   7   6
0000010   5   3   2   2  \n   8   9   8   6   0   6   2   1   2   5   0
0000020   0   2   5   4   9   0   0   6   2  \n   8   9   8   6   0   4
0000030   A   4   1   9   2   1   8   1   6   7   3   6   2   5  \n   8
0000040   9   8   6   0   6   2   0   1   6   0   0   0   2   3   5   7
0000050   5   5   9  \n   8   9   8   6   0   6   2   0   1   8   0   0
0000060   2   3   3   7   6   3   8   8
0000068
```

shell脚本源码如下：

```bash
while read line; do
        echo $line
done < iccids.csv
```


**解决方案**

*方案一*

在利用 while read line 读取文件时：

如果文件最后一行之后没有换行符 `\n`，则 read 读取最后一行时遇到文件结束符 `EOF`，循环即终止。

虽然，此时 `$line` 内存有最后一行，但程序已经没有机会再处理此行内容。因此导致了这个问题发生。

解决方案如下：

```bash
while read line || [[ -n ${line} ]]
```

> 这样当文件没有到最后一行时不会测试 `[[ -n ${line} ]]` ，当遇到文件结束（最后一行）时，仍然可以通过测试 `$line` 是否有内容来进行继续处理。

上例子代码如下改进：

```bash
while read iicd || [[ -n $iicd ]]; do
        echo $iicd
done < iccids.csv
```

*方案二*

通过分析原因可知，本质原因是因为文件格式不是 unix 导致的，也可以直接通过设置文件格式来处理。 如这样处理，脚本代码不需改动。

## 问题: while 循环中 read 命令无效问题

*解决 while 循环中 read 命令无效问题, 代码如下:*

```bash
while read ip; do
    echo $ip
    read -p "pause..."
done < ip.list
```

> 运行程序时你会发现他根本不会等待你输入，就直接完成了，原因是两个 read 读取了同一个标准输入

*解决方法：*

将 read 的标准输入变更成其它文件描述符就行了，这样两个 read 就错开了

```bash
while read -u 5 ip; do
    echo $ip
    read -p "pause..."
done 5< ip.list
```

> 注意: `5<` 之间不能有空格

