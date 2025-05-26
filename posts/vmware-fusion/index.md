# VMware Fusion 自定义网络地址段


macOS 版本 VMware Fusion 虚拟机软件没有像 Windows 那样提供图形化网络配置界面, 当我们需要自定义网络地址段时需要手动编辑配置文件实现

VMware Fusion 有三个网络配置文件：networking、dhcpd.conf 和 nat.conf, 下面介绍如何进行修改

```bash
# 全局网络配置文件
/Library/Preferences/VMware Fusion/networking
# vmnet1 配置文件
/Library/Preferences/VMware Fusion/vmnet1/dhcpd.conf
# vmnet8 配置文件
/Library/Preferences/VMware Fusion/vmnet8/dhcpd.conf
/Library/Preferences/VMware Fusion/vmnet8/nat.conf
```

> 实验版本: VMware Fusion 12.2.3

## 停止 vmnet 网络服务(可选)

```bash
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --stop
```

## 修改 networking 配置文件

```bash
sudo vim /Library/Preferences/VMware\ Fusion/networking
```

*示例配置, 将 vmnet8 网络地址段配置为 192.168.1.0/24*

```
VERSION=1,0
answer VNET_1_DHCP yes
answer VNET_1_DHCP_CFG_HASH BC187B729C7F983F84061DBC24546E7A35EAC1F7
answer VNET_1_HOSTONLY_NETMASK 255.255.255.0
answer VNET_1_HOSTONLY_SUBNET 172.16.77.0
answer VNET_1_HOSTONLY_UUID AEDCBA4E-12EA-4C77-B679-B304941910A2
answer VNET_1_VIRTUAL_ADAPTER yes
answer VNET_8_DHCP yes
answer VNET_8_DHCP_CFG_HASH A24D08B25A27C942354C5C1BBC4B18F2154C43F3
answer VNET_8_HOSTONLY_NETMASK 255.255.255.0
answer VNET_8_HOSTONLY_SUBNET 168.168.1.0
answer VNET_8_HOSTONLY_UUID B2D4FBA6-CACA-4EE5-BDF2-ADFBD22FBF06
answer VNET_8_NAT yes
answer VNET_8_VIRTUAL_ADAPTER yes
```

## 配置网络

通过以下命令重新生成 vmnet8 的网络配置文件

```bash
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --configure
```

## 启动网络服务

```bash
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --start
```

## 验证

打开虚拟机将网卡模式配置为 DHCP，自动获取 IP 后, 通过以下命令验证

```bash
ifconfig 
# or
ip addr
```

> 也可以通过在宿主机上查看到虚拟网卡的 ip 验证
