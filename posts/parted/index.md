# 使用 parted 对 gpt 磁盘分区


## 安装 parted 工具

```shell
[root@localhost ~]# yum install parted
# 包含以下命令
[root@localhost ~]# rpm -ql parted  | grep bin
/sbin/parted   # 分区工具
/sbin/partprobe   # 分区表刷新工具
```

## 使用 parted 分区

```shell
[root@localhost ~]# parted /dev/sdb
GNU Parted 2.1
Using /dev/sdb
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) mklabel gpt  # 设置硬盘分区表
Warning: The existing disk label on /dev/sdb will be destroyed and all data on this disk will be lost. Do you want to continue?
Yes/No? yes
(parted) mkpart  # 开始分区
Partition name?  []? 1  # 分区表名
File system type?  [ext2]? ext4   # 文件系统类型
Start? 1    # 分区空间起始位置
End? 2G     # 分区空间结束位置
(parted) mkpart
Partition name?  []? 2
File system type?  [ext2]? ext4
Start? 2G   # 这个位置是上分区的结束位置大小
End? 12G    # 这个分区的大小加上起始位置就是结束位置大小
(parted) p
Model: VMware, VMware Virtual S (scsi)
Disk /dev/sdb: 21.5GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt

Number  Start   End     Size    File system  Name  Flags
 1      1049kB  2000MB  1999MB               1
 2      2000MB  12.0GB  10.0GB               2

```

## 脚本化分区

设置 /dev/sdb 分区表为 gpt, 将所有空间划为一个分区，分区名称为 d1

```bash
parted -s /dev/sdb mklabel gpt
parted -s /dev/sdb mkpart d1 1 100%
```

