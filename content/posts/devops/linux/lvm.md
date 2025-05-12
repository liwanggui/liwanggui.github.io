---
title: "使用 LVM 管理硬盘空间"
date: 2021-12-16T10:22:01+08:00
draft: false
categories: 
- devops
tags:
- lvm
---

为虚拟机挂载一块新硬盘，用于实验（`/dev/sdb`）

```bash
[root@localhost ~]# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   20G  0 disk
├─sda1            8:1    0    1G  0 part /boot
└─sda2            8:2    0   19G  0 part
  ├─centos-root 253:0    0   17G  0 lvm  /
  └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
sdb               8:16   0   20G  0 disk
sr0              11:0    1  906M  0 rom
```

## 创建 PV

```bash
pvcreate /dev/sdb
```

## 加入 VG

查看 VG 

```bash
[root@localhost ~]# vgdisplay
  --- Volume group ---
  VG Name               centos
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  3
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               2
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <19.00 GiB
  PE Size               4.00 MiB
  Total PE              4863
  Alloc PE / Size       4863 / <19.00 GiB
  Free  PE / Size       0 / 0
  VG UUID               85pJBT-lfvE-sptt-ywZF-j8Ya-m1Xg-ch4Qyf
```

将新硬盘加入 `centos` VG 中

```bash
[root@localhost ~]# vgextend centos /dev/sdb
  Volume group "centos" successfully extended
```

再次查看 VG 

```bash
[root@localhost ~]# vgdisplay
  --- Volume group ---
  VG Name               centos
  System ID
  Format                lvm2
  Metadata Areas        2
  Metadata Sequence No  4
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               2
  Max PV                0
  Cur PV                2
  Act PV                2
  VG Size               38.99 GiB
  PE Size               4.00 MiB
  Total PE              9982
  Alloc PE / Size       4863 / <19.00 GiB
  Free  PE / Size       5119 / <20.00 GiB
  VG UUID               85pJBT-lfvE-sptt-ywZF-j8Ya-m1Xg-ch4Qyf
```

> 通过上面的信息可以看出 VG 容量扩大了

## 创建 LV

查看现有的 lv 卷

```bash
[root@localhost ~]# lvdisplay
  --- Logical volume ---
  LV Path                /dev/centos/swap
  LV Name                swap
  VG Name                centos
  LV UUID                52CL0Y-FldW-4wuO-fV1s-qtAl-oKR5-vPI2uZ
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2021-09-10 12:03:59 +0800
  LV Status              available
  # open                 2
  LV Size                2.00 GiB
  Current LE             512
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:1

  --- Logical volume ---
  LV Path                /dev/centos/root
  LV Name                root
  VG Name                centos
  LV UUID                QL4fK3-RjZ0-5XXd-ghsm-W0DQ-Gp3m-A4z45J
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2021-09-10 12:03:59 +0800
  LV Status              available
  # open                 1
  LV Size                <17.00 GiB
  Current LE             4351
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
```

> 目前只有 swap 和 root 两个 lv

创建新的 lv 卷（test_lv）

```bash
[root@localhost ~]# lvcreate -L 5G -n test_lv centos
  Logical volume "test_lv" created.
```

查看 test_lv

```bash
[root@localhost ~]# lvdisplay /dev/centos/test_lv
  --- Logical volume ---
  LV Path                /dev/centos/test_lv
  LV Name                test_lv
  VG Name                centos
  LV UUID                qUnC6d-dyn0-7f0C-TC3B-dmi1-ncwF-30CJug
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2021-12-16 10:36:54 +0800
  LV Status              available
  # open                 0
  LV Size                5.00 GiB
  Current LE             1280
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:2
```

使用 test_lv

```bash
[root@localhost ~]# mkfs.ext4 /dev/centos/test_lv
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
327680 inodes, 1310720 blocks
65536 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=1342177280
40 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736

Allocating group tables: done
Writing inode tables: done
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done

[root@localhost ~]# mkdir /test
[root@localhost ~]# mount /dev/centos/test_lv /test
[root@localhost ~]# lsblk
NAME             MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                8:0    0   20G  0 disk
├─sda1             8:1    0    1G  0 part /boot
└─sda2             8:2    0   19G  0 part
  ├─centos-root  253:0    0   17G  0 lvm  /
  └─centos-swap  253:1    0    2G  0 lvm  [SWAP]
sdb                8:16   0   20G  0 disk
└─centos-test_lv 253:2    0    5G  0 lvm  /test
sr0               11:0    1  906M  0 rom
# 为了开机自动挂载，将挂载信息写入 /etc/fstab 文件中
[root@localhost ~]# echo '/dev/centos/test_lv /test  ext4 defaults 0 0' >> /etc/fstab
```

