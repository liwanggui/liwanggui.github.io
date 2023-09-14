---
title: "Docker Compose 进阶篇"
date: 2023-09-14T11:11:31+08:00
draft: false
categories: 
- container
tags:
- docker compose
---

## 概述

`docker-compose` 项目是docker官方的开源项目， 负责实现对docker容器集群的快速编排，来轻松高效的管理容器，定义运行多个容器。

- `docker-compose`将所管理的容器分为三层， 分别是工程（project），服务（service）以及容器（containner）
- `docker-compose`运行目录下的所有文件（`docker-compose`.yml文件、extends文件或环境变量等）组成一个工程，如无特殊指定，工程名即为当前目录名。
- 一个工程当中，可以包含多个服务，每个服务中定义了容器运行的镜像、参数、依赖。
- 一个服务中可以包括多个容器实例，`docker-compose`并没有解决负载均衡的问题。因此需要借助其他工具实现服务发现及负载均衡，比如 consul。
- `docker-compose`​的工程配置文件默认为 `docker-compose.yml`。可以通过环境变量COMPOSE_FILE -f 参数自定义配置文件，其自定义多个有依赖关系的服务及每个人服务运行的容器。


**官方文档：** https://docs.docker.com/compose/

**GitHub：** https://github.com/docker/compose/releases/

## Compose 和 Docker 兼容性

`Compose` 文件格式有多个版本：`1`、`2`、`2.x`、和 `3.x`。下面的表格是 `Compose` 文件所支持的指定的 `docker` 发行版：

{{< figure src="/images/b415e85e-b56b-40b5-9392-986d1544728b.png" title="docke compose & docker 版本对应图">}}

## 安装 docker

```bash
# 安装yum-config-manager配置工具
yum -y install yum-utils

# 建议使用阿里云yum源：（推荐）
#yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 安装docker-ce版本
yum install -y docker-ce

# 启动并开机启动
systemctl enable --now docker
docker --version
```

> 提示: 可以使用 docker 官方提供在线脚本进行安装，参考: [docker - 快速安装](/posts/docker-install/)

## 安装 docker-compose

官方安装地址教程：https://docs.docker.com/compose/install/other/

```bash
curl -SL https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

chmod +x /usr/bin/docker-compose
docker-compose --version
```

## 环境变量

`Docker Compose` 允许你使用多种方法为服务设置环境变量。 这些环境变量可以用来配置你的应用程序或将敏感信息传递给你的容器。

下面是一些设置 `Docker Compose` 环境变量的方法：

1. 在 `docker-compose.yml` 文件中设置环境变量

    你可以在 `docker-compose.yml`​ 文件中为每个服务设置环境变量。在服务配置中，使用 `environment` 关键字，并在其中列出需要设置的环境变量和其值。

    ```yaml
    services:
      web:
        image: nginx
        environment:
        MY_VAR: my_value
    ```

2. 从 `.env` 文件中读取环境变量

    你可以将环境变量存储在一个 `.env`​ 文件中，并让 `Docker Compose` 读取它。在 `docker-compose.yml`​ 文件中，使用 `env_file​` 关键字并指定 `.env` 文件的路径。

    ```yaml
    services:
      web:
        image: nginx
        env_file:
        - .env
    ```

3. 使用 shell 环境变量

    你也可以在启动 `docker-compose` 命令时，使用 `shell` 环境变量传递环境变量值。例如：

    ```bash
    $ export MY_VAR=my_value
    $ docker-compose up
    ```

    在 `docker-compose.yml`​ 文件中使用 `${MY_VAR}` 语法来引用 `shell` 环境变量。

    ```yaml
    services:
      web:
        image: nginx
        environment:
        MY_VAR: ${MY_VAR}
    ```

    使用环境变量可以使你的应用程序更具灵活性，并且可以方便地管理敏感信息。

## 编排中的字段详解

在 `Docker Compose` 编排文件中，有一些重要的字段需要了解：

### version

`version​` 字段指定了 `Docker Compose` 编排文件的版本。 当前最新版本是 3。

```yaml
version: '3'
```

### services

