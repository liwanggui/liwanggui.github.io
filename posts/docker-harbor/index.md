# docker - 私有仓库部署 (harbor)


`harbor` 使用 `docker` 容器的方式部署，所以在部署 `harbor` 前需要安装好 `docker` 及单机编排工具 `docker-compose`

## 下载 harbor 离线安装包

`harbor` 托管于 Github，在 Github 上有提供完整的离线安装直接下载即可。 [Github 地址](https://github.com/goharbor/harbor)

```bash
root@ops:/opt# wget https://github.com/goharbor/harbor/releases/download/v2.1.0/harbor-offline-installer-v2.1.0.tgz
```

## 安装 docker-compose

由于 `harbor` 依赖于 `docker-compose` 完成单机编排工作，需要先安装好

```bash
root@ops:/opt# curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
root@ops:/opt# chmod +x /usr/local/bin/docker-compose
```

## 部署 harbor

```bash
root@ops:/opt# tar xzf harbor-offline-installer-v2.1.0.tgz
root@ops:/opt# cd harbor
# 复制一份harbor配置文件
root@ops:/opt/harbor# cp harbor.yml.tmpl harbor.yml
root@ops:/opt/harbor# egrep -v '^$|#' harbor.yml
hostname: harbor.host.com  # harbor 站点域名
http:
  port: 801   # 修改端口
harbor_admin_password: Harbor12345  # harbor 管理员默认密码
database:
  password: root123
  max_idle_conns: 50
  max_open_conns: 100
data_volume: /data/harbor  # harbor 数据存储路径
clair:
  updaters_interval: 12
trivy:
  ignore_unfixed: false
  skip_update: false
  insecure: false
jobservice:
  max_job_workers: 10
notification:
  webhook_job_max_retry: 10
chart:
  absolute_url: disabled
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /data/harbor/logs   # harbor 日志文件路径
_version: 2.0.0
proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - clair
    - trivy
root@ops:/opt/harbor# ./install # 开始部署 harbor
```

## 配置 nginx 反代

> 部署完成后可以配置 nginx 反代对外提供服务，nginx 配置注意加大 `client_max_body_size` 参数值.

```nginx
server {
    listen 80;
    server_name harbor.wfugui.com;

    # 注意此项配置
    client_max_body_size 2000m;

    location / {
        proxy_pass https://localhost:801;
        include proxy.conf;
    }
}
```

> 注意: 最新版本的 harbor 如果不启用证书验证连接(https) 在 push 镜像时会不成功

