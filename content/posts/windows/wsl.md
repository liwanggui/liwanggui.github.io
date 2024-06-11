---
title: "Windows linux 子系统 WSL"
date: 2023-03-10T14:15:50+08:00
draft: false
categories: 
- windows
tags:
- wsl
---

## WSL 全局配置

使用 [.wslconfig](https://learn.microsoft.com/zh-cn/windows/wsl/wsl-config#wslconfig) 为 WSL 上运行的所有已安装的发行版配置全局设置

文件路径位于：`C:\Users\<UserName>\.wslconfig`

```ini
[experimental]
autoMemoryReclaim=gradual  # gradual  | dropcache | disabled
networkingMode=mirrored    # 如果值为 mirrored，则会启用镜像网络模式。 默认或无法识别的字符串会生成 NAT 网络。
#dnsTunneling=true
firewall=true
autoProxy=true
```

## WSL 发行版配置

wsl.conf 文件会针对每个发行版配置设置

### 启用 systemd

许多 Linux 发行版（包括 Ubuntu）默认运行 “systemd”，WSL 最近添加了对此系统/服务管理器的支持，因此 WSL 更类似于在裸机上使用你最爱的 `Linux` 发行版。 需要 `WSL` 的 `0.67.6+` 版本才能启用 `systemd`。 使用命令 `wsl --version` 检查 WSL 版本

若要启用 `systemd`，请使用 `sudo` 通过管理员权限在文本编辑器中打开 `wsl.conf` 文件，并将以下行添加到 `/etc/wsl.conf`：

```ini
[boot]
systemd=true
```

> 官方文档: https://learn.microsoft.com/zh-cn/windows/wsl/wsl-config

## 开机启动并开启 SSH 服务

安装 openssh 服务，提供 ssh 远程连接

```bash
sudo apt update
sudo apt install -y openssh-server
/etc/init.d/ssh start
```

> 提示: 如开启了 systemd ，可以使用 systemd 管理 ssh 服务，命令: systemctl enable --now ssh

## 使用 cloud-init 初始化 WSL 实例

[参考文档](https://cloudinit.readthedocs.io/en/latest/tutorial/wsl.html)

### 获取 Ubuntu WSL 镜像

我们可以从 [Ubuntu 镜像服务器](https://cloud-images.ubuntu.com/wsl/) 下载 Ubuntu 24.04 WSL 镜像。

在用户主目录下创建一个目录来存储 WSL 映像和安装数据。

```powershell
mkdir ~\wsl-images
```

下载 Ubuntu 24.04 WSL 映像

```powershell
Invoke-WebRequest -Uri https://cloud-images.ubuntu.com/wsl/noble/current/ubuntu-noble-wsl-amd64-wsl.rootfs.tar.gz -OutFile wsl-images\ubuntu-noble-wsl-amd64-wsl.rootfs.tar.gz
```

将 image 导入 WSL 并将其存储在 wsl-images 目录中。

```powershell
wsl --import Ubuntu-24.04 wsl-images .\wsl-images\ubuntu-noble-wsl-amd64-wsl.rootfs.tar.gz
```

### 创建 cloud-init 初始化配置

用户数据是用户自定义 cloud-init 实例的主要方式。打开记事本并粘贴以下内容：

```yaml
#cloud-config

apt:
  sources_list: |
    Types: deb
    URIs: http://mirrors.ustc.edu.cn/ubuntu
    Suites: noble noble-updates noble-backports
    Components: main universe restricted multiverse
    Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
    
    ## Ubuntu security updates. Aside from URIs and Suites,
    ## this should mirror your choices in the previous section.
    Types: deb
    URIs: http://security.ubuntu.com/ubuntu
    Suites: noble-security
    Components: main universe restricted multiverse
    Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

package_update: true

packages:
  - openssh-client
  - openssh-server
  - git
  - wget 
  - lrzsz
  - iotop

timezone: Asia/Shanghai

write_files:
  - content: |
      [network]
      hostname = wsl2
      #generateHosts = false
      generateResolvConf = false

      [boot]
      systemd=true
    path: /etc/wsl.conf
    owner: root:root
    permissions: '0644'
  - content: |
      nameserver 180.76.76.76
      nameserver 223.5.5.5
    path: /etc/resolv.conf
    owner: root:root
    permissions: '0644'

# 默认用户
user: liwanggui

users:
- name: liwanggui
  ssh_authorized_keys:
    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjvxWX2G+cRUn5dFQr4wZEDD7QAI3lWhHLM5e....

ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjvxWX2G+cRUn5dFQr4wZEDD7QAI3lWhHLM5e....
```

将文件保存至 `%USERPROFILE%\.cloud-init\Ubuntu-24.04.user-data`

> 例如，如果您的用户名是 me，则路径为 `C:\Users\me\.cloud-init\Ubuntu-24.04.user-data`。确保文件以`.user-data`扩展名保存，而不是以`.txt`文件形式保存。


### 启动 Ubuntu WSL 实例

```powershell
wsl --distribution Ubuntu-24.04
```

### 验证是否 cloud-init 成功

在验证用户数据之前，让我们等待 cloud-init 成功完成：

```bash
cloud-init status --wait
```

其输出结果如下：

```
status: done
```

现在我们可以看到 cloud-init 已经检测到我们在 WSL 中运行：

```bash
cloud-id
```

其输出结果如下：

```
wsl
```

### 验证我们的用户数据

现在我们知道 cloud-init 已经成功运行，我们可以验证它是否收到了我们之前提供的预期用户数据：

```bash
cloud-init query userdata
```

这将在终端窗口打印以下内容：

```yaml
#cloud-config

apt:
  sources_list: |
    Types: deb
    URIs: http://mirrors.ustc.edu.cn/ubuntu
    Suites: noble noble-updates noble-backports
    Components: main universe restricted multiverse
    Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
    
    ## Ubuntu security updates. Aside from URIs and Suites,
    ## this should mirror your choices in the previous section.
    Types: deb
    URIs: http://security.ubuntu.com/ubuntu
    Suites: noble-security
    Components: main universe restricted multiverse
    Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

package_update: true

packages:
  - openssh-client
  - openssh-server
  - git
  - wget 
  - lrzsz
  - iotop

timezone: Asia/Shanghai

write_files:
  - content: |
      [network]
      hostname = wsl2
      #generateHosts = false
      generateResolvConf = false

      [boot]
      systemd=true
    path: /etc/wsl.conf
    owner: root:root
    permissions: '0644'
  - content: |
      nameserver 180.76.76.76
      nameserver 223.5.5.5
    path: /etc/resolv.conf
    owner: root:root
    permissions: '0644'

# 默认用户
user: liwanggui

users:
- name: liwanggui
  ssh_authorized_keys:
    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjvxWX2G+cRUn5dFQr4wZEDD7QAI3lWhHLM5e....

ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjvxWX2G+cRUn5dFQr4wZEDD7QAI3lWhHLM5e....
```

## WSL 开机启动

配置开机启动, 按 Win + R 键输入 "`shell:startup`" 打开启动目录，创建 `wsl-start.vbs` 文件， 内容如下

```vbs
Set ws = CreateObject("Wscript.Shell")
ws.run "wsl -d Ubuntu-22.04 -u root", vbhide
```

> 注意: `-d` 参数为你安装的 `linux` 发行版名称，使用 `wsl -l` 查看


## 故障问题

安装旧版本的 Proxifier 程序会导致 wsl 无法启动，只需要安装 Proxifier 4.x 及以上版本即可解决
