# 使用 cobbler 批量部署 bclinux7.2


## 1. Cobbler介绍

`Cobbler`是一个`Linux`服务器安装的服务，可以通过网络启动(PXE)的方式来快速安装、重装物理服务器和虚拟机，同时还可以管理`DHCP`，`DNS`等。

`Cobbler`可以使用命令行方式管理，也提供了基于Web的界面管理工具(cobbler-web)，还提供了API接口，可以方便二次开发使用。

`Cobbler`是较早前的`kickstart`的升级版，优点是比较容易配置，还自带web界面比较易于管理。

`Cobbler`内置了一个轻量级配置管理系统，但它也支持和其它配置管理系统集成，如`Puppet`，暂时不支持`SaltStack`。

### 1.1 Cobbler集成的服务

- PXE服务支持
- DHCP服务管理
- DNS服务管理(可选bind,dnsmasq)
- 电源管理
- Kickstart服务支持
- YUM仓库管理
- TFTP(PXE启动时需要)
- Apache(提供kickstart的安装源，并提供定制化的kickstart配置)

### 1.2 系统环境准备

```bash
[root@localhost ~]# cat /etc/redhat-release # 查看发行版本
CentOS Linux release 7.2.1511 (Core)
[root@localhost ~]# uname -r # 查看内核版本
3.10.0-327.el7.x86_64
[root@localhost ~]# sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config # 关闭selinux功能,配置文件修改只有重启系统方可生效(如果不想重启，请使用此命令临时关闭selinux功能：setenforce 0)
[root@localhost ~]# systemctl stop firewalld  # 停止防火墙
[root@localhost ~]# systemctl disable firewalld  # 禁用防火墙
[root@localhost ~]# ip addr show  # 查看ip地址
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:0c:29:4d:04:21 brd ff:ff:ff:ff:ff:ff
    inet 192.168.92.106/24 brd 192.168.92.255 scope global dynamic eth0
       valid_lft 20823sec preferred_lft 20823sec
    inet6 fe80::20c:29ff:fe4d:421/64 scope link
       valid_lft forever preferred_lft forever
[root@localhost ~]# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo # 增加阿里云的 epel yum 源(没有此源将无法安装cobbler软件，软件安装完后不用可以删除)
```

## 2. Cobbler的安装

### 2.1 安装Cobbler

```bash
# 安装所需软件
[root@localhost ~]# yum -y install cobbler cobbler-web dhcp tftp-server pykickstart httpd xinetd
[root@localhost ~]# rpm -ql cobbler  # 查看安装的文件，下面列出部分。
/etc/cobbler                  # 配置文件目录
/etc/cobbler/settings         # cobbler主配置文件，这个文件是YAML格式，Cobbler是python写的程序。
/etc/cobbler/dhcp.template    # DHCP服务的配置模板
/etc/cobbler/tftpd.template   # tftp服务的配置模板
/etc/cobbler/rsync.template   # rsync服务的配置模板
/etc/cobbler/iso              # iso模板配置文件目录
/etc/cobbler/pxe              # pxe模板文件目录
/etc/cobbler/power            # 电源的配置文件目录
/etc/cobbler/users.conf       # Web服务授权配置文件
/etc/cobbler/users.digest     # 用于web访问的用户名密码配置文件
/etc/cobbler/dnsmasq.template # DNS服务的配置模板
/etc/cobbler/modules.conf     # Cobbler模块配置文件
/var/lib/cobbler              # Cobbler数据目录
/var/lib/cobbler/config       # 配置文件
/var/lib/cobbler/kickstarts   # 默认存放kickstart文件
/var/lib/cobbler/loaders      # 存放的各种引导程序
/var/www/cobbler              # 系统安装镜像目录
/var/www/cobbler/ks_mirror    # 导入的系统镜像列表
/var/www/cobbler/images       # 导入的系统镜像启动文件
/var/www/cobbler/repo_mirror  # yum源存储目录
/var/log/cobbler              # 日志目录
/var/log/cobbler/install.log  # 客户端系统安装日志
/var/log/cobbler/cobbler.log  # cobbler日志
```

### 2.2 配置Cobbler

