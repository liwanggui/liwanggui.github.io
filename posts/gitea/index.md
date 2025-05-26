# Gitea 部署安装


Gitea 的部署安装很简单，直接从官方下载 `gitea` 二进制包运行就可以了

官方文档: [https://docs.gitea.io/zh-cn/install-from-binary/](https://docs.gitea.io/zh-cn/install-from-binary/)

## 二进制部署 gitea

### 安装 git

git 版本只能是 2.x 及以上的版本，由于 centos 仓库自带的 git 版本默认为 1.x 不满足 gitea 的需求，需要使用第三方 YUM 安装 git

**创建仓库配置文件 `/etc/yum.repos.d/wandisco-git.repo`**

```ini
[wandisco-git]
name=Wandisco GIT Repository
baseurl=http://opensource.wandisco.com/centos/7/git/$basearch/
enabled=1
gpgcheck=1
gpgkey=http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco
```

**导入验证密钥**

```bash
rpm --import http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco
```

**安装 git**

```bash
yum install git
git --version
```

> 参考文档: [https://www.cnblogs.com/zhaoxxnbsp/p/12674339.html](https://www.cnblogs.com/zhaoxxnbsp/p/12674339.html)

### 安装 gitea

我们需要使用 git 用户运行 gitea，所以需要先创建 git 用户，执行以下命令

```bash
useradd -d /data/git-data -m git
```

接下来的操作我们都使用 git 用户进行，执行 `su - git`

基于二进制的安装非常简单，只要从 [下载页面](https://dl.gitea.io/gitea) 选择对应平台，拷贝下载 `URL`，执行以下命令即可（以Linux为例）：

```bash
wget -O gitea https://dl.gitea.io/gitea/1.14.2/gitea-1.14.2-linux-amd64
chmod +x gitea
```

让 gitea 跑起来，执行命令

```bash
./gitea web
```

> 现在你可以在浏览器打开 http://<your_server_ip>:3000 进行配置了

> gitea 支持的数据库有 SQLite, MySQL 和 PostgreSQL，你可以选择你喜欢的数据库来存放 gitea 相关的数据，如果是测试可以直接使用 SQLite

### 配置反向代理

在日常使用过程最好还是做下反向代理的配置，使用标准的 `http(s)` 端口提供服务，下面列出了常的 web 应用配置反向的的配置

*nginx 配置*

```
server {
    listen 80;
    server_name <your_domain>;
    location / {
        proxy_pass http://127.0.0.1:3000;
    }
}
```

*apache 配置*

```bash
<VirtualHost *:80>
    ServerName <your_domain>
    ProxyRequests Off
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/

    <proxy *>
        AllowOverride None
        Order Deny,Allow
        Allow from all
    </proxy>
</VirtualHost>
```

*caddy2 配置*

```
<your_domain> {
    reverse_proxy localhost:3000
}
```

## 部署 Gitea 和 Gogs 遇到的坑

1. `Gogs` 和 `Gitea` 依赖于 `git 2.0` 及以上的版本
2. `Gogs` 和 `Gitea` 查找 `git` 相关命令的路径固定为 `/usr/bin`，只配置 `PATH` 环境变量是没有用的，有以下错误提示:

```
Failed to execute git command: exec: "git-upload-pack": executable file not found in $PATH
fatal: Could not read from remote repository.
```

> 解决方法：使用软链接将 git 相关命令链接至 `/usr/bin` 目录下(这个只针对 git 安装命令路径不是 `/usr/bin` 的情况)， 执行命令 `ln -s /usr/local/git/bin/* /usr/bin/`
