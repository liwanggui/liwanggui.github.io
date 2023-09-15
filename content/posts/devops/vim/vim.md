---
title: "Vim 常用配置"
date: 2021-09-14T09:27:13+08:00
draft: false
categories: 
- devops
- vim
tags:
- vim
---

## Tab 转为 空格

在 `$HOME/.vimrc` 文件中加入以下配置

```vim
set expandtab
set tabstop=4
```

将现有文件的 `Tab` 转换为 空格

```vim
:set ts=4
:set expandtab
:%retab!
```

## 取消自动缩进

```vim
set pastetoggle=<F11>
```

按 `F11` 将禁用自动缩进功能

## 为 Shell 脚本定制开头片断

```vim
autocmd BufNewFile *.sh exec ":call SetTitle()"
func SetTitle()
    if expand("%:e") == 'sh'
    call setline(1,"#!/bin/bash")
    call setline(2,"#")
    call setline(3,"#***************************************************************************")
    call setline(4,"# Author: liwanggui")
    call setline(5,"# Email: liwanggui@163.com")
    call setline(6,"# Date: ".strftime("%Y-%m-%d"))
    call setline(7,"# FileName: ".expand("%"))
    call setline(8,"# Description: This is a test script")
    call setline(9,"# Copyright (C): ".strftime("%Y")." All rights reserved")
    call setline(10,"#***************************************************************************")
    call setline(11,"#")
    call setline(12,"")
    endif
endfunc
autocmd BufnewFile * normal G
```

## 完整配置

```vim
set expandtab
set tabstop=4
set shiftwidth=4
set ignorecase
set cursorline
set autoindent
set paste
set pastetoggle=<F11>

autocmd BufNewFile *.sh exec ":call SetTitle()"
func SetTitle()
    if expand("%:e") == 'sh'
    call setline(1,"#!/bin/bash")
    call setline(2,"#")
    call setline(3,"#***************************************************************************")
    call setline(4,"# Author: liwanggui")
    call setline(5,"# Email: liwanggui@163.com")
    call setline(6,"# Date: ".strftime("%Y-%m-%d"))
    call setline(7,"# FileName: ".expand("%"))
    call setline(8,"# Description: This is a test script")
    call setline(9,"# Copyright (C): ".strftime("%Y")." All rights reserved")
    call setline(10,"#***************************************************************************")
    call setline(11,"#")
    call setline(12,"")
    endif
endfunc
autocmd BufnewFile * normal G
```
