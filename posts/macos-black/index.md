# 制作黑苹果或者白苹果系统dmg镜像


比较简单制作黑苹果系统或者白苹果系统的dmg镜像的方法

1. 借助 `gibMacOS` 工具获取完整的 `macOS` 安装文件。gibMacOS：[https://github.com/corpnewt/gibMacOS](https://github.com/corpnewt/gibMacOS)
2. 解压，运行 `gibMacOS.command` ，使用数字选择对应的想要下载的镜像。
3. 在 `gibMacOS-master` 目录下，会有一个 `macOS Downloads` 文件夹，运行里面的 `InstallAssistant.pkg` 
4. 打开 访达，应用程序，可以看到苹果系统的 app 安装程序。
5. 打开 启动台，其他，磁盘工具，点最上面菜单中的 文件，新建映像，新建空白映像。

**以 macOS Monterey 为例**

- 存储为: Install macOS Monterey
- 位置: 桌面
- 名称: Install macOS Monterey
- 格式: Mac OS 扩展 日志式
- 大小: 15GB
- 分区: 单个分区GUID分区表

确定，耐心等待生成完成。

6. 打开终端，运行

```bash
sudo /Applications/Install\ macOS\ Monterey.app/Contents/Resources/createinstallmedia --volume /Volumes/Install\ macOS\ Monterey/ /Applications/Install\ macOS\ Monterey.app --nointeraction
``` 

输入密码，耐心等待完成，完成后右键推出即可。

7. 这里说一句 可以借助 `Hackintool` 工具或者 `OCC` 工具，挂载这个dmg镜像的EFI分区，挂载后可以把准备好的EFI引导文件复制进去，然后再推出，这样就是黑苹果镜像了。

8. 推出后，打开启动台 - 其他 - 磁盘工具

点击菜单 - 映象 - 转换

选中桌面的 `Install macOS Monterey.dmg` 新名称可以改为 `Install macOS Monterey 12.0.1.dmg` 之类的，路径选桌面，映像格式选 压缩。

9. 等待压缩完成后，继续打开 启动台 - 其他 - 磁盘工具，点击菜单 - 映象 - 扫描要恢复的映像，然后选中制作好的 `Install macOS Monterey 12.0.1.dmg` 进行扫描一遍，如果没有错误，就可以把这个dmg文件上传网盘了。