```bash
[root@localhost ~]# systemctl start httpd # 启动 httpd 服务
[root@localhost ~]# systemctl start cobblerd # 启动 cobbler 服务
[root@localhost ~]# systemctl restart cobblerd # 此次重启是为了在执行 cobbler check 时不报错[root@localhost ~]# cobbler check 
The following are potential configuration items that you may want to fix:

1 : The 'server' field in /etc/cobbler/settings must be set to something other than localhost, or kickstarting features will not work.  This should be a resolvable hostname or IP for the boot server as reachable by all machines that will use it.
2 : For PXE to be functional, the 'next_server' field in /etc/cobbler/settings must be set to something other than 127.0.0.1, and should match the IP of the boot server on the PXE network.
3 : change 'disable' to 'no' in /etc/xinetd.d/tftp
4 : some network boot-loaders are missing from /var/lib/cobbler/loaders, you may run 'cobbler get-loaders' to download them, or, if you only want to handle x86/x86_64netbooting, you may ensure that you have installed a *recent* version of the syslinux package installed and can ignore this message entirely.  Files in this directory, should you want to support all architectures, should include pxelinux.0, menu.c32, elilo.efi, and yaboot. The 'cobbler get-loaders' command is the easiest way to resolve these requirements.
5 : enable and start rsyncd.service with systemctl
6 : debmirror package is not installed, it will be required to manage debian deployments and repositories
7 : The default password used by the sample templates for newly installed machines (default_password_crypted in /etc/cobbler/settings) is still set to 'cobbler' and should be changed, try: "openssl passwd -1 -salt 'random-phrase-here' 'your-password-here'" to generate new one
8 : fencing tools were not found, and are required to use the (optional) power management features. install cman or fence-agents to use them

Restart cobblerd and then run 'cobbler sync' to apply changes.

# 上面提示的问题，我们一个一个来解决
[root@localhost ~]# cp /etc/cobbler/settings{,.ori}  # 备份
# 第1个问题，server，Cobbler服务器的IP。
[root@localhost ~]# sed -i 's/server: 127.0.0.1/server: 192.168.92.106/' /etc/cobbler/settings
# 第2个问题，next_server，如果用Cobbler管理DHCP，修改本项，作用：告知客户端TFTP服务器的ip。
[root@localhost ~]# sed -i 's/next_server: 127.0.0.1/next_server: 192.168.92.106/' /etc/cobbler/settings
# 用Cobbler管理DHCP
[root@localhost ~]# sed -i 's/manage_dhcp: 0/manage_dhcp: 1/' /etc/cobbler/settings
# 防止循环装系统，适用于服务器第一启动项是PXE启动。
[root@localhost ~]# sed -i 's/pxe_just_once: 0/pxe_just_once: 1/' /etc/cobbler/settings
# 第7个问题，设置新装系统的默认root密码123456。下面的命令来源于提示6。random-phrase-here为干扰码，可以自行设定。
[root@localhost ~]# openssl passwd -1 -salt 'root' '123456'
$1$root$j0bp.KLPyr.u9kgQ428D10
[root@linux-node1 ~]# vim /etc/cobbler/settings 
default_password_crypted: "$1$root$j0bp.KLPyr.u9kgQ428D10"
# 第4个问题，会自动从官网下载
[root@localhost ~]# cobbler get-loaders
task started: 2017-02-26_113724_get_loaders
task started (id=Download Bootloader Content, time=Sun Feb 26 11:37:24 2017)
downloading https://cobbler.github.io/loaders/README to /var/lib/cobbler/loaders/README
downloading https://cobbler.github.io/loaders/COPYING.elilo to /var/lib/cobbler/loaders/COPYING.elilo
downloading https://cobbler.github.io/loaders/COPYING.yaboot to /var/lib/cobbler/loaders/COPYING.yaboot
downloading https://cobbler.github.io/loaders/COPYING.syslinux to /var/lib/cobbler/loaders/COPYING.syslinux
downloading https://cobbler.github.io/loaders/elilo-3.8-ia64.efi to /var/lib/cobbler/loaders/elilo-ia64.efi
downloading https://cobbler.github.io/loaders/yaboot-1.3.17 to /var/lib/cobbler/loaders/yaboot
downloading https://cobbler.github.io/loaders/pxelinux.0-3.86 to /var/lib/cobbler/loaders/pxelinux.0
downloading https://cobbler.github.io/loaders/menu.c32-3.86 to /var/lib/cobbler/loaders/menu.c32
downloading https://cobbler.github.io/loaders/grub-0.97-x86.efi to /var/lib/cobbler/loaders/grub-x86.efi
downloading https://cobbler.github.io/loaders/grub-0.97-x86_64.efi to /var/lib/cobbler/loaders/grub-x86_64.efi
*** TASK COMPLETE ***
[root@localhost ~]# ls /var/lib/cobbler/loaders/ # 下载的内容
COPYING.elilo  COPYING.syslinux  COPYING.yaboot  elilo-ia64.efi  grub-x86_64.efi  grub-x86.efi  menu.c32  pxelinux.0  README  yaboot
# 第3个问题
[root@localhost ~]# vim /etc/xinetd.d/tftp
service tftp
{
        socket_type             = dgram
        protocol                = udp
        wait                    = yes
        user                    = root
        server                  = /usr/sbin/in.tftpd
        server_args             = -s /var/lib/tftpboot
        disable                 = no # 改为no
        per_source              = 11
        cps                     = 100 2
        flags                   = IPv4
}
# 第5个问题
[root@localhost ~]# systemctl enable rsyncd.service
Created symlink from /etc/systemd/system/multi-user.target.wants/rsyncd.service to /usr/lib/systemd/system/rsyncd.service.
[root@localhost ~]# systemctl start rsyncd.service

# 启动xinetd服务，重启cobbler服务，重新检查cobbler
[root@localhost ~]# systemctl start xinetd
[root@localhost ~]# systemctl restart cobblerd
[root@localhost ~]# cobbler check
The following are potential configuration items that you may want to fix:

1 : debmirror package is not installed, it will be required to manage debian deployments and repositories # 和debian系统相关，不需要
2 : fencing tools were not found, and are required to use the (optional) power management features. install cman or fence-agents to use them # fence设备相关，不需要

Restart cobblerd and then run 'cobbler sync' to apply changes.
```

