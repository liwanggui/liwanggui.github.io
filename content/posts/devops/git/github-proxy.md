---
title: "Github 访问代理(HTTPS & SSH)"
date: 2024-01-26T11:22:32+08:00
draft: false
categories: 
- devops
tags:
- git
- github
---

## GitHub HTTPS 代理加速

国内克隆 github 仓库不稳定时，可以使用网上免费的代理站点加速，也可以自己部署 GitHub 代理加速站点

### 方法1

网上免费的 GitHub 代理站点: 
- https://ghproxy.org/
- https://hub.fgit.cf 

> hub.fgit.cf 使用文档 https://doc.fastgit.org/zh-cn/guide.html

为方便命令行操作可以使用以下命令对 git 进行配置, 

```bash
# 使用 https://hub.fgit.cf/ 站点
git config --global url."https://hub.fgit.cf/".insteadOf "https://github.com/"
git config protocol.https.allow always

# 使用 https://ghproxy.org/ 站点
git config --global url."https://ghproxy.org/github.com".insteadOf "https://github.com"
```

### 方法2

有代理服务器时，可以设置 `Http Proxy`

```bash
$ git config --global http.proxy socks5://127.0.0.1:7890
```

因为 `git` 底层使用 `libcurl` 发送 `http` 请求，而 `libcurl` 的代理使用 `socks5://` 时会在本地解析 `DNS`，实际使用中我们希望 `DNS` 也在远程（也就是可以访问 `google` 的代理节点）解析，所以使用 `socks5h` ，即

```bash
$ git config --global http.proxy socks5h://127.0.0.1:7890
```

`h` 代表 `host`，包括了域名解析，即域名解析也强制走这个 `proxy`。另外不需要配置 `https.proxy`，这些 `git server` 都会配置 `http redirect to https`。

推荐使用 `socks5` 代理，因为 `socks5` 包含 `http(s)`。而且 `socks5` 代理工作在 `osi` 七层模型中的会话层（第五层），`https/http` 代理工作在 `osi` 七层模型的应用层（第七层）, `socks` 代理更加底层。所以就没必要配置 `git config --global http.proxy http://127.0.0.1:7890` 了。


像上面这样配置的话会使本机所有的 `git` 服务都走了代理，假如你在良心云上（国内主机）部署了自己的 `gitea`，服务地址 `https://gitea.example.com`，那么可以只配置 `GitHub` 的 `http proxy`，即

```bash
$ git config --global http.https://github.com.proxy socks5://127.0.0.1:7890
```

这样做实际上是修改了 `~/.gitconfig` 文件，添加了如下内容

```ini
[http "https://github.com"]
        proxy = socks5://127.0.0.1:7890
```

### 方法3， 自行部署

如有需要部署 GitHub 代理加速站点，可以参考 https://github.com/hunshcn/gh-proxy 

## GitHub SSH 代理加速

当使用 ssh 协议克隆仓库出错时，可以尝试参考下这篇文档，[在 HTTPS 端口使用 SSH](https://docs.github.com/zh/authentication/troubleshooting-ssh/using-ssh-over-the-https-port)

当有跳板服务器（可以正常访问 Github）或代理时，可以通过配置 `SSH Proxy` 实现加速, 配置文件 `~/.ssh/config`

1. 使用跳板服务器

```bash
Host github.com
  Hostname ssh.github.com
  IdentityFile ~/.ssh/id_rsa
  User git
  Port 443
  ProxyCommand ssh -l root -p 22 jumpserver.example.com -W %h:%p
```

2. 使用代理服务器

```bash
Host github.com
  Hostname ssh.github.com
  IdentityFile ~/.ssh/id_rsa
  User git
  Port 443
  ProxyCommand nc -v -x 127.0.0.1:7890 %h %p
```

> 文档参考: https://hellodk.cn/post/975
