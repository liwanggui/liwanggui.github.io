---
title: "Windows 常用 CMD 命令"
date: 2021-06-12T18:02:55+08:00
draft: false
categories: 
- windows
tags:
- cmd
---

## 用户

### 激活用户

```cmd
net user administrator /active:no
```

### 启用用户

```cmd
net user administrator /active:yes
```

### 添加用户

```cmd
net user username /add
```

### 删除用户

```cmd
net user username /del
```

## 文件共享

### 查看系统共享

```cmd
net share
```

### 删除共享

```cmd
net share 共享名  /del
```

### 映射网络驱动器

```cmd
net use H: \\192.168.31.141\public /user:samba haiersamba
```

### 删除网络驱动器

```cmd
net use /del H:
```

### 删除网络连接

```cmd
net use \\192.168.31.141 /del
```

### 删除所有网络连接

```cmd
net use * /del
```

### 查看无线 wifi 密码

```cmd
# 查看已保存的wifi列表
netsh wlan show profiles
# 查看指定wifi的密码
netsh wlan show profile TP-LINK_3E48 key=clear
```

### 重命名

```cmd
rname q.txt q.rar  //对单个文件重命名
rname *.png *.jpg  //文件批量重命名
```

### 重启资源管理器

```cmd
tskill explorer
```

## 系统服务

### 停止 Windows Update 服务

```cmd
sc stop wuauserv
```

### 禁用 Windows Update 服务

```cmd
sc config wuauserv start= disabled  //start= 等号后有一个空格
```

### 创建服务

```cmd
sc create <service name> [binPath= 程序路径] [displayname= "service name"] [start= auto ]
```
> 注意: 等号后有一个空格

### 删除服务

```cmd
sc delete <service name>
```

*服务从注册表中删除*

导航到 `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services` 中删除相应的服务名即可（不推荐）


> 注意: 在打开 `services.msc` 服务管理器的情况下，使用命令删除服务会提示标记为删除，要彻底删除请关闭服务管理器


## 网络

### 设置接口 IP 地址与 DNS

```cmd
netsh interface ip set address "接口名" static ip_address submask gateway
netsh interface ip set address "接口名" source=dhcp     //将接口设置为DHCP自动获取 `
netsh interface ip set dnsserver "接口名" static dns_ip primary
```

## 磁盘

### diskpart 分区

```cmd
shift + f10
diskpart  #启动硬盘工具
list disk  #选择磁盘
select disk 0   #选择磁盘
clean  #清除分区
convert mbr  #转换分区表
create partition primary size=102400  #创建主分区
active  #激活分区
format fs=ntfs label="new volume" quick compress  #格式化
exit
```