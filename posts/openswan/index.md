# 配置 openswan ipsecvpn


## 实验环境

- VPC1:`192.168.1.1`
- VPC2:`192.168.2.2`

## 安装 openswan

```bash
[root@wglee ~]# yum install openswan
```

## 编辑 `/etc/ipsec.conf ` 文件，启用 `/etc/ipsec.d/*.conf`

```bash
[root@wglee ~]# sudo vi /etc/ipsec.conf

# /etc/ipsec.conf - Openswan IPsec configuration file
#
# Manual: ipsec.conf.5
#
# Please place your own config files in /etc/ipsec.d/ ending in .conf

version 2.0 # conforms to second version of ipsec.conf specification

# basic configuration
config setup
    # Debug-logging controls: "none" for (almost) none, "all" for lots.
    # klipsdebug=none
    # plutodebug="control parsing"
    # For Red Hat Enterprise Linux and Fedora, leave protostack=netkey
    protostack=netkey
    nat_traversal=yes
    virtual_private=
    oe=off
    # Enable this if you see "failed to find any available worker"
    # nhelpers=0

#You may put your configuration (.conf) file in the "/etc/ipsec.d/" and uncomment this.
include /etc/ipsec.d/*.conf
```

## 在 /etc/ipsec.d 目录创建以下文件

**配置VPC1**

```bash
[root@wglee ~]# sudo vi /etc/ipsec.d/vpc1-to-vpc2.conf
conn vpc1-to-vpc2
    type=tunnel
    authby=secret
    left=%defaultroute
    leftid=<VPC1的外网IP>
    leftnexthop=%defaultroute
    leftsubnet=<VPC1 子网地址>
    right=<VPC2的外网IP>
    rightsubnet=<VPC2 子网地址>
    pfs=yes
    auto=start
[root@wglee ~]# sudo vi /etc/ipsec.d/vpc1-to-vpc2.secrets
<VPC1 子网地址> <VPC1 子网地址>: PSK "Put a Preshared Key here!!"
```

**配置VPC2**

```bash
[root@wglee ~]# sudo vi /etc/ipsec.d/vpc2-to-vpc1.conf
conn vpc2-to-vpc1
    type=tunnel
    authby=secret
    left=%defaultroute
    leftid=<VPC2的外网IP>
    leftnexthop=%defaultroute
    leftsubnet=<VPC2 的子网地址>
    right=<EIP1>
    rightsubnet=<VPC1 的子网地址>
    pfs=yes
    auto=start
[root@wglee ~]# sudo vi /etc/ipsec.d/vpc2-to-vpc1.secrets
<VPC2 的子网地址> <VPC1 的子网地址>: PSK "Put a Preshared Key here!!"
```

## 启动 IPSec/Openswan

```bash
[root@wglee ~]# sudo service ipsec start
# Configure IPSec/Openswan to always start on boot
[root@wglee ~]# sudo chkconfig ipsec on
```

## 编辑 /etc/sysctl.conf

```bash
[root@wglee ~]# sudo vi /etc/sysctl.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
```

## 重启网络

```bash
[root@wglee ~]# service network restart
```

## 检查 VPN 状态

```bash
#下面的命令可以在检查或故障排除VPN状态有所帮助：
[root@wglee ~]# sudo ipsec verify

#会检查所需的OpenSWAN的服务状态正常运行
[root@wglee ~]# sudo service ipsec status
#检查OpenSWAN服务的状态和VPN隧道
```

> 来源： <https://aws.amazon.com/articles/5472675506466066>
