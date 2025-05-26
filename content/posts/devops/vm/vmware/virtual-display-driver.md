---
title: "解决 VNC 远程桌面黑屏 - 虚拟显示器驱动"
date: 2024-10-24T10:52:31+08:00
draft: false
categories: 
- vmware
tags:
- vmware
- Virtual-Display-Driver
---

## 问题

为了解决主机没有显示器又需要远程桌面管理的场景。
虚拟显示器对于没有显示器的服务器，可以启用远程桌面和屏幕流式传输到其他系统，就像安装了显示器一样。

官方仓库: [https://github.com/itsmikethetech/Virtual-Display-Driver](https://github.com/itsmikethetech/Virtual-Display-Driver)

## 安装使用

1. 下载最新版本，并解压到文件夹中，例如放到 `C:\IddSampleDriver` 目录下
2. 右键单击并以管理员身份运行 *.bat 文件，将驱动程序证书添加为受信任的根证书。
3. 不要安装 inf。 打开设备管理器，单击任意设备，然后单击 “操作” 菜单并单击 “添加旧版硬件”。
4. 选择 “从列表中添加硬件（高级）”，然后选择显示适配器。
5. 单击 “从磁盘安装...”，然后单击 “浏览...” 按钮。 导航到解压的文件并选择 inf 文件。
6. 安装完成！转到显示设置以自定义附加显示器的分辨率。 您可以启用/禁用显示适配器来切换监视器。

> 注意：请确保 `options.txt` 系统可以访问，否则安装将失败。例如: `C:\IddSampleDriver\options.txt` 

> 注意: 请勿重复安装