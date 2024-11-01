# 部署 YUM 本地仓库


`yum` 主要用于自动安装、升级 `rpm` 软件包，它能自动查找并解决 `rpm` 包之间的依赖关系。要成功的使用 `yum` 工具安装更新软件或系统，就需要有一个包含各种rpm软件包的 `repository`（软件仓库），这个软件仓库我们习惯称为 `yum` 源。网络上有大量的 `yum` 源，但由于受到网络环境的限制，导致软件安装耗时过长甚至失败。特别是当有大量服务器大量软件包需要安装时，缓慢的进度条令人难以忍受。因此我们在优化系统时，都会更换国内的源。

相比较而言，本地 `yum` 源服务器最大优点是局域网的快速网络连接和稳定性。有了局域网中的 `yum` 源服务器，即便在 Internet 连接中断的情况下，也不会影响其他 `yum` 客户端的软件安装和升级。

## 创建 yum 仓库目录

```bash
mkdir -p /data/yum/centos/{6,7}/x86_64
```

> 上传 rpm 包到 `/data/yum/centos/6/x86_64` 和 `/data/yum/centos/7/x86_64` 目录

## 安装 createrepo 软件

```bash
yum install createrepo
```

## 初始化 repodata 索引文件

```bash
createrepo -pdo /data/yum/centos/6/x86_64/ /data/yum/centos/6/x86_64/
createrepo -pdo /data/yum/centos/7/x86_64/ /data/yum/centos/7/x86_64/
```

## 提供 yum 服务

提供 `yum` 服务很简单，只需要使用 `nginx` 开启目录浏览器功能即可, 测试时可以使用 `python` 模块实现

```bash
# python 2.x
python2 -m SimpleHTTPServer 80

# python 3.x
python3 -m http.server 80
```

## 添加新 rpm 包

每当添加新的 `rpm` 包时都需要执行以下命令, 为了方便可以将以下加入计划任务中

```bash
createrepo --update /data/yum/centos/6/x86_64/
createrepo --update /data/yum/centos/7/x86_64/
```

## 客户端配置

客户端需要将 `yum` 仓库地址写成 `yum` 源配置文件，并放入 `/etc/yum.repos.d` 目录中

```bash
cat > /etc/yum.repos.d/devops.repo << REPO
[devops]
name=CentOS-$releasever - DEVOPS
baseurl=http://your_domain_name/centos/$releasever/x86_64/
enable=1
gpgcheck=0
REPO
```

> 之后就可以使用 `yum` 安装 `devops` 仓库中的 `rpm` 包了

