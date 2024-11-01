# ESXi 集成网卡驱动


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

## 使用 PowerCLI 为 ESXi 集成网卡驱动

下载 Offline Bundle 版 ESXi 软件包 :
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
Export-EsxImageProfile -ImageProfile $newImageProfileName -ExportToIso -FilePath "D:\backup\tmp\ESXi-8.0U2b-23305546-customized.iso"
```

> 注意: 以上命令中的路径记得要替换成自己环境的路径，打包失败

## ESXi-Customizer-PS 为 ESXi 集成网卡驱动

下载最新的 `ESXi-Customizer-PS`：https://github.com/VFrontDe-Org/ESXi-Customizer-PS

查询网卡名称和下载驱动网址：https://vibsdepot.v-front.de/wiki/index.php/List_of_currently_available_ESXi_packages

*在线打包*

```powershell
.\ESXi-Customizer-PS.ps1 -v80 -vft -load net55-r8168,net51-r8169
```

*离线打包，需要提前下载 Bundle 版本的 ESXi 文件和网卡驱动, 命令如下*

```powershell
.\ESXi-Customizer-PS.ps1 -nsc -izip .\VMware-ESXi-8.0U2b-23305546-depot.zip -pkgDir .\vib
```

## 使用 vCenter Auto Deploy 打包 ESXi (推荐)

安装 `vCenter` ， 下载 `VMware-VCSA`

安装完成后，登录 `vSphere Client` 页面，选择 `Auto Deploy` 页面，启动 `Auto Deploy` 服务。

![Auto Deploy](/images/vcenter-autodeploy.png)

新建软件库

![新建软件库](/images/vcenter-autodeploy-new.png)

上传 Offline Bundle 版本的 ESXi 软件包

![alt text](/images/vcenter-autodeploy-bundle-esxi.png)

上传下载好的网卡驱动包

![alt text](/images/vcenter-autodeploy-net-usb.png)

![alt text](/images/vcenter-autodeploy-net-coommunity.png)

全部上传完成后，在软件仓库选择 ESXi 软件包的仓库名。在映像配置文件，选项卡下，克隆以 `standard` 结尾的配置文件（有多个，就选择和 Offline Bundle 版本的 ESXi 软件包名称一致的）

![alt text](/images/vcenter-autodeploy-clone.png)

配置 “克隆映像配置文件”

![alt text](/images/vcenter-autodeploy-clone-config.png)

![alt text](/images/vcenter-autodeploy-clone-config-apk1.png)
![alt text](/images/vcenter-autodeploy-clone-config-apk2.png)

完成配置

![alt text](/images/vcenter-autodeploy-clone-config2.png)

导出镜像

![alt text](/images/vcenter-autodeploy-image1.png)

![alt text](/images/vcenter-autodeploy-image2.png)

镜像生成完成后，会出下载选项

![alt text](/images/vcenter-autodeploy-download.png)


*附: 如在镜像生成时有错误提示: Entry is too large to be added to cache, remove any unused depots.*

这是因为默认缓存过小，因此需要增加缓存大小，使用 ssh 登录 `vCenter Server`

查看缓存大小

```bash
less /etc/vmware-imagebuilder/sca-config/imagebuilder-config.props

vmomiPort=8098
cacheSize_GB=2
httpPort=8099
loglevel=INFO
```

如您所见，`cacheSize_GB` 默认设置为 2GB

```
vi /etc/vmware-imagebuilder/sca-config/imagebuilder-config.props
less /etc/vmware-imagebuilder/sca-config/imagebuilder-config.props

vmomiPort=8098
cacheSize_GB=4
httpPort=8099
loglevel=INFO
```

重新启动 `Image Builder` 和 `Auto Deploy` 服务即可解决

```bash
service-control --restart vmware-imagebuilder
service-control --restart vmware-rbd-watchdog
```

> 参考文章; https://vninjadfw.github.io/autodeploycache/

