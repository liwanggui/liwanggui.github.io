# Windows 右键菜单管理


## 1. 为 Sublime Text 添加右键菜单

- 注册表位置： `HKEY_CLASSES_ROOT\*\shell`
- 菜单名,显示在右键菜单上
    - icon 字符串值，显示的图标
    - command (子项）
        - 默认值： 操作的命令 `D:\Program Files\Sublime Text 3\sublime_text.exe "%1"`

![](/images/aaad9c24-ac5e-4f2c-8c7a-3b6fd75beb8f.png)
 
![](/images/4a3240ba-8035-4b3f-acda-16fea6b6bdae.png)

> 添加右键 shell 菜单注册表地址: `计算机\HKEY_CLASSES_ROOT\Directory`

## 2. 添加 cmd 右键菜单

将以下注册表信息保存为 `xxx.reg` 右键导入即可。

```cmd
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Directory\Background\shell\cmdPrompt]
@="Cmd Here"
"icon"="\"C:\\Windows\\System32\\cmd.exe\""

[HKEY_CLASSES_ROOT\Directory\Background\shell\cmdPrompt\command]
@="\"C:\\Windows\\System32\\cmd.exe\" \"--cd=%v.\""

[HKEY_CLASSES_ROOT\Directory\shell\cmdPrompt]
@="Cmd Here"
"icon"="\"C:\\Windows\\System32\\cmd.exe\""

[HKEY_CLASSES_ROOT\Directory\shell\cmdPrompt\command]
@="\"C:\\Windows\\System32\\cmd.exe\" \"--cd=%v.\""
```

