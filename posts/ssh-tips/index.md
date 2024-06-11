# SSH 使用小技巧


## 取消初次连接确认

在脚本中有时会使用 ssh 进行远程连接操作，如果是第一次 ssh 连接往往会提示你是否确认连接并要求你输入 yes, 才能继续。如何才能避免这个步骤呢？

**1. 通过 `.ssh/config` 配置文件**

```bash
cat >> ~/.ssh/config << EOF
StrictHostKeyChecking no
EOF
```

**2. 在 ssh 命令加上一个参数**

```bash
ssh username@ip_address -p 22 -o StrictHostKeyChecking=no
```

## SSH 密钥

**通过私钥计算公钥**

```bash
ssh-keygen.exe -f ~/.ssh/id_rsa -y 
```

**查看公钥的指纹**

```bash
ssh-keygen.exe -f ~/.ssh/id_rsa.pub -l
```

## SSH agent 转发

通过 OpenSSH 的 agent 转发功能，我们可以从 A 服务器直接连接 B 服务器而不需要将私钥放在 A 服务器

> 前提条件 A，B 服务器上 authorized_keys 文件中有相同的钥，使用这个公钥的私钥进行连接.

**通过 `.ssh/config` 配置文件**

写入如下配置, 然后正常连接服务器即可

```bash
cat >> ~/.ssh/config << EOF
Host example.cn
  ForwardAgent yes
EOF
```

**命令行方式**

```bash
> ssh-add -K ~/.ssh/id_rsa
> ssh -A root@example.cn
```

- `-A`：启动 agent 转发，具体可以 `man ssh`

默认 SSH 是启动 agent 的。如果不成功请检查 `/etc/ssh/sshd_config` 配置文件 `AllowAgentForwarding` 选项及 `/etc/ssh/ssh_config` 文件是否有 `ForwardAgent no` 配置项，改为 yes 即可。

## ssh 代理设置

实验环境

- Server： 192.168.0.1
- Gateway: 100.100.100.100
- Client: 100.100.100.101

> 说明：其中 `Server` 不可以访问外网; 

- `Gateway` 可以访问 `Server`， 同时与外网互通;  
- `Client` 不能直接访问 `Server` 需要先连接 `Gateway` 才可以访问 `Server`。

### ssh 端口转发

ssh 端口转发功能，实现 `Clinet` 直接访问 `Server`, 在 `Gateway` 执行命令如下：

```bash
ssh -CfNg -L 2233:192.168.0.1:22 root@192.168.0.1
```

> 解释： `-L` 是本地端口转发，通过将本地 `2233` 与 `Server` 的 `22` 端口相关联，以使 `Client` 访问 `2233` 时自动转发到 `Server` 的 `22` 端口。


### ssh ProxyCommand

通过配置 `~/.ssh/config` 文件也可以达到 `ssh` 代理的功能，具体配置如下（在 `Client` 上配置）

```bash
[root@localhost ~]# vim .ssh/config
Host server
    HostName 192.168.0.1
    Port 22
    ProxyCommand ssh -l root -p 22 100.100.100.100 -W %h:%p
    IdentityFile /root/.ssh/id_rsa
# 配置好后，就可以直接通过以下命令连接 Server
[root@localhost ~]# ssh root@server
```

说明

- Host 别名，取一个主别名
- HostName 主机的ip地址，在此例中是 `Server` 的 `ip` 地址，也可以是域名
- ProxyCommand ssh 代理的命令 `-W` 后面是 `Server` 的 `ip` 地址及端口，会自动替换
- IdentityFile 表示连接使用的私钥

### ssh 命令行实现中转代理

当然我们也可以不写配置文件直接通过命令也是可以进行 `ssh` 代理跳转的，命令如下：

```bash
ssh -t -p 22 userb@123.456.789.110 "ssh userc@192.168.1.111"
```

> 注： 因为 `ssh` 是可以直接远程执行命令的, 不可以少 `-t` 参数

### ssh socket5 代理

执行以下命令就可以创建一个基于 `ssh` 的 `socket5` 代理了,最好将此放入后台运行。

```bash
ssh -D 8080 -f -C -q -N fred@server.example.org
# 放入后台运行
nohup ssh -D 8080 -f -C -q -N fred@server.example.org &
```


