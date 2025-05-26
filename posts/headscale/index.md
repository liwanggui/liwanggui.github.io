# Headscale - 异地组网


## 简介

[headscale](https://github.com/juanfont/headscale) 是 tailscale 的开源自托管的实现，更多信息请参考以下链接

- [Headscale 文档](https://headscale.net/stable/)
- [Tailscale 文档](https://tailscale.com/kb/1017/install)

**同类产品**

- [Netbird](https://github.com/netbirdio/netbird): 使用内核 WireGuard，有完整管理界面，开源且可以自行部署，部署方法查看[文档](https://docs.netbird.io/selfhosted/selfhosted-quickstart)
- [Netmaker](https://github.com/gravitl/netmaker): 与 Netbird 类似，有完整管理界面，开源且可以自行部署，部署方法查看[文档](https://docs.netmaker.io/docs/server-installation/quick-install#quick-install-script)

> 注: headscale、netbird、netmaker 中 headscale 最轻量

## 安装

headscale 支持适用于 Debian 和 Ubuntu 的 DEB 软件包和二进制包安装，本文以二进行包为例进行安装

### 1. 下载符合当前系统的二进制包包

```bash
sudo wget --output-document=/usr/bin/headscale \
https://github.com/juanfont/headscale/releases/download/v<HEADSCALE VERSION>/headscale_<HEADSCALE VERSION>_linux_<ARCH>
```

### 2. 赋于 headscale 执行权限

```bash
sudo chmod +x /usr/bin/headscale
```

### 3. 创建运行用户

添加专用本地用户来运行 headscale 

```bash
sudo useradd \
 --create-home \
 --home-dir /var/lib/headscale/ \
 --system \
 --user-group \
 --shell /usr/sbin/nologin \
 headscale
```

### 4. 创建配置文件

下载你所选版本的[示例配置](https://headscale.net/stable/ref/configuration/)并将其保存为: `/etc/headscale/config.yaml`，请根据你的本地环境调整配置

```bash
sudo mkdir -p /etc/headscale
sudo vim /etc/headscale/config.yaml
```

> 提示: 示例配置文件在仓库的根目录下，文件名为 config-example.yaml

### 5. 创建 Systemd 配置

将 [headscale 的 systemd 服务文件](https://headscale.net/stable/packaging/headscale.systemd.service) 复制到 `/etc/systemd/system/headscale.service` 并根据本地设置进行调整。以下参数可能需要修改：`ExecStart`、`WorkingDirectory`、`ReadWritePaths`

```bash
sudo wget --output-document=/etc/systemd/system/headscale.service \
https://headscale.net/stable/packaging/headscale.systemd.service
```

### 6. 配置 unix 套接字

在 `/etc/headscale/config.yaml` 中，使用 headscale 用户或组可写入的路径覆盖默认的 headscale unix 套接字

```yaml
unix_socket: /var/run/headscale/headscale.sock
```

### 7. 重载 systemd 

重新加载 systemd 以加载新的配置文件

```bash
systemctl daemon-reload
```

### 8. 开启 headscale 服务

启用并启动新的 headscale 服务

```bash
systemctl enable --now headscale
```

### 9. 验证 headscale 

验证 headscale 是否按预期运行

```bash
systemctl status headscale
```

## 使用入门

### 1. 创建用户

```bash
headscale users create <USER>
```

### 2. 查看用户

```bash
headscale users list
```

### 3. 交互式，注册节点

headscale 兼容 tailscale 客户端工具，所以直接使用 tailscale 客户端软件即可，[软件下载地址](https://tailscale.com/download)

```bash
tailscale up --login-server <YOUR_HEADSCALE_URL>

To authenticate, visit:

        <YOUR_HEADSCALE_URL>/register/nMpEDpqK25qxM51GsvZd37lr
```

按终端提示打开链接，复制页面命令 <span style="color: red;"> (将 USERNAME 修改为之前创建的用户名) </span>。在 Headscale 服务器上批准并注册该节点

```bash
headscale nodes register --user USERNAME --key nMpEDpqK25qxM51GsvZd37lr
```

### 4. 使用预授权密钥，注册节点

生成预授权密钥并以非交互方式注册节点。
首先，在 Headscale 实例上生成预授权密钥。默认情况下，
该密钥有效期为一小时，且只能使用一次（其他选项请参阅 `headscale preauthkeys --help` 命令）：

```bash
headscale preauthkeys create --user <USER>
```

该命令成功后将返回 preauthkey，该密钥可用于通过以下 tailscale up 命令将节点连接到 headscale 实例：

```bash
tailscale up --login-server <YOUR_HEADSCALE_URL> --authkey <YOUR_AUTH_KEY>
```

### 5. 查看所有节点

查看已注册的所有节点

```bash
headscale nodes list
```

## 部署中继服务器

在上面的 Headscale 搭建完成并添加客户端后, 某些客户端可能无法联通; 这是由于网络复杂情况下导致了 NAT 穿透失败; 为此我们可以搭建一个中继服务器来进行流量转发

[自定义 DERP 服务器](https://tailscale.com/kb/1118/custom-derp-servers)

### 1. 搭建 DERP Server

首先需要注意的是, 在需要搭建 DERP Server 的服务器上, 请先安装一个 Tailscale 客户端并注册到 Headscale; 这样做的目的是让搭建的 DERP Server 开启客户端认证, 否则你的 DERP Server 可以被任何人白嫖.

目前 Tailscale 官方并未提供 DERP Server 的安装包, 所以需要我们自行编译安装; 在编译之前请确保安装了最新版本的 Go 语言及其编译环境.

```bash
# 编译 DERP Server
go install tailscale.com/cmd/derper@latest

# 复制到系统可执行目录
sudo mv ${GOPATH}/bin/derper /usr/local/bin

# 创建用户和运行目录
sudo useradd \
        --create-home \
        --home-dir /var/lib/derper/ \
        --system \
        --user-group \
        --shell /usr/sbin/nologin \
        derper
```

创建 systemd 配置: `/lib/systemd/system/derper.service`

```ini
[Unit]
After=syslog.target
After=network.target
Description=derper coordination server for Tailscale

[Service]
Type=simple
User=derper
Group=derper
ExecStart=/usr/local/bin/derper \
            --verify-clients \
            -a :12340 \
            -c /var/lib/derper/private.key
ExecReload=/usr/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5

WorkingDirectory=/var/lib/derper
ReadWritePaths=/var/lib/derper /var/run


[Install]
WantedBy=multi-user.target
```

> 提示:  `--verify-clients`  选项用于开启客户端验证，防止 derper 服务被人白嫖 (需在机安装 tailscale 客户端并注册到 headscale)

最后使用以下命令启动 Derper Server 即可

```bash
systemctl enable derper --now
```

> 注意: 默认情况下 `Derper Server` 会监听在 `:443` 上, 同时会触发自动 ACME 申请证书. 关于证书逻辑如下:

1. 如果不指定 `-a` 参数, 则默认监听 `:443`
2. 如果监听 `:443` 并且未指定 `--certmode=manual` 则会强制使用 `--hostname` 指定的域名进行 ACME 申请证书
3. 如果指定了 `--certmode=manual` 则会使用 `--certdir` 指定目录下的证书开启 HTTPS
4. 如果指定了 `-a` 为非 `:443` 端口, 且没有指定 `--certmode=manual` 则只监听 HTTP

如果期望使用 ACME 自动申请只需要不增加 -a 选项即可(占用 443 端口), 如果期望通过负载均衡器负载, 则需要将 -a 选项指定到非 443 端口, 然后配置 Nginx、Caddy 等 LB 软件即可. 最后一点 stun 监听的是 UDP 端口, 请确保防火墙打开此端口

### 2. 配置 Headscale 

在创建完 Derper 中继服务器后, 我们还需要配置 Headscale 来告诉所有客户端在必要时可以使用此中继节点进行通信; 为了达到这个目的, 我们需要在 Headscale 服务器上创建以下配置

```yaml
regions:
  900:
    regionid: 900
    regioncode: private-derper
    regionname: "my private derper server"
    nodes:
      - name: a
        regionid: 900
        hostname: derper.xxx.com
        stunport: 3478
        derpport: 443
        ipv4: 123.13.12.11
```

> 注意: 每个区域都有一个唯一的 `region ID`。`region ID` 值 `900-999` 保留用于自定义用户指定的区域，Tailscale 不会使用。

在创建好基本的 Derper Server 节点信息配置后, 我们需要调整主配置来让 Headscale 加载

```yaml
derp:
  server:
    # 这里关闭 Headscale 默认的 Derper Server
    enabled: false
  # urls 留空, 保证不加载官方的默认 Derper
  urls: []
  # 这里填写 Derper 节点信息配置的绝对路径
  paths:
  - /etc/headscale/derper.yaml

  # If enabled, a worker will be set up to periodically
  # refresh the given sources and update the derpmap
  # will be set up.
  auto_update_enabled: true

  # How often should we check for DERP updates?
  update_frequency: 24h
```

接下来重启 Headscale 并重启 client 上的 tailscale 即可看到中继节点

```bash
> tailscale netcheck

Report:
        * Time: 2025-05-23T07:14:32.213827081Z
        * UDP: true
        * IPv4: yes, 111.11.11.11:57926
        * IPv6: no, but OS has support
        * MappingVariesByDestIP:
        * PortMapping: UPnP, NAT-PMP, PCP
        * Nearest DERP: my private derper server
        * DERP latency:
                -  xxx: 14.3ms  (my private derper server)

```

