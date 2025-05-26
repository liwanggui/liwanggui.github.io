# 使用 nmcli 配置网络


## 配置网络

配置接口 ip 地址

```bash
nmcli connection modify eth0 ipv4.method manual \
    ipv4.address "172.16.1.100/24" \
    ipv4.geateway "172.168.1.2" \
    ipv4.dns "172.168.1.2"
```

> 以上命令会修改网卡配置文件 `/etc/sysocnfig/network-script/ifcfg-eth0`，不会立即生效

重载接口配置

```bash
nmcli connection up eth0
```

创建网络连接 eth0-1

```bash
nmcli connection add type ethernet ifname eth0 con-name eth0-1 \
        ipv4.method manual \
        ipv4.addresses 172.16.100.100/24 \
        ipv4.gateway 172.16.100.1 \
        ipv4.dns 172.16.100.1 \
        autoconnect yes
```

> 以上命令会为 `eth0` 接口新增网卡配置文件, `ifcfg-eth0-1`

切换网络连接为 eth0-1

```bash
nmcli connection up eth0-1
```

> 可以为不同的环境创建不同的网络连接配置文件，使用 `nmcli connection` 切换

删除连接

```bash
nmcli connection delete eth0-1
```

## 查看网络

查看所有接口状态

```bash
nmcli device status
```

查看 eth0 接口详细信息

```bash
nmcli device show eth0
```

停止 eth0 接口连接

```bash
nmcli connection down eth0
# or
nmcli device disconnect eth0
```

启动 eth0 接口连接

```bash
nmcli connection up eth0
# or
nmcli device connect eth0
```