`services` 字段指定了在 `Docker Compose` 编排中要运行的服务。每个服务都有一个名称，并指定要使用的镜像和容器的配置选项。 
以下是一个简单的 `services` 配置的示例：

```yaml
services:
  web:
    build: .
    ports:
      - "5000:5000"
  redis:
    image: "redis:alpine"
```

### build 与 image

1. build

    `build` 字段允许在 `Docker Compose` 编排中指定 `Dockerfile` 的位置，从而可以使用 `Docker Compose` 构建镜像。
    例如，以下是使用本地 `Dockerfile` 的示例：

    ```yaml
    services:
      web:
        build: .
    ```

    也可以指定一个包含 `Dockerfile` 的目录：

    ```yaml
    services:
      web:
        build: ./my-web-app
    ```

2. image

    `image` 字段指定要使用的 `Docker` 镜像。例如：

    ```yaml
    services:
      web:
        image: nginx
    ```

    > 【温馨提示】`build` 和 `image` 二选一即可，也可以同时写，但是一般只选择 `image` 吧。

    ```yaml
    version: '3.8'
      services:
      web:
        build: ./web
        image: myapp/web:latest
    ```

    上面的配置指定了服务名称为 `web`, Dockerfile 路径为 `./web`，镜像名称为 `myapp/web`​，标签为 `latest`​。在运行 `docker-compose build`​ 命令时，会自动构建名为 `myapp/web:latest` 的镜像。

### networks

`networks` 字段指定了要使用的网络。默认情况下，`Docker Compose` 创建一个名为 `default` 的网络。
以下是一个使用自定义网络的示例：

```yaml
networks:
  my-network:
    driver: bridge
```

### volumes

`volumes` 字段指定了要使用的数据卷。 以下是一个使用数据卷的示例（下面会细讲）：

```yaml
volumes:
  my-volume:
    driver: local
```

### environment 与 environment_file

1. environment

    `environment` 字段指定了要设置的环境变量。以下是一个使用环境变量的示例：

    ```yaml
    environment:
      MY_VAR: my_value
    ```

2. environment_file

    `environment_file`：指定从文件中读取环境变量。

    ```yaml
    environment_file: .env
    ```

### ports 与 expose

1. ports

    `ports` 字段指定了要宿主机映射到容器的端口（宿主机端口:容器端口）。以下是一个使用端口映射的示例：

    ```yaml
    ports:
      - "8080:80"
    ```

2. expose

    `expose` 字段是用于在 `Docker` 容器内部暴露端口的选项，可以让其他容器连接到这些端口，但不会将它们映射到 `Docker` 主机上。

    在 `docker-compose.yml` 文件中使用 `expose` 选项来指定容器内部需要暴露的端口。例如，以下示例定义了一个 `web` 服务，它暴露了 `8000` 和 `8080` 端口：

    ```yaml
    version: '3'
      services:
      web:
        image: myapp:latest
        expose:
        - "8000"
        - "8080"
    ```

    当您使用 `expose​` 选项时，其他容器可以使用 `Docker` 的内部网络进行连接。例如，如果您有另一个服务 `worker`，它需要连接到 `web` 服务的 `8000` 端口，则可以在 `worker` 服务的 `docker-compose.yml` 文件中使用 `links` 选项：

    ```yaml
    version: '3'
    services:
      worker:
        image: myworker:latest
        links:
          - web
    ```

### depends_on

`depends_on` 字段指定了服务之间的依赖关系。例如，如果 `web` 服务依赖于 `db` 服务，则可以使用以下示例：

```yaml
depends_on:
  - db
```

### restart

`Docker Compose` 提供了几种重启策略，以便在容器出现故障时自动重启它们。以下是可用的重启策略：

- no: 不重启任何容器。如果容器停止，`Compose` 不会尝试自动重启它们。（默认策略）
- always: 如果容器停止，`Compose` 将自动重启它。（常用）
- on-failure: 只有在容器因非 `0` 退出码而停止时才会重启。
- unless-stopped: 除非手动停止，否则始终重启容器。这相当于使用 `docker run` 命令时使用的 `--restart=unless-stopped` 标志。

