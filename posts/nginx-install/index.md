# nginx - 源码编译安装


## 概述

在生产环境中一般都会安装根据环境需要定制参数的 nginx , 这就需要通过源码编译安装 nginx 了。 本文将介绍 nginx 源码编译过程

本文使用 `Ubuntu 20.04.2 LTS` 编译安装.

## 依赖

*安装 nginx 编译时所依赖软件包*

```bash
apt install gcc make openssl libssl-dev libpcre3-dev zlib1g-dev
```

## 安装

在编译之前需要先下载 nginx 源码包， [http://nginx.org/download/](http://nginx.org/download/)

```bash
wget http://nginx.org/download/nginx-1.18.0.tar.gz
```

创建 nginx 运行用户

```bash
useradd -r www
```

好了，现在可以开始编译安装 nginx 了，开始编译第一步，编译配置（编译前解压好下载好的 nginx 源码包），进入源码包，输入以下命令按 Enter 键开始配置 nginx 编译参数

```bash
./configure --prefix=/usr/local/nginx \
--user=www \
--group=www \
--with-threads \
--with-file-aio \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_sub_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_auth_request_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_degradation_module \
--with-http_slice_module \
--with-http_stub_status_module \
--with-stream \
--with-stream_ssl_module \
--with-stream_realip_module \
--with-stream_ssl_preread_module
```

如果没有错误，说明 nginx 编译参数没有问题。好了，现在开始编译 nginx，输入以下命令开始编译：

```bash
make
```

编译完成，请查看是否有错误，没有就说明编译成功了，可以开始安装了，输入以下命令开始安装：

```bash
make install
```

> 注意: `nginx` 将会安装至 `--prefix` 参数所指定路径中

## systemd

源码编译安装的 `nginx` 是不可以被 `systemd` 管理，如果需要使用 `systemd` 管理 `nginx` 服务，就需要手动编写 `systemd` 单元文件了。 `nginx.service` 文件如下:

```bash
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

将写好的 `nginx.service` 文件放入 `/usr/lib/systemd/system` 路径下即可被 `systemd` 识别
