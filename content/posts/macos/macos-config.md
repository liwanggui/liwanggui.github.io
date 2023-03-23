---
title: "macOS 开发配置"
date: 2021-06-12T18:39:34+08:00
draft: false
categories: 
- macOS
tags:
- macOS
---

## XCode

从 `App store` 或苹果开发者网站安装 [Xcode](https://developer.apple.com/xcode/)

紧接着，安装 `Xcode command line tools`，运行：

```bash
xcode-select --install
```

运行命令后，按照指引，你将完成 `Xcode command line tools` 安装。

> 注: 如果你不是一名 iOS 或 OSX 开发者，可以跳过安装 XCode 的过程，直接安装 `Xcode command line tools`。安装完成后，你将可以直接在 `terminal` 中使用主要的命令，比如：`make`, `GCC`, `clang`, `perl`, `svn`, `git`, `size`, `strip`, `strings`, `libtool`, `cpp` 等等。

> 如果你想了解 `Xcode command line tools` 包含多少可用的命令，可以到 `/Library/Developer/CommandLineTools/` 查看。

## 配置 git

*GitHub git 帮助文档:*  https://docs.github.com/en/get-started/quickstart/set-up-git

```bash
# 配置 github 加速, 仅适用于 https 
git config --global url."https://gh.wglee.org/github.com".insteadOf "https://github.com"

# 配置用户信息
git config --global user.name "Your Name Here"
git config --global user.email "your_email@youremail.com"

# 如果你不想每次都输入用户名和密码的话, 执行下面命令
git config --global credential.helper osxkeychain
```

> 这些配置信息将会添加进 `~/.gitconfig` 文件中.

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


## 安装 Homebrew

> 官网地址: https://brew.sh/

在安装 Homebrew 之前，需要将 Xcode Command Line Tools 安装完成

```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

安装完成后执行以下命令

```bash
brew doctor
```

> 安装完成后，Homebrew 会将本地 /usr/local 初始化为 git 的工作树，并将目录所有者变更为当前所操作的用户，将来 brew 的相关操作不需要 sudo

## iTerm2 

> iTerm2 下载地址： https://iterm2.com/downloads.html

> 终端配色仓库:  https://github.com/altercation/solarized/tree/master/iterm2-colors-solarized

下载后，解压将 `iTerm` 拖拽进入 `Application` 文件夹中。 然后，你可以在 `Launchpad` 中启动 `iTerm`

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

### 常用快捷键

- `command + d` 横向分屏
- `command + shift + d` 水平分屏
- `command + enter` 全屏，取消全屏
- `command + ;` 打开输入历史记录
- `command + f` 打开搜索框
- `option + command + i` 分屏时同时操作多个窗口，重复取消

## oh-my-zsh

### 安装 zsh zsh-completions

```bash
brew install zsh zsh-completions
```

> 注: 如果 zsh 已安装可以跳过

### 安装 ohmyzsh

> 官方站点:  https://ohmyz.sh/

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

> zsh 主题配置项: `ZSH_THEME="ys"`

### 配置从当前位置删除到行首， ctrl + u

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

## 新增命令无法自动识别解决方法

```bash
rehash  # 执行 rehash 后就可以了
```

## 配置 vim

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
