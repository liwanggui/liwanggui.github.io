# SSH 密钥对的使用过程


Linux 默认使用密码登录，很不安全容易被暴力破解入侵。使用密钥登录可以增加安全性。下面将介绍如何配置密钥登录验证.

## 生成 ssh 密钥对

首先我们需要在自己的电脑上生成密钥对(公私钥)

### Linux

由于 linux 和 macOS 自带 ssh 软件和终端，直接打开终端输入以下输入命令生成密钥对

```bash
[root@singhead ~]# ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
15:a5:d1:4c:bc:dd:fa:0f:78:18:f6:78:4d:04:77:95 root@singhead
The key's randomart image is:
+--[ RSA 2048]----+
| o*o . *|
| ++ E.|
| o o ..|
| . . ...|
| S o ..|
| . *.o |
| + =..|
| o ..|
| o|
+-----------------+
[root@singhead .ssh]# ls -l
total 12
-rw------- 1 root root 1671 Oct 2 00:04 id_rsa
-rw-r--r-- 1 root root 395 Oct 2 00:04 id_rsa.pub
```

### Windows 

由于 Windows 环境问题，我们需要借助于 GitBash 这个工具来生成密钥对，如果你有使用终端管理工具（例如 Xshell, SecureCRT 等）也可以使用终端管理工具生成。

这里只介绍如何使用 GitBash 生成密钥的操作过程

下载安装 Git: [https://gitforwindows.org/](https://gitforwindows.org/)

安装完成后，会有一个 GitBash 的终端可用，我们就用这个来操作

打开 `GitBash` 输入以下命令, 一路按 `Enter` 键即可完成，密钥对的生成，密钥默认存放 `C:\Users\<你的用户名>\.ssh` 目录下

```bash
ssh-keygen -t rsa
```

> 不管那个系统平台使用的命令都是一样的

## 推送公钥文件到 linux 服务器中

```bash
[root@singhead ~]# cd .ssh/
[root@singhead .ssh]# ssh-copy-id -i id_rsa.pub root@192.168.1.20
[root@singhead .ssh]# ssh-copy-id -i id_rsa.pub root@192.168.1.21
```

> Tips: 以上命令将公钥添加至主机的 `/root/.ssh/authorized_keys` 文件中

## 配置 ssh 

调整 linux 服务器设置,禁用密码验证，启用密钥验证对验证，并重启 SSH 服务

```bash
[root@singhead ~]# vim /etc/ssh/sshd_config
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
[root@singhead ~]# service sshd restart
```
