# 解除 docker 的 ubuntu 系统 minimize（最小化）限制


Docker 的 Ubuntu 系统安装默认是最小化安装（通过删除用户不登录的系统上不需要的包和内容，该系统已被最小化。）

要恢复此内容， 您可以运行 “`unminimize`” 命令。

在执行命令的过程中需要频繁的输入 yes，如果不想频繁输入 yes 确认，可以直接执行下面的命令：

```bash
yes | unminimize
```

