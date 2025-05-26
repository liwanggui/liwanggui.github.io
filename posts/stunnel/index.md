# 使用 stunnel 加密保护你的连接


## 简介

[Stunnel](https://www.stunnel.org/) 是一个自由的跨平台软件，用于提供全局的TLS/SSL服务。针对本身无法进行TLS或SSL通信的客户端及服务器，Stunnel可提供安全的加密连接。该软件可在许多操作系统下运行，包括Unix-like系统，以及Windows。Stunnel依赖于某个独立的库，如OpenSSL或者SSLeay，以实现TLS或SSL协议。

下面我们通过一个简单的示例，演示 stunnel 的配置及使用

## 部署 stunnel 

*安装*

```bash
yum install -y stunnel
```

*准备 systemd service 文件*

```bash
cat > /usr/lib/systemd/system/stunnel.service <<EOF
[Unit]
Description=TLS tunnel for network daemons
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/usr/bin/stunnel /etc/stunnel/stunnel.conf
ExecStartPre=-/usr/bin/mkdir -p /var/run/stunnel
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
```

## 配置 stunnel

由于 http 默认使用明文进行数据传输，在安全性上得不到保障，现在我们通过 stunnel 加 tls 证书包装一个让其监听 443 端口，为用户提供加密连接服务。

> 注意: 这里只是个实验用于演示 stunnel，在实际生产环境我们可以使用 nginx 或 apache 配置 https 站点

*服务端服务*

```bash
cat > /etc/stunnel/stunnel.conf <<EOF
setuid = root
setgid = root
pid = /var/run/stunnel/stunnel.pid
debug = 7
# 指定 ssl 版本
sslVersion = TLSv1.2

[http]
accept = 443
connect = 80
cert = /etc/stunnel/ssl/test/fullchain.pem
key  = /etc/stunnel/ssl/test/key.pem
EOF
```

*启动服务*

```bash
systemctl start stunnel
systemctl enable stunnel
```

> 提示: stunnel 启动后就可以直接使用 443 端口替代 80 端口提供服务了

## 客户端配置

stunnel 的客户端配置可以理解为反向代理服务器; 当我们服务端使用自签证书配置时，客户端请求时还需要带上证书会客户端带来不少麻烦事，如果客户端跑的是已经写好的工具，还得改代码重新启动客户端服务。 为了解决这事我们可以通过配置 stunnel 客户端来解决。

stunnel 客户端与 stunnel 服务端通过 tls 证书建立连接, stunnel 客户端通过在本地监控一个端口用于提供一个不需要证书就可以连接服务，然后我们程序通过连接这个端口就可以正常请求到真正的后端服务了，减少了改动工作量

*配置如下*

```
cat > /etc/stunnel/stunnel.conf <<EOF
setuid = root
setgid = root
pid = /var/run/stunnel/stunnel.pid
debug = 7
# 指定 ssl 版本
sslVersion = TLSv1.2

[http]
client = yes
accept = 80
connect = <服务端地址>:443
cert = /etc/stunnel/ssl/test/fullchain.pem
key  = /etc/stunnel/ssl/test/key.pem
EOF
```

> 提示: 与服务端配置的区别就是多了一个 `client = yes` 的配置项
