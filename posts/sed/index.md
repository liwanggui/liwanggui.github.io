# Linux 文本三剑客：sed


## 基本语法

格式

```bash
sed [option]... 'script' inputfile...
```

常用选项：

- `-n`: 不输出模式空间内容到屏幕，即不自动打印
- `-e`: 多点编辑
- `-f`: 从指定的文件中读取编辑脚本
- `-r`: 支持扩展正则表达式
- `-i.bak`: 备份文件并原处编辑 (.bak 字符是自定义的)

## 示例

*打印文件的最后一行*

```bash
sed -n '$p' /etc/passwd
```

> `$` 表示最后一行

*打印第2行及以下4行*

```bash
seq 10 | sed -n '2,+4p'
```

*打印第2行到第4行*

```bash
seq 10 | sed -n '2,4p'
```

*查找文件中指定字符串行*

```bash
sed -n '/^auth/p' /etc/pam.d/su
```

> 判断 `/etc/pam.d/su` 文件中是否有 `auth    required    pam_securetty.so` 配置行

*修改行*

```bash
sed -i.bak 's/PermitRoot*/PermitRoot no/g' /etc/ssh/sshd_config 
```

> -i.bak 在修改文件时会先备份，本例备份文件名为 sshd_config.bak

*删除行*

```bash
sed -i '/^PATH/d' /etc/profile
```

