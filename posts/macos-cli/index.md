# macOS 命令行


## 视频格式转换

[ffmpeg 下载站点](https://evermeet.cx/ffmpeg/)

```bash
ffmpeg -i 2020年MySQL数据库入门到精通.flv -codec copy 2020年MySQL数据库入门到精通.mov
```

## 清理DNS缓存

```bash
sudo killall -HUP mDNSResponder; say DNS cache has been flushed
```

## brew 使用代理

如果碰巧你的 brew 更新缓慢，可以试试让 brew 走代理更新程序包。

```
export ALL_PROXY=socks5://127.0.0.1:your_port_number
```

## 命令格式化 APFS 格式 U 盘

*语法*

```
diskutil eraseDisk format name [APM[Format]|MBR[Format]|GPT[Format]]
```

- format: 文件系统
- name: 设备卷标名

*格式化 U 盘前先用 `diskutil list` 命令查询设备号*

```
sudo diskutil eraseDisk FAT32 san MBRFormat /dev/disk3
```

> APFS 格式是无法直接进行格式化的，我们需要首先删除 APFS 容器。执行如下命令

```
sudo diskutil apfs deleteContainer /dev/disk3
```

> 然后你就会发现，你的 U 盘格式自动变成了 Mac OS 扩展(日志式)

## 显示隐藏文件夹
在 Windows 上隐藏文件夹大家应该都是老手了，转到 Mac 后，却发现隐藏文件夹和自己想象有那么一些不一样。为了更好的把大家的「小秘密」藏到内心最深处的地方，也可以使用两段命令来完成操作。跟前文一样，我们需要获取文件夹的路径，然后在终端中输入以下代码：

```bash
chflags hidden ~/Desktop/Hidden
```

你也可以使用 `nohidden` 重新让该文件夹显示。如果你要显示全部文件，推荐大家直接使用快捷键`「Shift + Command + .」`即可显示全部隐藏文件。

## 允许从陌生来源安装软件

```bash
sudo spctl --master-disable
```