这些策略可以在 `docker-compose.yml` 文件中通过 `restart` 键指定，例如：

```yaml
version: '3'
services:
  web:
    image: myapp:latest
    restart: always
```

这个示例使用 `always` 策略，这意味着如果 `web` 容器停止，`Compose` 将自动重启它。

### command

`command` 字段可以使用多种写法来指定容器启动时要执行的命令，具体取决于您的需求和偏好。

以下是一些常见的写法示例：

1. 字符串形式

    ```yaml
    version: '3'
    services:
      web:
        image: myapp:latest
        command: python manage.py runserver 0.0.0.0:8000
    ```

    在这个示例中，command 字段的值是一个字符串，表示要执行的命令和参数。

2. 列表形式

    ```yaml
    version: '3'
    services:
      web:
        image: myapp:latest
        command:
        - python
        - manage.py
        - runserver
        - 0.0.0.0:8000
    ```

    在这个示例中，command 字段的值是一个列表，每个元素都表示要执行的命令或参数。

3. Shell 命令形式

    ```yaml
    version: '3'
    services:
      web:
        image: myapp:latest
        # 两种写法
        # command: sh -c "python manage.py runserver 0.0.0.0:8000"
        command: ["sh","-c","python manage.py runserver 0.0.0.0:8000"]
    ```

4. 使用环境变量形式

    ```yaml
    version: '3'
    services:
      web:
        image: myapp:latest
        environment:
          - ENVIRONMENT=production
        command: python manage.py runserver 0.0.0.0:${PORT}
    ```

    在这个示例中，command 字段中的 ${PORT}​ 将被替换为 web 服务的环境变量 PORT 的值。

### configs 与 secrets

1. configs

    configs：指定容器使用的配置文件。

    ```yaml
    configs:
      - source: my-config
        target: /etc/nginx/conf.d/default.conf
    ```

    上面的例子中，将名为 `my-config` 的配置文件复制到容器的 `/etc/nginx/conf.d/default.conf` 目录下。

2. secrets

    `secrets：` 指定容器使用的机密数据。

    ```yaml
    secrets:
      - db_password
    ```

### hostname 与 container_name

`hostname​` 和 `container_name` 都是用来定义 `Docker` 容器的标识符，但是它们的含义不同。

1. hostname

    `hostname` 用于设置容器的主机名，也就是在容器内部可以使用的名称。

    例如，如果您在容器内部使用 `ping hostname` 命令，它将解析为容器的 IP 地址。可以使用以下格式设置主机名：

    ```yaml
    version: '3'
    services:
      web:
        image: myapp:latest
        container_name: myapp
    ```

    在这个示例中，`web` 服务的容器主机名被设置为 `myapp-container`。

2. container_name

    `container_name` 用于给容器命名，也就是在 `Docker` 主机上使用的名称。可以使用以下格式设置容器名称：

    ```yaml
    version: '3'
    services:
      web:
        image: myapp:latest
        container_name: myapp
    ```

    在这个示例中，web 服务的容器名称被设置为 myapp。

    > 总之，`hostname` 和 `container_name` 都是用于定义容器的标识符，但是 `hostname` 用于容器内部的标识，`container_name` 用于 `Docker` 主机上的标识。

### user

在 Docker Compose 中，可以使用 user 字段来指定容器中运行的进程的用户和用户组。它的语法与 docker run​ 命令的 --user 选项类似，有以下三种形式：

1. user:group（推荐）

    以 `user` 用户和 `group` 用户组的身份运行容器中的进程，例如：

    ```yaml
    version: "3"
    services:
      web:
        image: nginx
        user: nginx:nginx
    ```

2. uid:gid

    以 `uid` 用户 `ID` 和 `gid` 用户组 `ID` 的身份运行容器中的进程，例如：

    ```yaml
    version: "3"
    services:
      web:
        image: nginx
        user: "1000:1000"
    ```