### 2.3 配置DHCP

```bash
# 修改cobbler的dhcp模版，不要直接修改dhcp本身的配置文件，因为cobbler会覆盖。
[root@localhost ~]# vim /etc/cobbler/dhcp.template
......
# 仅列出修改过的字段
subnet 192.168.92.0 netmask 255.255.255.0 {
     option routers             192.168.92.2; # 指定网关
     option domain-name-servers 192.168.92.2; # 指定DNS
     option subnet-mask         255.255.255.0; 
     range dynamic-bootp        192.168.92.200 192.168.92.254; # 分配的地址段（部署的服务器多可以给大点）
......
```

### 2.4 同步cobbler配置

```bash
# 同步最新cobbler配置，它会根据配置自动修改dhcp等服务。
[root@localhost ~]# cobbler sync
task started: 2017-02-26_115318_sync
task started (id=Sync, time=Sun Feb 26 11:53:18 2017)
running pre-sync triggers
cleaning trees
removing: /var/lib/tftpboot/grub/images
copying bootloaders
trying hardlink /var/lib/cobbler/loaders/pxelinux.0 -> /var/lib/tftpboot/pxelinux.0
trying hardlink /var/lib/cobbler/loaders/menu.c32 -> /var/lib/tftpboot/menu.c32
trying hardlink /var/lib/cobbler/loaders/yaboot -> /var/lib/tftpboot/yaboot
trying hardlink /usr/share/syslinux/memdisk -> /var/lib/tftpboot/memdisk
trying hardlink /var/lib/cobbler/loaders/grub-x86.efi -> /var/lib/tftpboot/grub/grub-x86.efi
trying hardlink /var/lib/cobbler/loaders/grub-x86_64.efi -> /var/lib/tftpboot/grub/grub-x86_64.efi
copying distros to tftpboot
copying images
generating PXE configuration files
generating PXE menu structure
rendering DHCP files
generating /etc/dhcp/dhcpd.conf
rendering TFTPD files
generating /etc/xinetd.d/tftp
cleaning link caches
running post-sync triggers
running python triggers from /var/lib/cobbler/triggers/sync/post/*
running python trigger cobbler.modules.sync_post_restart_services
running: dhcpd -t -q
received on stdout:
received on stderr:
running: service dhcpd restart
received on stdout:
received on stderr: Redirecting to /bin/systemctl restart  dhcpd.service

running shell triggers from /var/lib/cobbler/triggers/sync/post/*
running python triggers from /var/lib/cobbler/triggers/change/*
running python trigger cobbler.modules.scm_track
running shell triggers from /var/lib/cobbler/triggers/change/*
*** TASK COMPLETE ***
```

### 2.5 开机启动

