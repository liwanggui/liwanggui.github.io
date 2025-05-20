---
title: "macOS 开发配置"
date: 2021-06-12T18:39:34+08:00
draft: false
categories: 
- macOS
tags:
- macOS
---

## 安装开发组件 - XCode

从 `App store` 或苹果开发者网站安装 [Xcode](https://developer.apple.com/xcode/)

紧接着，安装 `Xcode command line tools`，运行：

```bash
xcode-select --install
```

运行命令后，按照指引，你将完成 `Xcode command line tools` 安装。

> 注: 如果你不是一名 iOS 或 OSX 开发者，可以跳过安装 XCode 的过程，直接安装 `Xcode command line tools`。安装完成后，你将可以直接在 `terminal` 中使用主要的命令，比如：`make`, `GCC`, `clang`, `perl`, `svn`, `git`, `size`, `strip`, `strings`, `libtool`, `cpp` 等等。

> 如果你想了解 `Xcode command line tools` 包含多少可用的命令，可以到 `/Library/Developer/CommandLineTools/` 查看。

## 配置源码管理工具 - Git

*GitHub git 帮助文档:*  https://docs.github.com/en/get-started/quickstart/set-up-git

### Git 全局配置

```bash
# 配置 github 加速, 仅适用于 https 
git config --global url."https://gh.wglee.org/github.com".insteadOf "https://github.com"

# 配置用户信息
git config --global user.name "Your Name Here"
git config --global user.email "your_email@youremail.com"

# 如果你不想每次都输入用户名和密码的话, 执行下面命令
git config --global credential.helper osxkeychain
```

> 提示: Git 全局配置文件 `~/.gitconfig`

### 配置 github ssh 加速

```bash
cat >> ~/.ssh/config <<EOF
Host github.com
    Hostname ssh.github.com
    Port 443
    User git
    IdentityFile ~/.ssh/id_rsa
EOF
```

### Git 全局忽略文件

创建一个新文件 `~/.gitignore` ，并将以下内容添加进去，这样全部 git 仓库将会忽略以下内容所提及的文件。

```
# Folder view configuration files
.DS_Store
Desktop.ini

$RECYCLE.BIN/

# Thumbnail cache files
._*
Thumbs.db

# Files that might appear on external disks
.Spotlight-V100
.Trashes

# Compiled Python files
*.pyc

# Compiled C++ files
*.out

# Application specific files
venv
node_modules
.sass-cache

# vscode
.vscode/
```


## 软件管理工具 - Homebrew

> 官网地址: https://brew.sh/

在安装 `Homebrew` 之前，需要将 `Xcode Command Line Tools` 安装完成

```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

> 安装完成后，Homebrew 会将本地 /usr/local 初始化为 git 的工作树，并将目录所有者变更为当前所操作的用户，将来 brew 的相关操作不需要 sudo

## 终端管理工具 - iTerm2

> iTerm2 下载地址： https://iterm2.com/downloads.html

### 配置 zmodem（lrzsz）

`iTerm` 默认终端是不支持 `sz` `rz` 命令的，`iterm2` 终端可以配置支持 `sz` `rz`  命令，配置方法如下：

*1. 安装 lrzsz*

```bash
brew install lrzsz
```

*2. 安装 iterm2-zmodem 脚本*

```bash
git clone https://github.com/aikuyun/iterm2-zmodem.git
cp iterm2-zmodem/iterm2*.sh /usr/local/bin/
chmod +x /usr/local/bin/iterm2*.sh
```

*3. 配置 iterm2 Triggers*

```bash
Regular expression: \*\*B0100
    Action: Run Silent Coprocess
    Parameters: /usr/local/bin/iterm2-send-zmodem.sh
Regular expression: \*\*B00000000000000
    Action: Run Silent Coprocess
    Parameters: /usr/local/bin/iterm2-recv-zmodem.sh 
```

按 `command` + `,` 打开配置面板，然后点击 “`Profiles`”, “`Advanced`”， “`Triggers -> Edit`”

> Tips: 正常连接服务器就可以使用 `sz` `rz` 命令了
> 通过添加 profile 配置主机列表


> 注意: 需要在服务器上安装 lrzsz 软件包

### 配置 trzsz-iterm2 (trzsz)

trzsz-iterm2 是 trzsz 在 iTerm2 上使用的客户端。

- 官方文档: https://trzsz.github.io/cn/iterm2

安装 trzsz-iterm2 

```bash
brew install trzsz
```

以安装路径 `/usr/local/bin/trzsz-iterm2` 为例, 配置步骤如下

打开 iTerm2 -> Preferences... / Settings... -> Profiles -> ( 在左边选中一个 Profile ) -> Advanced -> Triggers -> Edit -> [+]，如下配置：

|Name	| Value	| Note |
|:-|-|:-|
|Regular Expression	|:(:TRZSZ:TRANSFER:[SRD]:\d+\.\d+\.\d+:\d+)	|前后无空格|
|Action | Run Silent Coprocess...	||
|Parameters | /usr/local/bin/trzsz-iterm2 -p text \1	|前后无空格|
|Enabled |	✅	|选中|

- 不要选中最下面的 Use interpolated strings for parameters。
- 注意 /usr/local/bin/trzsz-iterm2 要替换成真实的 trzsz-iterm2 绝对路径。
- 不同 Profile 的 Trigger 是互相独立的，也就是每个用到的 Profile 都要进行配置。
- Trigger 的配置是允许输入多行的，但只会显示一行，注意不要多复制了一个换行符进去。

{{< figure src="/images/iterm2_config.png" title="iterm2 Config" >}}

打开 iTerm2 -> Preferences... / Settings... -> General -> Magic，选中 Enable Python API

{{< figure src="/images/iterm2_enable_python.png" title="iterm2 Enable Python API" >}}

设置 ITERM2_COOKIE 环境变量可以使启动速度更快。

打开 iTerm2 -> Preferences... / Settings... -> Advanced，筛选 COOKIE，选择 Yes

{{< figure src="/images/iterm2_cookie.png" title="iterm2 cookie" >}}

### 常用快捷键

- `command + d` 横向分屏
- `command + shift + d` 水平分屏
- `command + enter` 全屏，取消全屏
- `command + ;` 打开输入历史记录
- `command + f` 打开搜索框
- `option + command + i` 分屏时同时操作多个窗口，重复取消

## 终端 zsh 工具 - "Oh My ZSH"

### 安装 ohmyzsh

> 官方站点:  https://ohmyz.sh/

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

> zsh 主题配置项: `ZSH_THEME="ys"`

### 快捷键配置

配置从当前位置删除到行首 `Ctrl + U`

```bash
cat >> ~/.zshrc <<EOF
# 恢复 Crtl + U 快捷键功能
bindkey \^U backward-kill-line
# zsh 默认自动给没有换行符的字符串添加一个百分号%（root 用户是 # 号），同时另起一行显示新的提示符
# 去掉末尾自动添加的符号 (% or #)， 
unsetopt prompt_cr prompt_sp
EOF
source  ~/.zshrc
```

### 新增命令无法自动识别解决方法

在使用 zsh 时，某些命令安装后会找不到，必须手动执行 rehash 才能更新 hash table。这和 zsh 的命令缓存机制有关。

由于 zsh 会将命令路径缓存，以加快命令查找速度。

这个缓存不会自动更新，导致： 安装新命令后，如果之前尝试过运行该命令但未成功，zsh 会认为它 “还是不存在”。

```bash
rehash  # 或者 hash -r
```

## 配置 VIM 编辑器

创建 `~/.vimrc` 配置文件

```bash
syntax on
set autoread
set ruler
set encoding=utf-8
set clipboard=unnamed
set laststatus=2

" 将制表符转为空格
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

set autoindent
set cindent
set hlsearch
set backspace=2

" 配置 yaml 文件缩进为二空格
autocmd FileType yaml setlocal autoindent tabstop=2 shiftwidth=2 expandtab

" 记录上次编辑位置
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
```

## 解决 macOS Ventura 下 ssh 无法使用 rsa 密钥验证

在 `~/.ssh/config` 配置文件中加入以下配置项即可、

```bash
Host *
    HostkeyAlgorithms +ssh-rsa
    PubkeyAcceptedAlgorithms +ssh-rsa
```

## macOS 英文目录显示为中文

> 以目录名为 `Code` 进行讲解

1. 在英文目录下新建 `.localized` 隐藏目录
2. 进入`localized` 目录创建 `zh_CN.strings` 文件, 输入 "english" = "中文";

```bash
mkdir -p Code/.localized
cat Code/.localized/zh_CN.strings
"Code" = "代码";
```

> 注意: 不能少了分号

3. 最后将目录名改为以 `.localized` 结尾即可

```bash
mv Code Code.localized
```

> 参考文档:  https://www.bookstack.cn/read/Mac-dev-setup/README.md