3. user

    以 `user` 用户的身份运行容器中的进程，例如：

    ```yaml
    version: "3"
    services:
      web:
        image: nginx
        user: nginx
    ```

    需要注意的是，如果在 `Docker Compose` 中使用了 `user` 字段，则容器中的所有进程都将以指定的用户身份运行，而不是默认的 `root` 用户身份运行。这可以提高容器的安全性，避免在容器中使用 `root` 用户造成潜在的安全风险。

### deploy

`deploy：`指定服务部署配置。

```yaml
deploy:
  replicas: 3
  resources:
    limits:
      cpus: '0.5'
      memory: '256M'
    reservations:
      cpus: '0.25'
      memory: '128M'
```

上面的例子中，配置服务的副本数量为 `3`，限制每个副本使用的 CPU 和内存资源，并保留一部分资源供其他服务使用。

## port 和 expose 区别

`ports​` 和 `expose` 是两个不同的 `Docker Compose` 字段，用于在容器中暴露端口。

`ports` 字段用于将容器内部的端口映射到宿主机上的端口，以便外部网络可以通过宿主机上的端口与容器中运行的应用程序进行通信。这个字段的语法如下：

```yaml
version: "3"
services:
  web:
    image: nginx
    ports:
      - "8080:80"
```

这个例子中，容器中运行的 `nginx` 进程监听的是容器内部的 `80` 端口，而 `ports` 字段将宿主机上的 `8080` 端口映射到了容器内部的 `80` 端口，这样外部网络就可以通过访问宿主机上的 `8080` 端口来访问容器中运行的 `nginx` 应用程序。

`expose​` 与 `ports` 不同的是，`expose` 字段仅仅是将容器内部的端口暴露给其他容器使用，而不是直接映射到宿主机上的端口。这个字段的语法如下：

```yaml
version: "3"
services:
  db:
    image: mysql
    expose:
      - "3306"
  web:
    image: nginx
    expose:
      - "80"
```

这个例子中，`db` 和 `web` 两个容器分别暴露了它们内部的 `3306` 和 `80` 端口，其他容器可以使用这些端口来与它们通信。
但是，由于这些端口没有被映射到宿主机上，因此外部网络无法直接访问它们。如果要从外部网络访问这些容器，需要使用 `ports` 字段将它们映射到宿主机上的端口。

## configs 与 secrets 区别

`configs​` 和 `secrets` 是 `Docker Compose` 和 `Docker Swarm` 中用于管理容器配置和敏感数据的两个不同的功能。
它们的区别如下：

- 用途不同：`configs` 用于管理容器应用程序的配置文件，例如 `nginx` 的配置文件、`MySQL` 的配置文件等，而 `secrets` 则用于管理敏感数据，例如数据库的密码、`API` 密钥等。
- 存储位置不同：`configs` 存储在 `Docker` 主机的文件系统中，可以是本地文件系统、`NFS` 文件系统或远程 `S3` 存储等，而 `secrets` 存储在 `Docker Swarm` 的安全存储中，该存储是加密的、高度安全的，并且只能由授权的 `Docker` 服务和节点访问。
- 访问方式不同：`configs` 可以通过文件挂载或 `Docker Compose` 文件中的 `configs` 字段来访问，而 `secrets` 可以通过文件挂载、`Docker Compose` 文件中的 `secrets` 字段、`Docker CLI` 的 `docker secret` 命令或容器内部的文件系统来访问。
- 生命周期不同：`configs` 的生命周期是独立于服务的，当服务停止时，配置文件仍然可以保留在主机上，而 `secrets` 的生命周期是与服务绑定的，当服务被删除时，敏感数据也会被删除。
- 更新方式不同：`configs` 的更新是通过重新部署服务来实现的，而 `secrets` 的更新是通过 `Docker CLI` 的 `docker secret` 命令或容器内部的文件系统来实现的。

以下是一个使用 `configs`​ 和 `secrets` 的 `Docker Compose` 文件的示例：

```yaml
version: '3.7'

services:
  web:
    image: nginx:latest
    ports:
      - 80:80
    configs:
      - source: nginx_conf
        target: /etc/nginx/nginx.conf
    secrets:
      - source: db_password
        target: /run/secrets/db_password

configs:
  nginx_conf:
    file: ./nginx.conf

secrets:
  db_password:
    file: ./db_password.txt
```

