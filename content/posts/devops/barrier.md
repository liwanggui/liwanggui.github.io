---
title: "全平台免费键盘鼠标共享软件 Barrier 的安装与使用"
date: 2024-10-14T14:31:14+08:00
draft: false
categories: 
- devops
tags:
- Barrier
---

## 说明

键鼠共享软件其实不止 [Barrier](https://github.com/debauchee/barrier) 这一款，其他的还有:

- [Mouse Without Borders](https://www.microsoft.com/en-us/download/details.aspx?id=35460) 只适用于 Windows 系统
- [Synergy](https://symless.com/synergy)  是一款收费软件
- [sharemouse](https://www.sharemouse.com/) 同样是款收费软件，可以免费使用，但功能有限制
- [Deskflow](https://github.com/deskflow/deskflow) 免费开源
- [input-leap](https://github.com/input-leap/input-leap) 免费开源

[Barrier](https://github.com/debauchee/barrier) 是和 Synergy 同源的一款软件。最初 Synergy 是基于 Chris Schoeneman 编写的 CosmoSynergy 开发的一个免费软件，Synergy 在迭代数个版本后开始收费，于是有团队开始基于 Synergy 的开源内核再次开发出了免费版的 barrier。

Barrier 是一款免费且开源的跨系统键盘鼠标共享软件，主要的特点有：
- 共享鼠标和共享键盘
- 共享剪切板
- 跨系统。适用于 Windows、macOS 和 Linux 系统
- 免费、开源

> 注意: Barrier 已处于无人维护状态，[input-leap](https://github.com/input-leap/input-leap) 是 Barrier 的一个活跃的分支，如使用 barrier 有问题，可以尝试使用 [input-leap](https://github.com/input-leap/input-leap) 替代 Barrier

## 安装

### Windows 和 macOS

Windows 和 macOS 系统有已经打包好的安装包，可以从 Barrier 开源 GitHub 仓库的发布页面 [下载](https://github.com/debauchee/barrier/releases)

Windows 系统选择后缀为 exe 的安装包，macOS 系统选择后缀为 dmg 的安装包。

### linux

Debian 系的 Linux 系统（如Ubuntu等），可以直接使用包管理工具 apt 安装

```bash
sudo apt install barrier
```

其他Linux系统可以通过包管理工具snap安装：

```bash
sudo snap install barrier
```

> 如果系统没有自带 snap，则需先安装 snap。

## 设置和使用

barrier 的设置分为服务端（server）和客户端（client）。

### 服务端

直接连接键盘鼠标的那台电脑是服务端。

打开服务端电脑上的 Barrier, 勾选服务端-共享此电脑的鼠标和键盘。 (记下服务端的IP地址,一般是局域网IP)
选中 “交互式配置” , 点击配置服务器
拖动配置界面右上侧的电脑图标到下方的格子里，双击电脑图标，更改电脑名称为客户端电脑显示的名称（可以在客户端 barrier 软件界面 “屏幕名称” 一栏找到）。两个电脑图标在格子里的相对位置和实际电脑的屏幕位置相对应。

{{< figure src="/images/barrier-1.png" title="配置服务端1" >}}

{{< figure src="/images/barrier-2.png" title="配置服务端2" >}}

### 客户端

要使用服务端电脑键盘鼠标的电脑是客户端

打开客户端电脑上的 Barrier，勾选 Client。
在服务端IP一栏（Server IP）填入服务端的IP地址。如果这一栏不可编辑，则取消勾选“自动配置”（Auto config）。
点击"开始"。

## 常见问题

1. 确保服务端和客户端在同一个局域网内。
2. 如果鼠标键盘不能成功共享，可以检查上述设置，并重启 Barrier 软件。
3. 如果还是不行，可以点击菜单栏“显示日志”（Show Log），查看日志中的报错信息。
4. 日志中出现证书错误，可以参考 [ERROR: ssl certificate doesn't exist](https://github.com/debauchee/barrier/issues/1952)

### 生成ssl证书

默认 Barrier 安装完成后可能没有生成证书，导致服务不可用。各系统操作步骤如下:

**macOS**

```bash
$ mkdir -p ~/Library/Application\ Support/barrier/SSL/Fingerprints;
$ openssl req -x509 -nodes -days 365 -subj /CN=Barrier -newkey rsa:4096 -keyout ~/Library/Application\ Support/barrier/SSL/Barrier.pem -out ~/Library/Application\ Support/barrier/SSL/Barrier.pem;
$ fingerprint=$(openssl x509 -fingerprint -sha256 -noout -in ~/Library/Application\ Support/barrier/SSL/Barrier.pem | cut -d"=" -f2);
$ echo "v2:sha256:$fingerprint" > ~/Library/Application\ Support/barrier/SSL/Fingerprints/Local.txt;
```

**linux**

```bash
$ mkdir -p ~/.local/share/barrier/SSL/Fingerprints;
$ openssl req -x509 -nodes -days 365 -subj /CN=Barrier -newkey rsa:4096 -keyout ~/.local/share/barrier/SSL/Barrier.pem -out ~/.local/share/barrier/SSL/Barrier.pem;
$ fingerprint=$(openssl x509 -fingerprint -sha256 -noout -in ~/.local/share/barrier/SSL/Barrier.pem | cut -d"=" -f2);
$ echo "v2:sha256:$fingerprint" > ~/.local/share/barrier/SSL/Fingerprints/Local.txt;
```

**windows**

注意: Windows 依赖 https://gitforwindows.org/ <br/>
参考: https://github.com/debauchee/barrier/issues/231#issuecomment-1143791895

```powershell
# Powershell
Set-Alias openssl "C:\Program Files\Git\usr\bin\openssl.exe"
cd ~\AppData\Local\Barrier\SSL\
openssl req -x509 -nodes -days 365 -subj /CN=Barrier -newkey rsa:4096 -keyout Barrier.pem -out Barrier.pem
```