```bash
# 设置为开机启动
[root@localhost ~]# systemctl enable httpd
[root@localhost ~]# systemctl enable rsyncd
[root@localhost ~]# systemctl enable xinetd
[root@localhost ~]# systemctl enable cobblerd
[root@localhost ~]# systemctl enable dhcpd
# 重启所有服务
[root@localhost ~]# systemctl restart httpd
[root@localhost ~]# systemctl restart rsyncd
[root@localhost ~]# systemctl restart xinetd
[root@localhost ~]# systemctl restart cobblerd
[root@localhost ~]# systemctl restart dhcpd
```

## 3. cobbler 命令行管理

### 3.1 查看命令帮助

```bash
[root@localhost ~]# cobbler
usage
=====
cobbler <distro|profile|system|repo|image|mgmtclass|package|file> ...
        [add|edit|copy|getks*|list|remove|rename|report] [options|--help]
cobbler <aclsetup|buildiso|import|list|replicate|report|reposync|sync|validateks|version|signature|get-loaders|hardlink> [options|--help]

[root@linux-node1 ~]# cobbler import --help  # 导入镜像
Usage: cobbler [options]
Options:
  -h, --help            show this help message and exit
  --arch=ARCH           OS architecture being imported
  --breed=BREED         the breed being imported
  --os-version=OS_VERSION
                        the version being imported
  --path=PATH           local path or rsync location
  --name=NAME           name, ex 'RHEL-5'
  --available-as=AVAILABLE_AS
                        tree is here, don't mirror
  --kickstart=KICKSTART_FILE
                        assign this kickstart file
  --rsync-flags=RSYNC_FLAGS
                        pass additional flags to rsync
cobbler check    核对当前设置是否有问题
cobbler list     列出所有的cobbler元素
cobbler report   列出元素的详细信息
cobbler sync     同步配置到数据目录,更改配置最好都要执行下
cobbler reposync 同步yum仓库
cobbler distro   查看导入的发行版系统信息
cobbler system   查看添加的系统信息
cobbler profile  查看配置信息
```

### 3.2 导入镜像

```bash
# 挂载镜像
[root@localhost ~]# mount /dev/cdrom /mnt
mount: /dev/sr0 is write-protected, mounting read-only
[root@localhost ~]# cobbler import --path=/mnt/ --name=BClinux-7.2-x86_64 --arch=x86_64
# --path 镜像路径
# --name 为安装源定义一个名字
# --arch 指定安装源是32位、64位、ia64, 目前支持的选项有: x86│x86_64│ia64
# 安装源的唯一标示就是根据name参数来定义，本例导入成功后，安装源的唯一标示就是：BClinux-7.2-x86_64，如果重复，系统会提示导入失败。
# 镜像存放目录，cobbler会将镜像中的所有安装文件拷贝到本地一份，放在/var/www/cobbler/ks_mirror下的BClinux-7.2-x86_64目录下。因此/var/www/cobbler目录必须具有足够容纳安装文件的空间。
[root@localhost ~]# cobbler distro list  # 查看镜像列表
   BClinux-7.2-x86_64
```

### 3.3 指定ks.cfg文件及调整内核参数

