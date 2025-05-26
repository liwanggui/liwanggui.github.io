# macOS 应用程序无法打开或文件损坏的处理方法


当我们在安装 Mac 应用时，遇到提示 “ XXX.app 已损坏，打不开。您应该将它移到废纸篓 ” 或 “ 打不开 XXX.app，因为它来自身份不明的开发者 ” 可以使用以下方法解决

**允许从陌生来源安装软件**

```bash
sudo spctl --master-disable
```

> 重新打开应用查看是否可正常运行

如已经开启任何来源，但依旧打不开 macOS Sierra 10.12 及以上的用户可能会遇到, 使用以下命令, 然后重新打开 App

```bash
sudo xattr -d com.apple.quarantine /Applications/xxxx.app
```

> 注意：/Applications/xxxx.app 换成你的 App 路径