在上面的示例中，我们定义了一个 `web` 服务，该服务使用了 `nginx:latest` 镜像，并将容器内的 `80` 端口映射到 `Docker` 主机的 `80` 端口。此外，我们还定义了两个配置：`configs` 和 `secrets`。

- configs​ 定义了一个名为 `nginx_conf` 的配置，该配置从本地的 `nginx.conf` 文件中读取配置，并将其挂载到容器内的 `/etc/nginx/nginx.conf` 路径。这样，我们就可以使用自定义的 `nginx.conf` 配置文件来配置 `nginx` 服务。
- secrets​ 定义了一个名为 `db_password` 的敏感数据，该数据从本地的 `db_password.txt` 文件中读取，并将其挂载到容器内的 `/run/secrets/db_password` 路径。这样，我们就可以在容器内部安全地访问数据库密码，而不必担心密码泄露的风险。

在上述示例中，我们使用了文件挂载来访问 `configs​` 和 `secrets`。这是最常见的访问方式，但并不是唯一的方式。`secrets` 还可以通过 `Docker CLI` 的 `docker secret` 命令或容器内部的文件系统来访问。

## 挂载

在 `Docker Compose` 中，可以通过挂载主机目录或文件来访问容器内部的文件或目录，以便在容器内外共享数据或配置文件。`Docker Compose` 支持两种方式进行挂载：

1. 命名卷挂载

    命名卷是由 `Docker` 创建和管理的卷，它们可以用于存储持久化数据，并可以在多个容器之间共享。
    在 `Docker Compose` 中，可以通过 `volumes` 字段来定义命名卷的挂载路径和主机目录的映射关系。
    关于 `docker` 的卷管理可以参考我这篇文章：`Docker` 数据卷 `—Volumes`。

    示例例如：

    ```yaml
    version: "3.7"

    services:
      app:
        image: myapp:latest
        volumes:
          - myapp_data:/app/data

      volumes:
        myapp_data:
    ```

    在上述示例中，我们定义了一个 `myapp` 服务，该服务使用了 `myapp:latest` 镜像，并将命名卷 `myapp_data` 挂载到容器内的 `/app/data` 目录。

2. 主机目录挂载

    主机目录挂载允许将 `Docker` 主机上的目录或文件夹挂载到容器内部，以便在容器内外共享数据。在 `Docker Compose` 中，可以通过 `volumes` 字段来定义主机目录的挂载路径和主机目录的映射关系。例如：

    ```yaml
    version: "3.7"

    services:
      app:
        image: myapp:latest
        volumes:
          - /host/data:/app/data
    ```

    在上述示例中，我们定义了一个 `myapp` 服务，该服务使用了 `myapp:latest` 镜像，并将宿主机上的 `/host/data` ​目录挂载到容器内的 `/app/data` 目录。

    > 注意: 在 `Docker Compose` 中，如果使用主机目录挂载，则要求主机目录必须存在且具有正确的权限。否则，容器将无法访问该目录。此外，在使用主机目录挂载时，请注意挂载的目录是否包含敏感数据，以避免数据泄露的风险。

## 网络

`Docker Compose` 中的网络可以用于在多个容器之间建立通信。通过定义网络，可以让容器之间相互通信，同时将它们与主机网络隔离开来，提高容器应用的安全性。

`Docker Compose` 提供了三种网络类型：`bridge`、`host` 和 `none`，每种类型都适用于不同的场景。

1）bridge 网络类型

bridge 网络类型是默认的网络类型，它创建一个桥接网络，允许容器之间进行通信。每个容器都有自己的 IP 地址，并且可以通过容器名称来相互访问。如果没有指定网络类型，`Docker Compose` 将使用 ​bridge 网络类型。

在 bridge 网络类型中，`Docker Compose` 会为每个服务创建一个容器，并为每个容器分配一个 IP 地址。在同一个网络中的容器可以相互访问。