## 动态 lv 扩容

现在需要对 root lv 进行动态扩容，vg 中剩余的所有空间都分给 root lv，操作步骤如下

查看 vg 

```bash
[root@localhost ~]# vgdisplay
  --- Volume group ---
  VG Name               centos
  System ID
  Format                lvm2
  Metadata Areas        2
  Metadata Sequence No  7
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                3
  Open LV               3
  Max PV                0
  Cur PV                2
  Act PV                2
  VG Size               38.99 GiB
  PE Size               4.00 MiB
  Total PE              9982
  Alloc PE / Size       6143 / <24.00 GiB
  Free  PE / Size       3839 / <15.00 GiB
  VG UUID               85pJBT-lfvE-sptt-ywZF-j8Ya-m1Xg-ch4Qyf
```

> 通过上面的信息可以看出，还有 15G 剩余空间可以供分配 (3839 个 PE, 一个 PE 大小为 4M )

现在将 VG 剩余所有空间分配给 root lv

```bash
[root@localhost ~]# lvextend -l +100%FREE /dev/centos/root
  Size of logical volume centos/root changed from <17.00 GiB (4351 extents) to 31.99 GiB (8190 extents).
  Logical volume centos/root successfully resized.
```

- `-l +100%FREE` 表示使用卷组中所有剩余的自由空间。
- `/dev/centos/root` 是逻辑卷的路径，确保使用正确的路径

> 提示: 如果想分配后刷新分表区信息，需要加入 `-r` 参数

查看 root lv 信息

```bash
[root@localhost ~]# lvdisplay /dev/centos/root
  --- Logical volume ---
  LV Path                /dev/centos/root
  LV Name                root
  VG Name                centos
  LV UUID                QL4fK3-RjZ0-5XXd-ghsm-W0DQ-Gp3m-A4z45J
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2021-09-10 12:03:59 +0800
  LV Status              available
  # open                 1
  LV Size                31.99 GiB
  Current LE             8190
  Segments               2
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
```

再通过 df 查看

```bash
[root@localhost ~]# df -hl
Filesystem                  Size  Used Avail Use% Mounted on
/dev/mapper/centos-root      17G  1.5G   16G   9% /
devtmpfs                    224M     0  224M   0% /dev
tmpfs                       236M     0  236M   0% /dev/shm
tmpfs                       236M  5.5M  230M   3% /run
tmpfs                       236M     0  236M   0% /sys/fs/cgroup
/dev/sda1                  1014M  130M  885M  13% /boot
tmpfs                        48M     0   48M   0% /run/user/0
/dev/mapper/centos-test_lv  4.8G   20M  4.6G   1% /test
```

> 可以看出硬盘空间分配成功，但没有刷新

刷新分区信息

```bash
[root@localhost ~]# resize2fs -f /dev/centos/root
resize2fs 1.42.9 (28-Dec-2013)
resize2fs: Bad magic number in super-block while trying to open /dev/centos/root
Couldn't find valid filesystem superblock.
```

> 我们使用 `resize2fs` 命令刷新分区信息出错，这是由于 root lv 的文件系统为 xfs 需要使用 `xfs_growfs` 命令

```bash
[root@localhost ~]# xfs_growfs /dev/centos/root
meta-data=/dev/mapper/centos-root isize=512    agcount=4, agsize=1113856 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0 spinodes=0
data     =                       bsize=4096   blocks=4455424, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal               bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 4455424 to 8386560
```

再次 `df -hl` 查看大小

```bash
[root@localhost ~]# df -hl
Filesystem                  Size  Used Avail Use% Mounted on
/dev/mapper/centos-root      32G  1.5G   31G   5% /
devtmpfs                    224M     0  224M   0% /dev
tmpfs                       236M     0  236M   0% /dev/shm
tmpfs                       236M  5.5M  230M   3% /run
tmpfs                       236M     0  236M   0% /sys/fs/cgroup
/dev/sda1                  1014M  130M  885M  13% /boot
tmpfs                        48M     0   48M   0% /run/user/0
/dev/mapper/centos-test_lv  4.8G   20M  4.6G   1% /test
```

> root lv 的容量大小已刷新成功了