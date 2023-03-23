---
title: "docker - Dockerfile 相关指令"
date: "2021-03-06T10:53:43+08:00"
draft: false
categories:
- container
tags:
- docker
- dockerfile
---

- `Dockerfile` 是一个文本格式的配置文件，用户可以使用 `Dockerfile` 快速创建自定义的镜像。
- `Dockerfile` 由一行行命令语句组成，并且支持以 `#` 开头注释行。
- `Dockerfile` 一般分为四部分： 基础镜像信息，维护者信息、镜像操作指令和容器启动时执行指令。

## 指令

### FROM 

格式: `FROM <image> 或者 FROM <image>:<tag>`

`Dockerfile` 的第一条指令必须是 `FROM`

### MAINTAINER - 弃用

格式: `MAINTAINER <name>`，指定维护者信息

> 推荐使用 `LABEL maintainer="SvenDowideit@home.org.au"`

### LABLE

格式: `LABEL <key>=<value> <key>=<value> <key>=<value> ...`

该指令将元数据添加到 docker 镜像中

```
LABEL "com.example.vendor"="ACME Incorporated"
LABEL com.example.label-with-value="foo"
LABEL version="1.0"
LABEL description="This text illustrates \
that label-values can span multiple lines."
```

### USER

格式: `USER <username>`

指定容器内进程使用的用户名或 `UID`, 当服务不需要管理员权限时，可以通过该命令指定运行用户。并且可以在之前创建所需要的用户。

### WORKDIR

格式: `WORKDIR /path/to/workdir`

指定容器的当前工作路径，为后续的 `RUN`、`CMD`、`ENTRYPINT` 指令配置工作路径

### ENV 

格式: 

- `ENV <key> <value>` 指定一个环境变量，可以被 `RUN` 指令使用，并在容器运行时保持存在
- `ENV <key1>=<value1> <key2>=<value2>...` 可以同时指定多个变量，推荐使用这种方式

```
ENV PG_MAJOR=9.3 PG_VERSION=9.3.4

RUN curl -SL http://example.com/postgres-${PG_VERSION}.tar.gz | tar -xzC /usr/src && ...

ENV PATH=/usr/local/postgres-$PG_MAJOR/bin:$PATH
```

### ARG

格式: `ARG <key>=<value> ...`

该指令定义了一个变量，只在构建镜像时生效。可以只定义变量名(或者默认值)，然后使用命令 `docker build --build-arg` 参数, 传递变量值的给构建者。
如果用户指定了Dockerfile中未定义的构建参数，则该构建会输出警告。`ARGdocker build--build-arg <varname>=<value>`

### ADD

格式: `ADD <src> <dest>`

该指令将复制指定的 `<src>` 到容器中的 `<dest>`. 其中 `<src>` 可以是 `Dockerfile` 所在目录的一个相对路径(文件和目录)；
也可以是一个 `url`；还可以是一个 `tar` 文件（自动解压为目录）

```
ADD hom* /mydir/
ADD hom?.txt /mydir/
ADD --chown=55:mygroup files* /somedir/
ADD --chown=bin files* /somedir/
ADD --chown=1 files* /somedir/
ADD --chown=10:11 files* /somedir/
ADD --chmod=755 entrypoint.sh /usr/bin
```

### COPY

格式:

- `COPY [--chown=<user>:<group>] <src>... <dest>`
- `COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]`

该指令复制文件或目录，并将它们添加到容器的文件系统路径中; 可以指定多个资源，但文件和目录的路径将基于构建路径。

```
COPY hom* /mydir/
COPY hom?.txt /mydir/
COPY --chown=55:mygroup files* /somedir/
COPY --chown=bin files* /somedir/
COPY --chown=1 files* /somedir/
COPY --chown=10:11 files* /somedir/
```


### RUN

格式: `RUN <command> 或者 RUN ["executable", "param1", "param2"]`

每条 RUN 指令将在当前镜像的基础上执行指定的命令，并提交为新镜像。当命令过长时可以使用 `\` 换行。


### EXPOSE 

格式: `EXPOSE <port> [<port> ...]`

示例:

```
EXPOSE 22 80 443
```

`EXPOSE` 指令用于暴露容器端口。在启动容器时需要通过 `-P`, `Docker` 服务会随机分配一个端口转发到指定的端口；
使用 `-p`, 可以手动指定具体本地的端口与容器端口映射。


### VOLUME 

格式: `VOLUME ["/data"]`

创建一个可以从本地主机或其他容器挂载的挂载点，一般用来存放需要持久化的数据等。


### CMD

格式: 

1. `CMD ["executable", "param1", "param2"]` 使用 `exec` 执行，推荐方式
2. `CMD command param1 param2` ,在 `/bin/sh` 中执行
3. `CMD ["param1", "param2"]` 提供给 `ENTRYPOINT` 的默认参数

指定启动容器时执行的命令，每个 `Dockerfile` 只能有一条 `CMD` 指令。如果指定多条，只有最后一条生效被执行。
如果在启动容器时指定了运行的命令，会覆盖掉 `CMD` 指定的命令。

### ENTRYPOINT

格式: 
1. `ENTRYPOINT ["executable", "param1", "param2"]`
2. `ENTRYPOINT command param1 param2`

配置容器启动后执行的命令，并且不可被 `docker run` 提供的参数覆盖.
每个 `Dockerfile` 中只能有一个 `ENTRYPOINT`，指定多个 `ENTRYPOINT` 时，只有最一个有效。

> entrypoint 命令列表必须使用双引号，单引号会出错(实测)