> 注意: 如果您使用了 `Docker Compose` 的网络功能（默认情况下会创建一个网络），则可以在同一网络中的任何容器中使用容器名称来访问服务。如果您没有使用Docker Compose网络功能，则需要手动创建网络，并将所有容器添加到同一网络中。

【示例】假设我们有两个服务：`web` 和 `db`。在默认情况下，`Docker Compose` 使用 `bridge` 网络类型，我们可以不用特别指定网络类型。以下是一个示例的 `docker-compose.yml` 文件：

```yaml
version: '3'
services:
  web:
    build: .
    ports:
      - "80:80"
  db:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: example
```

在上述示例中，`web` 服务将使用本地 `Dockerfile` 构建，并将容器端口 `80` 映射到主机端口 `80`。`db` 服务将使用 `MySQL 5.7` 镜像，并设置 `MySQL` 的 `root` 用户密码为 `example`。

通过 `docker-compose up` 命令启动这个示例，`Docker Compose` 将为每个服务创建一个容器，并自动创建一个默认的 `bridge` 网络来使它们互相通信。

2. host 网络类型

`host` 网络类型让容器共享主机的网络栈，这意味着容器将与主机具有相同的 IP 地址和网络接口。这样可以提高容器的网络性能和可访问性，但是容器之间不能互相访问，因为它们共享同一个网络栈。

在 `host` 网络类型中，`Docker Compose` 会将每个服务直接放在主机网络中，容器将与主机共享 IP 地址和网络接口，因此可以通过主机 IP 地址来访问容器中运行的服务。

【示例】假设我们有一个服务，它需要使用主机网络接口。以下是一个示例的 `docker-compose.yml` 文件：

```yaml
version: '3'
services:
  web:
    build: .
    network_mode: host
```

在上述示例中，我们使用 `build` 关键字来指定构建上下文，并使用 `network_mode​` 关键字将服务 `web` 的网络模式设置为 `host`。这样，`web` 服务将与主机共享 `IP` 地址和网络接口，可以通过主机 `IP` 地址来访问服务。

3. none 网络类型

`none` 网络类型表示不为容器分配任何网络资源，容器将没有网络接口。这通常用于某些特殊的容器场景，例如一些只需要与主机交互而不需要网络连接的容器。

在 `none` 网络类型中，`Docker Compose` 会将每个服务放在一个单独的网络命名空间中，容器将没有任何网络资源，无法进行网络通信。

【示例】假设我们有一个服务，它不需要任何网络连接。以下是一个示例的 `docker-compose.yml` 文件：

```yaml
version: '3'
services:
  worker:
    build: .
    network_mode: none
```

在上述示例中，我们使用 `build` 关键字来指定构建上下文，并使用 `network_mode` 关键字将服务 `worker` 的网络模式设置为 `none`。这样，`worker` 服务将没有任何网络资源，无法进行网络通信。

4. 自定义网络

`Docker Compose` 默认会为每个 `Compose` 项目创建一个网络。这个网络的名称会以 `Compose` 项目的目录名作为前缀，例如，如果您的 `Compose` 项目目录名为`myproject`，则默认创建的网络名称为 `myproject_default`。

在这个默认创建的网络中，所有的服务和容器都可以通过它们的服务名称或容器名称进行通信。这些名称在默认情况下都是唯一的，因此可以避免名称冲突和混乱。
如果您需要访问不同的网络或自定义网络，则可以使用 `Docker Compose` 的 `networks` 属性来创建自定义网络。

例如，以下是一个 `Docker Compose` 文件，其中定义了一个名为 `my_network` 的自定义网络：

```yaml
version: '3'
services:
  web:
    image: nginx
    networks:
      - my_network

networks:
  my_network:
    driver: bridge
```

在这个示例中，`web` 服务将被连接到 `my_network` 网络中，而不是默认创建的网络。该网络的驱动程序为 `bridge`，这是 `Docker Compose` 默认使用的网络驱动程序。

`Compose` 项目目录名解释：`Compose` 项目目录名是指包含 `Docker Compose` 文件的目录的名称。
`Docker Compose` 文件（通常命名为 `docker-compose.yml`）描述了 `Docker Compose` 应该如何构建和运行 Docker 容器应用程序。该文件通常存储在Compose项目目录的根目录中。

