# Git 服务器搭建


## 安装Git

```bash
yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel perl-devel
yum install git
```

接下来我们 创建一个 git 用户组和用户，用来运行 git 服务：

```bash
useradd -m git
```

## 创建证书登录

收集所有需要登录的用户的公钥，公钥位于id_rsa.pub文件中，把我们的公钥导入到 /home/git/.ssh/authorized_keys 文件里，一行一个。

如果没有该文件创建它：

```bash
su - git
mkdir .ssh
chmod 755 .ssh
touch .ssh/authorized_keys
chmod 644 .ssh/authorized_keys
```

## 初始化 Git 仓库

首先我们选定一个目录作为 Git 仓库，假定是 `/home/git/gitrepo/runoob.git`，在 `/home/git/gitrepo` 目录下输入命令：

```bash
mkdir gitrepo
cd gitrepo
git init --bare runoob.git
```

以上命令 `Git` 创建一个空仓库，服务器上的 `Git` 仓库通常都以 `.git` 结尾。 

> 注意: 如果你操作过程使用的用户不是 `git` 记得将目录权限改为 `git` 所有

## 克隆仓库

```bash
git clone git@192.168.45.4:gitrepo/runoob.git
```

`192.168.45.4` 为 Git 所在服务器 ip ，你需要将其修改为你自己的 `Git` 服务 `ip`

这样我们的 Git 服务器安装就完成。
