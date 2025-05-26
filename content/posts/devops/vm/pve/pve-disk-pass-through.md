---
title: "ProxmoxVE(PVE) 硬盘直通"
date: 2024-03-06T13:53:21+08:00
draft: false
categories: 
- ProxmoxVE
tags:
- ProxmoxVE
- PVE
---

> 引用源文: https://foxi.buduanwang.vip/virtualization/1754.html/

## 磁盘直通

RDM 是引用于VMware的裸磁盘映射。参考 https://kb.vmware.com/s/article/1017530?lang=zh_CN

将单个硬盘或者分区，通过 qemu 进行映射到虚拟机。在KVM上没有找到类似技术的名词，所以用 RDM 代名。

通过这种方式，硬盘会在虚拟机内会认为是一个 qemu-hdd。 RDM 磁盘直通，不需要开启 iommu。只能在 PVE 命令行中添加。

我们可以通过下面命令，列出当前的硬盘列表

`ls -la /dev/disk/by-id/ | grep -Ev 'dm|lvm|part'`

如下面的例子

```bash
root@pve:~# ls -la /dev/disk/by-id/ | grep -Ev 'dm|lvm|part'
total 0
drwxr-xr-x 2 root root 540 Apr 28 16:39 .
drwxr-xr-x 6 root root 120 Mar  3 15:52 ..
lrwxrwxrwx 1 root root  13 Apr 28 16:39 nvme-eui.01000000010000005cd2e431fee65251 -> ../../nvme2n1
lrwxrwxrwx 1 root root  13 Mar  3 15:52 nvme-eui.334843304aa010020025385800000004 -> ../../nvme1n1
lrwxrwxrwx 1 root root  13 Apr 28 17:36 nvme-eui.334843304ab005400025385800000004 -> ../../nvme0n1
lrwxrwxrwx 1 root root  13 Apr 28 16:39 nvme-INTEL_SSDPE2KX020T8_BTLJ039307142P0BGN -> ../../nvme2n1
lrwxrwxrwx 1 root root  13 Mar  3 15:52 nvme-SAMSUNG_MZWLL800HEHP-00003_S3HCNX0JA01002 -> ../../nvme1n1
lrwxrwxrwx 1 root root  13 Apr 28 17:36 nvme-SAMSUNG_MZWLL800HEHP-00003_S3HCNX0JB00540 -> ../../nvme0n1
lrwxrwxrwx 1 root root   9 Mar  3 15:52 scsi-35000c500474cd7eb -> ../../sda
lrwxrwxrwx 1 root root   9 Mar  3 15:52 wwn-0x5000c500474cd7eb -> ../../sda
```

nvme 开头的是 nvme 硬盘，ata 开头是走 sata 或者 ata 通道的设备。scsi 是 scsi 设备-阵列卡 raid 或者是直通卡上的硬盘。

我们可以通过 q`m set <vmid> --scsiX /dev/disk/by-id/xxxxxxx` 进行 RDM 直通

例如你有一个虚拟机，虚拟机的 `vmid` 是 `101`，`--scsiX`，这里的 `X` 是整数，添加硬盘的序号

如果你不清楚vmid这个是什么含义，你可以参考下面文章

[认识虚拟机VMID的作用](https://foxi.buduanwang.vip/virtualization/pve/1643.html/)

你打算直通 intel 的一个 nvme 硬盘，那么你可以使用下面命令

```bash
qm set 101 --scsi1 /dev/disk/by-id/nvme-INTEL_SSDPE2KX020T8_BTLJ039307142P0BGN
```

执行之后，你可以在面板中看到下面这个硬盘。

![alt text](/images/pve-disk-pass-through.png)

当然，你也可以使用ide或者sata形式直通硬盘，如下

```bash
qm set 101 --sata1 /dev/disk/by-id/nvme-INTEL_SSDPE2KX020T8_BTLJ039307142P0BGN

qm set 101 --ide1 /dev/disk/by-id/nvme-INTEL_SSDPE2KX020T8_BTLJ039307142P0BGN
```

建议为 scsi 设备，这样性能理论上是最优秀的。

需要注意的是，scsi 会有序号，如 scsi1，scsi0。在操作之前，应该要知道哪些 scsi 号是空的。对于 pve 来说，sata 最多有6个设备。 如果要使用 sata 类型直通，请勿超过sata5.

如果想要了解什么最多 6 个 sata，请参考: https://www.intel.com/content/dam/www/public/us/en/documents/product-briefs/q35-chipset-brief.pdf


如果需要取消直通，可以使用命令 `qm set <vmid> --delete scsiX` 

如上面的例子，你应该输入

```bash
qm set 101 --delete scsi1
```

出现 update 即代表成功。可返回网页上查看。

```bash
root@pve:~# qm set 101 --delete scsi1
update VM 101: -delete scsi1
```