---
title: "使用 VMware PowerCLI 为 Esxi 集成网卡驱动"
date: 2024-03-04T16:02:17+08:00
draft: false
categories: 
- devops
tags:
- vmware
- esxi
---


## 安装 VMware PowerCLI

软件包下载地址: https://developer.vmware.com/web/tool/13.1.0/vmware-powercli/

官方安装教程: https://developer.vmware.com/docs/15315/GUID-3034A439-E9D7-4743-ABC0-EE38610E15F8.html

先下载好 “[VMware PowerCLI](https://developer.vmware.com/web/tool/13.1.0/vmware-powercli/)” 软件包，按下面步骤进行安装

1. 打开 PowerShell 命令窗口
2. 运行下面的命令，查看 `PowerShell Modules` 存放路径，将 `PowerCLI ZIP` 文件解压缩 `PowerShell Modules` 路径下(有多个路径，选一个即可)
    ```powershell
    $env:PSModulePath
    ```
3. 将 `PowerCLI ZIP` 文件的内容提取到列出的文件夹中的任意一个
4. 运行以下命令，解锁阻止复制的文件，`C:\Users\liwanggui\Documents\WindowsPowerShell\Modules` 为第三步提取文件的文件夹路径，需要替换为自己的路径
    ```powershell
    Get-ChildItem -Path 'C:\Users\liwanggui\Documents\WindowsPowerShell\Modules' -Recurse | Unblock-File
    ```
5. 验证 `PowerCLI` 模块是否已成功安装。
    ```powershell
    Get-Module VMware* -ListAvailable
    ```
6. 安装 [Python](https://www.python.org/downloads/windows/), `PowerCLI` 依赖于 `Python 3.7.1` 或更高版本 (安装过程略)
7. 安装以下 Python 模块
    ```bash
    pip install -i 'https://mirrors.aliyun.com/pypi/simple/' six psutil lxml pyopenssl
    ```
8. 为 `PowerCLI` 配置 `python` 环境，*使用管理员权限运行*, 在 Powershell 中执行以下命令(Python 路径替换为自己安装的路径)
    ```powershell
    Set-PowerCLIConfiguration -PythonPath "C:\Program Files\Python311\python.exe" -Scope User
    ```

> 注意: Powershell 如有执行策略提示，可以使用 `set-ExecutionPolicy RemoteSigned` 命令设置执行策略

## ESXi 集成网卡驱动

下载 VMware-ESXi-8.0 Offline Bundle 版:
- [VMware vSphere Hypervisor (ESXi) 8.0U2b](https://customerconnect.vmware.com/cn/downloads/details?downloadGroup=ESXI80U2B&productId=1345&rPId=116159)

下载网卡驱动文件:
- [Community Networking Driver for ESXi](https://archive.org/download/flings.vmware.com/Flings/Community%20Networking%20Driver%20for%20ESXi/)
- [USB Network Native Driver for ESXi](https://archive.org/download/flings.vmware.com/Flings/USB%20Network%20Native%20Driver%20for%20ESXi/)



集成打包命令如下

```powershell
# 指定 Office Bundle 版本的 ESXi 路径
$esxiOfflineBundle = "D:\backup\tmp\VMware-ESXi-8.0U2b-23305546-depot.zip"

# 现有的配置文件名，可在 Office Bundle 版本的 ESXi 包中的 vmw-ESXi-8.0.2-metadata.zip\profiles 下找到
$esxiImageProfileName = "ESXi-8.0U2sb-23305545-standard"

# 定义新的配置文件名
$newImageProfileName = "ESXi-8.0U2sb-23305545-standard-ext"

# 添加 ESXi 离线包至软件仓库
Add-EsxSoftwareDepot $esxiOfflineBundle

# 添加网卡驱动软件包 - vmusb 
Add-EsxSoftwareDepot D:\backup\tmp\driver\ESXi80U2-VMKUSB-NIC-FLING-67561870-component-22416446.zip
# 添加网卡驱动软件包 - 扩展网卡
Add-EsxSoftwareDepot D:\backup\tmp\driver\Net-Community-Driver_1.2.7.0-1vmw.700.1.0.15843807_19480755.zip

# 从现有的配置，克隆一份配置文件， Vendor 名称可自定义
New-EsxImageProfile -CloneProfile $esxiImageProfileName -Name $newImageProfileName -Vendor wglee

# 添加网卡驱动到新的配置文件中, 名称可以驱动压缩包的 vib20 目录查看
Add-EsxSoftwarePackage -ImageProfile $newImageProfileName -SoftwarePackage "vmkusb-nic-fling"
Add-EsxSoftwarePackage -ImageProfile $newImageProfileName -SoftwarePackage "net-community"

# 使用新的配置文件，打包新镜像
Export-EsxImageProfile -ImageProfile $newImageProfileName -ExportToIso -FilePath "D:\backup\tmp\ESXi-8.0U2b-23305546-Extend-Network-Driver.iso"
```

> 注意: 以上命令中的路径记得要替换成自己环境的路径
