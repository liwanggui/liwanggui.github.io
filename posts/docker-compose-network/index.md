# Docker Compose 网络配置


`Docker Compose` 提供了一种方便的方式来配置网络，本文档将介绍 `Docker Compose` 的网络相关配置

Docker 官方文档:

- https://docs.docker.com/compose/compose-file/05-services/#network_mode
- https://docs.docker.com/compose/compose-file/06-networks


## 默认网络

`Docker Compose` 默认会创建一个以 `项目名_default` 为名称的网络，它使用 `bridge` 网络模式，并且所有容器都可以相互通信, 默认网络的配置如下：

```yaml
version: '3'

services:
  service1:
    image: image1
  service2:
    image: image2
```

> 提示: `Docker Compose` 的 `项目名` 默认以 `当前目录名` 命名，可以使用 `-p` 参数指定或者通过 `.env` 文件中写入 `COMPOSE_PROJECT_NAME=test`

## 自定义网络

`Docker Compose` 支持自定义网络

1. 自定义网络名称

    ```yaml
    version: '3'

    services:
      service1:
        image: image1
        networks:
          - mynet
      service2:
        image: image2
        networks:
          - mynet

    networks:
      mynet:
        driver: bridge
    ```

2. 自定义网络地址段

    ```yaml
    version: '3'

    services:
      service1:
        image: image1
        networks:
          - mynet
      service2:
        image: image2
        networks:
          - mynet

    networks:
      mynet:
        driver: bridge
        ipam:
          driver: default
          config:
            - subnet: 172.16.10.0/24
              gateway: 172.16.10.1
    ```

3. 为容器固定指定 ip 地址

    ```yaml
    version: '3'

    services:
      service1:
        image: image1
        networks:
          mynet:
            ipv4_address: 172.16.10.11
      service2:
        image: image2
        networks:
          - mynet

    networks:
      mynet:
        driver: bridge
        ipam:
          driver: default
          config:
            - subnet: 172.16.10.0/24
              gateway: 172.16.10.1
    ```

## 外部网络

不同 `docker-compose.yml` 默认会创建不同的网络，当我们需要共用同一个网络时, 可以启用外部网络

> 注意: 共用的网络可以手动提前创建好， 命令 `docker network create ...`, 也可以是其他 `services` 创建的网络

以公用网络 `mynet` 为例

```yaml
version: '3'

networks:
  mynet:
    external: true

services:
  web:
    image: 'registry.gitlab.cn/omnibus/gitlab-jh:latest'
    restart: always
    hostname: 'gitlab'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.liwanggui.com'
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
    networks:
      - mynet  # 指定网络
    ports:
      - '8929:80'
      - '2222:22'
    volumes:
      - './gitlab-data/config:/etc/gitlab'
      - './gitlab-data/logs:/var/log/gitlab'
      - './gitlab-data/data:/var/opt/gitlab'
    shm_size: '256m'
```
