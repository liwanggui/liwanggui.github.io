# Rocky Linux 安装 docker


Rocky Linux 无法通过 https://get.docker.com 脚本安装 docker，但可以通过手动添加 CentOS 的 docker-ce yum 源来安装

## 配置 Docker YUM 源

```bash
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

对于国内安装用户可以使用国内源，如:

*阿里云源*

```bash
dnf config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

*中科大源*

```bash
dnf config-manager --add-repo https://mirrors.ustc.edu.cn/docker-ce/linux/centos/docker-ce.repo
```

## 安装 docker

```bash
dnf install docker-ce
```

*配置 docker 镜像加速*

```bash
cat >/etc/docker/daemon.json<<EOF
{
  "registry-mirrors": [
            "https://docker.mirrors.ustc.edu.cn/", 
            "http://hub-mirror.c.163.com"
            ]
}
EOF
```
