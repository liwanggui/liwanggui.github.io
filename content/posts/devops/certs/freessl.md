---
title: "ACME v2 证书自动化申请"
date: 2022-03-18T14:57:01+08:00
draft: false
categories: 
- devops
tags:
- acme.sh
- freessl.cn
---

如果你没有域名的解析控制权，此方法就非常适合； 
如果你有域名的控制权可以使用 [acme.sh + dns_api](https://github.com/acmesh-official/acme.sh/wiki/%E8%AF%B4%E6%98%8E) 的方式自动申请

## 安装 acme.sh

```bash
curl https://get.acme.sh | sh -s email=my@example.com
```

> *如果上面官方下载地址 **失败** 或者 **太慢**，可以选用国内的备用地址*

```bash
curl https://gitcode.net/cert/cn-acme.sh/-/raw/master/install.sh?inline=false | sh -s email=my@example.com
```

> 注意：安装完成后，需重载环境变量 `source ~/.bashrc`，以使 `acme.sh` 命令生效。

## 对域名进行授权

这步我们在 [freessl.cn](https://freessl.cn/) 站点注册个账号，登录后点击 `ACME 自动化` 菜单，添加域名，如下图所示

{{< figure src="/images/411F6DCD-15DC-4555-AD25-ADC25C1580B1.png" title="添加域名" >}}

获得域名验证（DCV）授权信息

{{< figure src="/images/5017DB1A-601C-48AB-92CF-78AC59722182.png" title="获得域名验证（DCV）授权信息" >}}

到您的域名解析服务商添加解析记录，下面以DNSPod为例：

{{< figure src="/images/5b805521-00c4-4aeb-9bb1-1ae80e4c5fcd.png" title="添加解析" >}}

## 申请证书

点击【配置完成，立即检测】后获得证书申请命令

{{< figure src="/images/A1D60901-574E-4317-A678-E301030198FA.png" title="部署命令" >}}


## 部署到 WebServer

**Apache example:**

```bash
acme.sh --install-cert -d example.com \
--cert-file      /path/to/certfile/in/apache/cert.pem  \
--key-file       /path/to/keyfile/in/apache/key.pem  \
--fullchain-file /path/to/fullchain/certfile/apache/fullchain.pem \
--reloadcmd     "service apache2 force-reload"
```

**Nginx example:**

```bash
acme.sh --install-cert -d example.com \
--key-file       /path/to/keyfile/in/nginx/key.pem  \
--fullchain-file /path/to/fullchain/nginx/cert.pem \
--reloadcmd     "service nginx force-reload"
```

> 证书进入到30天有效期，acme.sh 会自动完成续期 (有计划任务会定期检查)。