例如，如果您正在开发一个名为myapp的应用程序，并使用 `Docker Compose` 来管理它的容器化部署，那么您可能会在以下目录结构中存储您的 `Docker Compose` 文件：

```yaml
myapp/
├── docker-compose.yml
├── app/
│   ├── Dockerfile
│   └── app.py
└── data/
```

在这个例子中，`myapp` 是 `Compose` 项目目录名，`docker-compose.yml` 是 `Compose` 文件的名称，并存储在 `myapp` 目录的根目录中。`myapp` 目录还包含了应用程序的代码和数据目录。


## 域名解析 DNS

`Docker Compose` 中的容器可以使用容器名称或服务名称来相互访问，而不需要使用IP地址。 这是因为 `Docker Compose` 会为每个服务创建一个DNS记录，这些记录由默认的DNS解析器处理。

默认情况下，`Docker Compose` 会创建一个名为 "`projectname_default`" 的网络，并将所有服务连接到该网络中。该网络使用 `Docker` 内置的 `DNS` 解析器，为每个服务和容器分配一个 `DNS` 名称。例如，如果您的 `Compose` 项目名为 "`myproject`"，那么您可以使用以下命令查看所有服务的 DNS 名称：

```bash
docker-compose run <service> nslookup <service>
```

例如，如果您的服务名称为 "web" ，则可以使用以下命令查看 web 服务的 DNS 名称：

```yaml
docker-compose run web nslookup web
```

这将输出 web 服务的 DNS 记录，包括 IP 地址和 DNS 名称。例如：

```yaml
Server:    127.0.0.11
Address 1: 127.0.0.11

Name:      web
Address 1: 172.18.0.2
```

在这个例子中，`web` 服务的 DNS 名称为 "`web`"，IP地址为 `172.18.0.2` 。您可以使用该名称（"`web`"）来访问该服务，而无需使用 IP 地址。

## 健康检查

`Docker Compose` 支持为服务定义健康检查，用于检查服务是否正常运行。健康检查可以是一个命令、一个 `HTTP` 请求或者一个 `TCP` 端口。如果健康检查失败，`Docker Compose` 将尝试重新启动服务，直到达到最大重试次数或者服务成功运行。

### 健康检查语法

在 `Docker Compose` 中，可以通过 `healthcheck` 关键字来定义健康检查。具体语法如下：

```yaml
healthcheck:
  test: ["CMD-SHELL", "command"]
  interval: interval
  timeout: timeout
  retries: retries
```

参数解释：

- `test` 是健康检查的命令或者请求。
- `interval​` 是检查健康状态的时间间隔，单位为秒，默认为 30s。
- `timeout​` 是检查健康状态的超时时间，单位为秒，默认为 30s。
- `retries​` 是健康检查失败时的重试次数，默认为 3。

### 健康检查写法

包括以下几种写法：

1. 字符串形式的命令

    ```yaml
    healthcheck:
      test: curl --fail http://localhost:80 || exit 1
      interval: 30s
      timeout: 10s
      retries: 5
    ```

    在上述示例中，`healthcheck` 字段的 `test` 属性是一个字符串，表示需要执行的健康检查命令。在这个示例中，我们使用 `curl` 命令来测试 `localhost:80` 是否能够访问。如果健康检查命令返回状态码 `0`，则表示服务正常，否则表示服务异常。在这个示例中，如果健康检查失败，`Docker Compose` 将在每 `30` 秒尝试重新运行健康检查，最多重试 `5` 次。

2. 数组形式的命令

    ```yaml
    healthcheck:
      test:
        - CMD
        - curl
        - --fail
        - http://localhost:80
      interval: 30s
      timeout: 10s
      retries: 5
    ```

3. 自定义命令

    ```yaml
    healthcheck:
      test: ["CMD-SHELL", "curl --fail http://localhost:80 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
    ```

    在上述示例中，`healthcheck` 字段的 `test` 属性是一个数组，其中第一个元素是 `CMD-SHELL`，表示使用 `shell` 执行命令。第二个元素是一个自定义的命令，与前面的示例相同。