```bash
[root@localhost ~]# cd /var/lib/cobbler/kickstarts/ # Cobbler的ks.cfg文件存放位置
[root@localhost kickstarts]# ls # 自带很多
default.ks    esxi5-ks.cfg      legacy.ks     sample_autoyast.xml  sample_esx4.ks   sample_esxi5.ks  sample_old.seed
esxi4-ks.cfg  install_profiles  pxerescue.ks  sample_end.ks        sample_esxi4.ks  sample.ks        sample.seed
# 上传准备好的ks文件(anaconda-ks.cfg),上传方式自己选择（sftp,U盘...)
[root@localhost kickstarts]# mv anaconda-ks.cfg BClinux-7.2-x86_64.cfg
# 在第一次导入系统镜像后，Cobbler会给镜像指定一个默认的kickstart自动安装文件在/var/lib/cobbler/kickstarts下的sample_end.ks。
[root@localhost kickstarts]# cobbler profile report --name=BClinux-7.2-x86_64
Name                           : BClinux-7.2-x86_64
TFTP Boot Files                : {}
Comment                        :
DHCP Tag                       : default
Distribution                   : BClinux-7.2-x86_64
Enable gPXE?                   : 0
Enable PXE Menu?               : 1
Fetchable Files                : {}
Kernel Options                 : {}
Kernel Options (Post Install)  : {}
Kickstart                      : /var/lib/cobbler/kickstarts/sample_end.ks # 默认的ks文件
Kickstart Metadata             : {}
Management Classes             : []
Management Parameters          : <<inherit>>
Name Servers                   : []
Name Servers Search Path       : []
Owners                         : ['admin']
Parent Profile                 :
Internal proxy                 :
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Repos                          : []
Server Override                : <<inherit>>
Template Files                 : {}
Virt Auto Boot                 : 1
Virt Bridge                    : xenbr0
Virt CPUs                      : 1
Virt Disk Driver Type          : raw
Virt File Size(GB)             : 5
Virt Path                      :
Virt RAM (MB)                  : 512
Virt Type                      : kvm
# 编辑profile，修改关联的ks文件
[root@localhost kickstarts]# cobbler profile edit --name=BClinux-7.2-x86_64 --kickstart=/var/lib/cobbler/kickstarts/BClinux-7.2-x86_64.cfg


# 修改安装系统的内核参数，在CentOS7系统有一个地方变了，就是网卡名变成eno16777736这种形式，但是为了运维标准化，我们需要将它变成我们常用的eth0，因此使用下面的参数。但要注意是CentOS7才需要下面的步骤，CentOS6不需要。（改之前请确认是否需要修改，如不需要请跳过）
[root@localhost kickstarts]# cobbler profile edit --name=BClinux-7.2-x86_64 --kopts='net.ifnames=0 biosdevname=0'

[root@localhost kickstarts]# cobbler profile report CentOS-7.1-x86_64
Name                           : BClinux-7.2-x86_64
TFTP Boot Files                : {}
Comment                        :
DHCP Tag                       : default
Distribution                   : BClinux-7.2-x86_64
Enable gPXE?                   : 0
Enable PXE Menu?               : 1
Fetchable Files                : {}
Kernel Options                 : {'biosdevname': '0', 'net.ifnames': '0'}
Kernel Options (Post Install)  : {}
Kickstart                      : /var/lib/cobbler/kickstarts/BClinux-7.2-x86_64.cfg
Kickstart Metadata             : {}
Management Classes             : []
Management Parameters          : <<inherit>>
Name Servers                   : []
Name Servers Search Path       : []
Owners                         : ['admin']
Parent Profile                 :
Internal proxy                 :
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Repos                          : []
Server Override                : <<inherit>>
Template Files                 : {}
Virt Auto Boot                 : 1
Virt Bridge                    : xenbr0
Virt CPUs                      : 1
Virt Disk Driver Type          : raw
Virt File Size(GB)             : 5
Virt Path                      :
Virt RAM (MB)                  : 512
Virt Type                      : kvm

# 每次修改完都要同步一次
[root@localhost kickstarts]# cobbler sync
```

### 3.4 安装系统

可以很愉快的告诉你到这里就可以安装系统了！

**修改Cobbler提示**

> 非必须，不想修改请跳过直接开始安装系统

```bash
[root@localhost ~]# vim /etc/cobbler/pxe/pxedefault.template
MENU TITLE Cobbler | http://wglee.org # 此处的网址可以修改为你公司的网址
[root@localhost ~]# cobbler sync # 修改配置都要同步
```

![cobbler](/images/cobbler.png)

OK，选择第二项就可以开始装机了。

### 3.5 ks.cfg 文件

> 关于ks.cfg文件详细说明请查看：*ks.cfg 文件配置* 文档

```bash
[root@localhost kickstarts]# cat BClinux-7.2-x86_64.cfg
#version=DEVEL
install
# System authorization information
auth --enableshadow --passalgo=sha512
# Use Network installation
url --url=$tree # 这些$开头的变量都是调用配置文件里的值。
# Run the Setup Agent on first boot
firstboot --enable
ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --onboot=on
network  --hostname=localhost.localdomain

# Root password
rootpw  --iscrypted $default_password_crypted # $开头的变量，调用配置文件里的值。
# System services
services --disabled="chronyd"
firewall --disabled
selinux --disabled
# Reboot after installation
reboot

# System timezone
timezone Asia/Shanghai --isUtc
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
# Partition clearing information
clearpart --none --initlabel
# Disk partitioning information
part /boot --fstype="ext4" --ondisk=sda --size=500
part pv.01 --fstype="lvmpv" --ondisk=sda --grow --size=1
volgroup bclinux pv.01
logvol /  --fstype="xfs" --size=10240 --name=root --vgname=bclinux
logvol swap  --fstype="swap" --size=1024 --name=swap --vgname=bclinux

%packages
@^minimal
@core
@security-tools
kexec-tools
vim
wget
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%post
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
%end
```
