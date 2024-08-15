# PVE 重装后重新挂载 zfs 存储池及找回虚拟机


**pve 重装后找回 zfs 存储池，使用如下命令**

```bash
zpool import
zpool import -f -m data
```

**pve 重装后找回虚拟机的方法**

创建同名 `vmid` 的虚拟机，然后执行如下命令就可以了

```bash
qm disk rescan 
```

> 参考链接: https://www.right.com.cn/forum/thread-8300683-1-1.html