### CMD-SHELL 与 CMD

`CMD-SHELL`​ 和 `CMD​` 都是 `Dockerfile​` 中 `RUN​` 指令以及 `Docker Compose`​ 中 `healthcheck` 指令中常用的命令格式，两者之间的区别如下：

- `CMD-SHELL`（这里推荐）：表示使用 `shell` 执行命令。在 `Docker Compose` 中，健康检查的 test 属性中可以使用 `CMD-SHELL` 来执行自定义的 `shell` 命令。
- `CMD`：表示执行指定的命令或者命令参数。在 `Dockerfile` 中，CMD 常用于指定容器启动时需要执行的命令，而在 `Docker Compose` 中，`CMD` 常用于指定服务启动时需要执行的命令或者命令参数。

两者的使用方式不同，但都可以用于执行命令或者命令参数。在 `Dockerfile` 中，`CMD-SHELL`​ 并不是一个有效的指令，而在 `Docker Compose` 中，CMD 用于定义服务的启动命令，而 `healthcheck`​ 中的 test 属性可以使用 `CMD-SHELL` 来执行自定义的 `shell` 命令。其实CMD在`docker compose healthcheck`​ 也是可以使用的。只是更建议使用`CMD-SHELL`。

### 示例讲解

以下是一个简单的 `Docker Compose` 文件，其中定义了一个健康检查：

```yaml
version: "3"
services:
  web:
    image: nginx
    ports:
      - "80:80"
    healthcheck:
      #test: ["CMD", "curl", "-f", "http://localhost"]
      test: ["CMD-SHELL", "curl -f http://localhost"]
      interval: 1m
      timeout: 10s
      retries: 3
```
 
在这个例子中，`web` 服务使用 `nginx` 镜像，并将端口 `80` 映射到主机上的端口 `80` 。此外，它定义了一个健康检查，该检查将定期运行 `curl` 命令来测试服务是否响应 `HTTP` 请求。具体来说，该检查将每隔 1 分钟运行一次，超时时间为 10 秒，并尝试重试 3 次。

您可以使用以下命令启动该服务：

```bash
# 也通过-f指定docker-compose文件
docker-compose up
```

在服务启动后，`Compose` 将定期运行健康检查，并根据检查结果重启服务。您可以使用以下命令查看服务的健康状态：

```bash
docker-compose ps
```

此命令将显示服务的健康状态，例如：

```bash
Name           Command              State          Ports        
-------------------------------------------------------------------
webapp_web_1   nginx -g daemon off;   Up (healthy)   0.0.0.0:80->80/tcp
```

在这个例子中，服务的健康状态为 "`Up (healthy)`"，这表示服务正在运行并且健康检查通过。

## 常用命令

以下是 `Docker Compose` 中一些常用的命令：

- `docker-compose up`：启动 `Compose` 文件中定义的服务，创建并启动所有容器。
- `docker-compose down`：停止 `Compose` 文件中定义的服务，删除所有容器和网络。
- `docker-compose ps`：显示 `Compose` 文件中定义的所有容器的状态。
- `docker-compose logs`：显示 `Compose` 文件中定义的所有容器的日志。
- `docker-compose build`：根据 `Compose` 文件中定义的Dockerfile构建所有服务的镜像。
- `docker-compose pull`：拉取 `Compose` 文件中定义的所有服务的镜像。
- `docker-compose restart`：重启 `Compose` 文件中定义的所有服务。
- `docker-compose stop`：停止 `Compose` 文件中定义的所有服务。
- `docker-compose start`：启动 `Compose` 文件中定义的所有服务。
- `docker-compose exec`：在 `Compose` 文件中定义的容器中执行命令。
- `docker-compose run`：在 `Compose` 文件中定义的容器中运行命令。
- `docker-compose config`：检查 `Compose` 文件的语法，并显示 `Compose` 文件中定义的所有服务的配置。

这些是 `Docker Compose` 中一些常用的命令，您可以根据需要使用它们来管理和操作 `Compose` 项目。


> 原文地址: https://www.51cto.com/article/750177.html
