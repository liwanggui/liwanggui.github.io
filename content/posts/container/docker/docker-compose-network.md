---
title: "Docker Compose 加入已存在的网络"
date: 2022-10-23T17:03:39+08:00
draft: false
categories: 
- container
tags:
- docker-compose
---

不同 `docker-compose.yaml` 默认会他那不同的网络，当我们需要共用同一个网络时，可以使用下以下方法实现

```yaml
version: '2.10'

# 和 nexus 共用同一个网络
networks:
  nexus3_nexus:
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
      - nexus3_nexus  # 指定网络
    ports:
      - '8929:80'
      - '2222:22'
    volumes:
      - './gitlab-data/config:/etc/gitlab'
      - './gitlab-data/logs:/var/log/gitlab'
      - './gitlab-data/data:/var/opt/gitlab'
    shm_size: '256m'
```