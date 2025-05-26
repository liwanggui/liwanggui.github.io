# docker - 基本操作


> docker 安装请参考: -- [Docker 快速安装](/posts/docker-install/)

## 镜像管理

### 1. 获取镜像

```bash
# 默认从 dockerhub 拉取最新版本镜像
[root@localhost ~]# docker pull busybox
Using default tag: latest
latest: Pulling from library/busybox
add3ddb21ede: Pull complete
Digest: sha256:b82b5740006c1ab823596d2c07f081084ecdb32fd258072707b99f52a3cb8692
Status: Downloaded newer image for busybox:latest

# 拉取指定版本的镜像
[root@localhost ~]# docker pull ubuntu:14.04
14.04: Pulling from library/ubuntu
48f0413f904d: Downloading [======>                                            ]  8.925MB/67.12MB
2bd2b2e92c5f: Download complete
06ed1e3efabb: Download complete
a220dbf88993: Waiting
57c164185602: Waiting
```

### 2. 列出镜像

```bash
[root@localhost ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
busybox             latest              d20ae45477cb        2 weeks ago         1.13MB
ubuntu              latest              ccc7a11d65b1        4 weeks ago         120MB
ubuntu              14.04               c69811d4e993        4 weeks ago         188MB
```

### 3. 删除镜像

```bash
[root@localhost ~]# docker rmi ubuntu:14.04
Untagged: ubuntu:14.04
Untagged: ubuntu@sha256:6a3e01207b899a347115f3859cf8a6031fdbebb6ffedea6c2097be40a298c85d
Deleted: sha256:c69811d4e9931740c0a490f74fafb566bb520b945f6e62cab96f6faecd750b95
Deleted: sha256:5294610fabc319f443fc036f7bf5c02299f2614d4b0f79c87529bb9aef46ce4e
Deleted: sha256:a783f54895fb2d76726d8b4fbbb263bcffc0cbb7fe858450a39d21b7f4de1df6
Deleted: sha256:e11129e7baf41455394f83970e3e232fa7c33a87948b76ca1c121942c4f0403f
Deleted: sha256:38c3fb0ca70b3e0444085376821508b758e4f30b290a0016c4b044b9f46bddf8
Deleted: sha256:826fc2344fbbc40cf9f2714c831a0d3ff88596e471f71c33b1055f3913d829d4
```


### 4. 保存镜像

```bash
[root@localhost ~]# docker save ubuntu:latest -o ubuntu-latest.tar
[root@localhost ~]# ls -lh
total 44M
-rw-r--r--  1 root root  72.9M Sep  9 19:20 ubuntu-latest.tar
```

*保存并压缩*

```bash
[root@localhost ~]# docker save ubuntu:latest | gzip > ubuntu-latest.tar.gz
[root@localhost ~]# ls -lh
total 44M
-rw-r--r--  1 root root  44M Sep  9 19:20 ubuntu-latest.tar.gz
```


### 5. 载入镜像

```bash
[root@localhost ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
busybox             latest              d20ae45477cb        2 weeks ago         1.13MB
[root@localhost ~]# docker load -i ubuntu-latest.tar.gz
8aa4fcad5eeb: Loading layer [==================================================>]  124.1MB/124.1MB
25e0901a71b8: Loading layer [==================================================>]  15.87kB/15.87kB
625c7a2a783b: Loading layer [==================================================>]  11.78kB/11.78kB
9c42c2077cde: Loading layer [==================================================>]  5.632kB/5.632kB
a09947e71dc0: Loading layer [==================================================>]  3.072kB/3.072kB
Loaded image: ubuntu:latest
[root@localhost ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
busybox             latest              d20ae45477cb        2 weeks ago         1.13MB
ubuntu              latest              ccc7a11d65b1        4 weeks ago         120MB
```

> PS: 结合以上命令可以使用 shell 命令完成镜像迁移工作 `docker save <镜像名> | bzip2 | pv | ssh <用户名>@<主机名> 'cat | docker load'`

## 使用容器

### 1. 启动/停止/重启容器

```bash
# -d 参数表示守护进程方式运行
[root@localhost ~]# docker container ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
727dbeacc1f5        ubuntu:latest       "/bin/bash"         3 seconds ago       Up 2 seconds                            inspiring_goldberg

# 停止容器，重启，启动指令为 restart, start
[root@localhost ~]# docker container stop inspiring_goldberg
inspiring_goldberg
[root@localhost ~]# docker container ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED              STATUS                    PORTS               NAMES
727dbeacc1f5        ubuntu:latest       "/bin/bash"         About a minute ago   Exited (0) 1 second ago                       inspiring_goldberg
```

### 2. 删除容器

```bash
[root@localhost ~]# docker container rm 727dbeacc1f5
727dbeacc1f5
[root@localhost ~]# docker container ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

> 容器删除前需要先停止

### 3. 导出容器

```bash
[root@localhost ~]# docker container export 84bc66973544 > ubuntu-latest.tar
```

### 4. 导入容器为镜像

```bash
[root@localhost ~]# cat ubuntu-latest.tar | docker import - test/ubuntu:latest
sha256:389b10ce91abd80cc9b306cbc02cfc74b5089ba60766d8fd66af48691ab9d6fc
[root@localhost ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
test/ubuntu         latest              389b10ce91ab        5 seconds ago       97.9MB
busybox             latest              d20ae45477cb        2 weeks ago         1.13MB
ubuntu              latest              ccc7a11d65b1        4 weeks ago         120MB
```

> 注：用户既可以使用 `docker load` 来导入镜像存储文件到本地镜像库，也可以
使用 `docker import` 来导入一个容器快照到本地镜像库。这两者的区别在于容
器快照文件将丢弃所有的历史记录和元数据信息（即仅保存容器当时的快照状
态），而镜像存储文件将保存完整记录，体积也要大。此外，从容器快照文件导入
时可以重新指定标签等元数据信息。

### 5. 进入容器

```bash
[root@localhost ~]# docker container ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
84bc66973544        ubuntu:latest       "/bin/bash"         12 minutes ago      Up 12 minutes                           hungry_bartik
[root@localhost ~]# docker exec -ti 84bc66973544 bash
root@84bc66973544:/# cat /etc/os-release
NAME="Ubuntu"
VERSION="16.04.3 LTS (Xenial Xerus)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 16.04.3 LTS"
VERSION_ID="16.04"
HOME_URL="http://www.ubuntu.com/"
SUPPORT_URL="http://help.ubuntu.com/"
BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
VERSION_CODENAME=xenial
UBUNTU_CODENAME=xenial
```

