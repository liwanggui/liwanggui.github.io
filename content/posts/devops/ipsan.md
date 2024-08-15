---
title: "部署 iSCSI 存储区域网络（SAN）"
date: 2024-08-15T14:18:13+08:00
draft: false
categories: 
- devops
tags:
- san
---

SAN（Storage Area Network，存储区域网络），是一种基于块存储的存储方式。SAN是一种将存储设备，连接设备和接口集成在一个高速网络中的技术。SAN本身就是一个存储网络，承担了数据存储任务，SAN网络与LAN业务相互隔离，存储数据流不会占用业务带宽


## 一、在存储服务器上配置 iSCSI 目标

准备好一块盘: `/dev/sdb`

### 1. 安装 iSCSI Target 软件

```bash
yum install targetcli
```

### 2. 启动并启用 target 服务

确保 iSCSI target 服务在系统启动时自动运行。

```bash
systemctl enable --now target.service
```

### 3. 使用 targetcli 创建iSCSI目标

进入 `targetcli` 的交互式环境，开始配置iSCSI目标。

```bash
[root@test-01 ~]# targetcli
targetcli shell version 2.1.53
Copyright 2011-2013 by Datera, Inc and others.
For help on commands, type 'help'.

# 创建存储后端（Backstore）
/> /backstores/block create name=block1 dev=/dev/sdb
Created block storage object block1 using /dev/sdb.

# 创建iSCSI目标  
# iqn.2024-08.com.liwanggui-iscsi:storage1 是 iSCSI 名称，可以根据实际情况修改
/> /iscsi create wwn=iqn.2024-08.com.liwanggui-iscsi:storage1
Created target iqn.2024-08.com.liwanggui-iscsi:storage1.
Created TPG 1.
Global pref auto_add_default_portal=true
Created default portal listening on all IPs (0.0.0.0), port 3260.

# 将后端设备添加到iSCSI目标
/> /iscsi/iqn.2024-08.com.liwanggui-iscsi:storage1/tpg1/luns create /backstores/block/block1
Created LUN 0.

# 授权访问客户端 iqn.2024-08.com.liwanggui-iscsi:client1
/> /iscsi/iqn.2024-08.com.liwanggui-iscsi:storage1/tpg1/acls create iqn.2024-08.com.liwanggui-iscsi:client1
Created Node ACL for iqn.2024-08.com.liwanggui-iscsi:client1
Created mapped LUN 0.

# 退出 targetcli， 保存配置
/> exit
Global pref auto_save_on_exit=true
Last 10 configs saved in /etc/target/backup/.
Configuration saved to /etc/target/saveconfig.json

```

## 二、在客户端配置 iSCSI 启动器

### 1. 在客户端上安装 iSCSI Initiator 工具。

```bash
yum install iscsi-initiator-utils -y
```

### 2. 启动并启用 iscsid 服务

确保 iSCSI 启动器服务在系统启动时自动运行

```bash
systemctl enable --now iscsid.service
```

### 3. 配置 iSCSI Initiator 名称

编辑配置文件 `/etc/iscsi/initiatorname.iscsi`，设置启动器的IQN名称（使用 `iqn.2024-08.com.liwanggui-iscsi:client1`）

```bash
InitiatorName=iqn.2024-08.com.liwanggui-iscsi:client1
```

重启 `iscsiad` 服务

```bash
systemctl restart iscsid.service
```

### 4. 发现并连接 iSCSI 目标

使用目标服务器的IP地址发现可用的 iSCSI 目标

```bash
iscsiadm -m discovery -t sendtargets -p <Target_IP_Address>
```

> 将 `<Target_IP_Address>` 替换为目标服务器的IP地址, 例如:  192.168.110.106:3260

### 5. 登录 iSCSI 目标

连接到发现的目标：

```bash
[root@test-02 ~]# iscsiadm -m node --targetname iqn.2024-08.com.liwanggui-iscsi:storage1 --portal 192.168.110.106:3260 --login
Logging in to [iface: default, target: iqn.2024-08.com.liwanggui-iscsi:storage1, portal: 192.168.110.106,3260]
Login to [iface: default, target: iqn.2024-08.com.liwanggui-iscsi:storage1, portal: 192.168.110.106,3260] successful.
```

查看设备连接情况

```bash
[root@test-02 ~]# lsblk
NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda            8:0    0   200G  0 disk
├─sda1         8:1    0   600M  0 part /boot/efi
├─sda2         8:2    0     1G  0 part /boot
└─sda3         8:3    0 198.4G  0 part
  ├─uos-root 253:0    0    50G  0 lvm  /
  └─uos-data 253:1    0 148.4G  0 lvm  /data
sdb            8:16   0    10G  0 disk    # iSCSI 设备
```

### 6. 格式化并挂载iSCSI LUN

使用 `lsblk` 或 `fdisk -l` 命令查看新的 iSCSI 磁盘。

```bash
[root@test-02 ~]# mkfs.ext4 /dev/sdb
[root@test-02 ~]# mount /dev/sdb /mnt/
[root@test-02 ~]# df -hl
Filesystem            Size  Used Avail Use% Mounted on
/dev/sdb              9.8G   24K  9.3G   1% /mnt
...
```

配置 /etc/fstab 文件，以便在系统重启时自动挂载 iSCSI 磁盘。

```
/dev/sdb                /mnt                    ext4    _netdev         0 0
```

> 注意； `_netdev` ：这个选项告诉系统，这个设备是通过网络连接的，必须等到网络设备启动后才能挂载。


## 三、卸载 iSCSI 磁盘

1. 首先，确保设备不再被使用。卸载挂载点以确保文件系统的安全: `umount /mnt`
2. 从 `/etc/fstab` 中删除条目, 如果你之前在/etc/fstab中配置了自动挂载，需要删除或注释掉相关条目
3. 断开 iSCSI 会话
    查看当前连接的会话：
    
    ```bash
    iscsiadm -m session -P 3
    ```
    
    登出iSCSI会话
    
    ```bash
    iscsiadm -m node --targetname <Target_IQN> --portal <Target_IP_Address>:3260 --logout
    ```
    > 替换 `<Target_IQN>` 为目标的IQN，`<Target_IP_Address>` 为目标服务器的IP地址
    
    删除 iSCSI 目标配置, 为了确保在下一次系统启动时不再尝试连接，可以删除本地 iSCSI 配置

    ```bash
    iscsiadm -m node --targetname <Target_IQN> --portal <Target_IP_Address>:3260 --op delete
    ```

## 四、其他

在 SAN（存储区域网络）环境中，网络单点故障可能导致严重的服务中断。为了提高SAN的可靠性，可以通过以下几种方法来解决网络单点故障问题

1. 使用多路径I/O（Multipath I/O, MPIO）: `yum install device-mapper-multipath`
2. 使用冗余网络链路
