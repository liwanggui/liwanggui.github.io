# 网络文件系统（NFS）


NFS 允许系统通过网络与他人共享目录和文件。通过使用 NFS，用户和程序可以访问远程系统上的文件，就好像它们是本地文件一样。

NFS 可以提供的一些最显著的好处是：

- 本地工作站使用较少的磁盘空间，因为常用数据可以存储在单台计算机上，并且仍然可以通过网络为其他人访问。
- 用户无需在每个网络机器上单独拥有 home 目录。home 目录可在 NFS 服务器上设置，并在整个网络中提供。
- 软盘、CDROM 驱动器和 USB 拇指驱动器等存储设备可用于网络上的其他计算机。这可能会减少整个网络中的可移动媒体驱动器的数量。

## 安装

在终端提示下输入以下命令以安装 NFS 服务器：

```bash
# ubuntu
sudo apt install nfs-kernel-server

# centos
sudo yum install nfs-utils
```

要启动 NFS 服务器，您可以在终端提示下运行以下命令：

```bash
# ubuntu
sudo systemctl start nfs-kernel-server.service

# centos
sudo systemctl start nfs-server.service
```

## 配置

您可以通过将目录添加到 NFS 配置文件中来配置要共享的目录。默认配置文件：`/etc/exports`

```
/srv     *(ro,sync,subtree_check)
/scratch *(rw,sync,no_subtree_check,no_all_squash,no_root_squash,insecure)
```

**参数解释:**

- `ro` 该主机对该共享目录有只读权限
- `rw` 该主机对该共享目录有读写权限
- `root_squash` 客户机用root用户访问该共享文件夹时，将root用户映射成匿名用户
- `no_root_squash` 将客户端使用的是root用户时，则映射到FNS服务器的用户依然为root用户。
- `all_squash` 客户机上的任何用户访问该共享目录时都映射成匿名用户
- `anonuid` 将客户机上的用户映射成指定的本地用户ID的用户
- `anongid` 将客户机上的用户映射成属于指定的本地用户组ID
- `sync` 资料同步写入到内存与硬盘中
- `async` 资料会先暂存于内存中，而非直接写入硬盘
- `secure` NFS客户端必须使用NFS保留端口（通常是1024以下的端口），默认选项。
- `insecure` 允许NFS客户端不使用NFS保留端口（通常是1024以上的端口）

确保已创建您添加的任何自定义安装点（`/srv` 和 `/scratch` 将存在）：

```bash
sudo mkdir /srv /scratch
```

> 注意: 为了让客户机对目录有可读可写权限，给目录赋于 777 权限

重载 NFS 配置文件

```bash
sudo exportfs -r
```

NFS 常用命令

```bash
exportfs -v             #查看详细的 NFS 信息
exportfs -r             #重读配置文件
showmount -e            #查看本机发布的 NFS 共享目录
showmount -e +IP        #查看 IP 地址发布的 NFS 共享目录
showmount -a +IP        #查看有哪些 NFS 客户端挂载了 NFS 服务器上的共享目录
rpcinfo -p localhost    #查看rpc注册的端口信息
```

您可以用具体的主机名替换 `*`。 使主机名声明尽可能具体。

同步/异步选项可控制更改是否在回复请求之前被限制为稳定存储。因此，async 会带来性能优势，但可能会造成数据丢失或损坏。尽管同步是默认的，但值得设置，因为如果未指定，`exportfs` 将发出警告。

`subtree_check` 和 `no_subtree_check` 启用或禁用安全验证，即客户端尝试为 `exported` 文件系统安装的子指示器是允许他们进行的安全验证。此验证步骤对某些使用案例（例如文件重命名频繁的家庭目录）有一些性能影响。仅读文件系统更适合启用 `subtree_check` 。与同步一样，如果未指定，`exportfs` 将发出警告。

NFS 有许多可选设置，用于调整性能、加强安全性或提供便利。这些设置各有其自身的权衡，因此谨慎使用它们非常重要，仅针对特定用例需要。例如， `no_root_squash` 增加了便利性，允许任何客户端系统的根用户修改根拥有的文件：在允许在共享安装点上执行可执行项的多用户环境中，这可能导致安全问题。`noexec` 阻止可执行文件从安装点运行。

## NFS 客户端配置

要启用客户端系统的 NFS 支持，请在终端提示下输入以下命令：

```bash
# ubuntu
sudo apt install nfs-common

# centos
sudo yum install nfs-utils
```

使用 `mount` 命令从另一台机器上挂载共享的 NFS 目录，在终端提示处键入类似于以下命令行：

```bash
sudo mkdir /opt/example
sudo mount example.hostname.com:/srv /opt/example
```

## 警告

挂载点目录必须存在。目录中不应有任何文件或子目录，否则它们将无法访问，直到 nfs 文件系统卸载。`/opt/example/opt/example`

挂载 NFS 共享目录的另一种方法是向 `/etc/fstab` 文件添加一行配置。该行必须说明 NFS 服务器的主机名、及 NFS 共享目录的路径(在 NFS 服务器上的路径)。

`/etc/fstab` 配置如下

```
example.hostname.com:/srv /opt/example nfs nolock,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport 0 0
```

**挂载命令参数说明:**

- `proto`: 指定使用的协议，默认为 udp
- `rsize`：定义数据块的大小，用于客户端与文件系统之间读取数据。建议值：1048576
- `wsize`：定义数据块的大小，用于客户端与文件系统之间写入数据。建议值：1048576
- `timeo`：指定时长，单位为0.1秒，即NFS客户端在重试向文件系统发送请求之前等待响应的时间。建议值：600（60秒）
- `retrans`：NFS客户端重试请求的次数。建议值：2。
- `noresvport`：在网络重连时使用新的TCP端口，保障在网络发生故障恢复时不会中断连接。建议启用该参数。
- `_netdev`: 防止客户端在网络就绪之前开始挂载文件系统。

