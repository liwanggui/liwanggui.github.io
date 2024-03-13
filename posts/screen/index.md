# screen 实现 lrzsz 文件上传下载


在 `Windows` 操作系统环境下的 `Xshell` 等程序中执行 `“sz/rz”` 命令，会自动弹出一个图形界面窗口（是对ZMODEM协议信号捕获事件的响应），用于选取“从服务器接收文件传输目的路径/待发送到服务器的文件路径”。

而在 `Ubuntu Shell` 下，可通过 `GNU screen` 软件包下的 `screen` 命令环境捕获 `ZMODEM` 协议信号，从而实现选取 “从服务器接收文件传输目的路径/待发送到服务器的文件路径”。

## 发送文件到服务器

1. 打开一个 Shell
2. 执行 `screen` 命令，进入 `screen` 命令环境
3. 按下 `Ctrl+a` 组合键，然后再输入 `:zmodem catch` 命令，设置 `screen` 命令环境捕获ZMODEM协议信号
4. 在以上 `screen` 命令环境下与服务器建立 `SSH` 连接
5. 执行 `rz` 命令，`ZMODEM` 协议信号被 `screen` 命令环境捕获，终端底部出现待补全命令，待补全部分为 “待发送到服务器的文件路径”
6. 输入 “待发送到服务器的文件路径”，成功发送文件到服务器当前所处目录下

## 从服务器接收文件

1. 打开一个 Shell
2. 执行 `screen` 命令，进入 `screen` 命令环境
3. 按下 `Ctrl+a` 组合键，然后再输入 `:zmodem catch` 命令，设置 `screen` 命令环境捕获 `ZMODEM` 协议信号
4. 在以上 `screen` 命令环境下与服务器建立 `SSH` 连接
5. 执行 `sz` 文件路径命令，`ZMODEM` 协议信号被 `screen` 命令环境捕获，终端底部会出现可直接执行命令
6. 命令执行后，服务器的文件被传输到本地，自动置于用户主目录下

## screen 配置文件

可以通过在用户家目录下创建 .screenrc 配置文件，在文件中写入 `zmodem catch` 指令，这样就不用每次都要手动敲了

```bash
cat > ~/.screenrc <<EOF
zmodem catch
EOF
```
