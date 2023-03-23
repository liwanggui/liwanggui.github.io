---
title: "使用 rpmbuild 制作 RPM 包"
date: "2021-04-01T15:23:19+08:00"
draft: false
categories:
- devops
tags:
- rpmbuild
---

- [参考文档 - 1](https://rpm-packaging-guide.github.io/#building-software-from-source)
- [参考文档 - 2](https://www.cnblogs.com/t-road/p/6847146.html)

软件编译安装可以很大程序上定制符合实际需求的软件包，但由于编译时间过长依赖关系复杂常常会耽误太多的时间，为了达到快速部署安装的需求我们需要定制符合需求的 `rpm` 包， `rpm` 默认是通过 `rpmbuild` 工具配合 `spec` 配置文件生成。下面将介绍如何使用 `rpmbild` 工具生成定制 `rpm` 包， 以 `nginx` 为例

> 推荐使用 fpm 制作 rpm 包，参考 [fpm - 简单的包制作工具](/posts/fpm/)

## 环境准备

*安装所需工具*

```bash
yum install gcc rpm-build rpm-devel rpmlint make python bash coreutils diffutils patch rpmdevtools
```

*准备制作环境*

```bash
[root@build ~]# useradd -m build
[root@build ~]# su - build
[build@build ~]# rpmdev-setuptree
[build@build ~]# ls -R rpmbuild/
rpmbuild/:
BUILD  RPMS  SOURCES  SPECS  SRPMS
rpmbuild/BUILD:     # 源码编译工作目录
rpmbuild/RPMS:      # 最终 rpm 包生成目录
rpmbuild/SOURCES:   # 源码包及附加文件放置目录
rpmbuild/SPECS:     # spec 配置文件目录
rpmbuild/SRPMS:     # 最终端 srpm 包生成目录
```

> rpmbuild/BUILDROOT: rpm 打包工作目录

*生成 nginx.spec*

生成 `nginx.spec` 配置文件，并根据情况进行修改

```bash
[build@build ~]# cd rpmbuild/SPECS
[build@SPECS ~]# rpmdev-newspec nginx
[build@SPECS ~]# cat nginx.spec
Name:           nginx
Version:        1.14.2
Release:        1%{?dist}
Summary:        A high performance web server and reverse proxy server 

Group:          System Environment/Daemons
License:        GPLv2
URL:            https://nginx.org

# 制作 rpm 包所需文件
Source0:        nginx-1.14.2.tar.gz
Source1:        nginx.conf
Source2:        limit.conf
Source3:        proxy.conf
Source4:        pathinfo.conf
Source5:        enable-php.conf
Source6:        geoip2.conf
Source7:        upstream.conf.example
Source8:        enable-ssl.conf.example
Source9:        nginx-status.conf.example
Source10:       nginx.init
Source11:       nginx.logrotate

# 编译时需要的依赖包
BuildRequires:  gcc 
BuildRequires:  gcc-c++
BuildRequires:  make
BuildRequires:  libmaxminddb-devel

# rpm 安装时需要的依赖包
Requires:       libmaxminddb-devel

%description
Nginx is a web server and a reverse proxy server for HTTP, SMTP, POP3 and
IMAP protocols, with a strong focus on high concurrency, performance and low
memory usage.

# 制作前准备，解包和路径切换工具
%prep
%setup -q

# 软件包编译过程
%build
./configure --prefix=/usr/local/nginx /
--user=www --group=www /
--with-http_stub_status_module /
--with-http_sub_module /
--with-http_ssl_module /
--with-http_v2_module /
--with-http_realip_module /
--with-openssl=./openssl-1.1.1b /
--with-pcre=./pcre-8.42 /
--with-zlib=./zlib-1.2.11 /
--add-module=./nginx-sticky-module-ng-1.2.6/ /
--add-module=./nginx-upstream-check-module/ /
--add-module=./ngx-http-geoip2-module-3.2/
make %{?_smp_mflags}


# 编译完安装软件包至指定目录等待打包
%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT
%{__install} -p -D -m 0644 %{SOURCE1} %{buildroot}/usr/local/nginx/conf/nginx.conf
%{__install} -p -D -m 0644 %{SOURCE2} %{buildroot}/usr/local/nginx/conf/limit.conf
%{__install} -p -D -m 0644 %{SOURCE3} %{buildroot}/usr/local/nginx/conf/proxy.conf
%{__install} -p -D -m 0644 %{SOURCE4} %{buildroot}/usr/local/nginx/conf/pathinfo.conf
%{__install} -p -D -m 0644 %{SOURCE5} %{buildroot}/usr/local/nginx/conf/enable-php.conf
%{__install} -p -D -m 0644 %{SOURCE6} %{buildroot}/usr/local/nginx/conf/geoip2.conf
%{__install} -p -D -m 0644 %{SOURCE7} %{buildroot}/usr/local/nginx/conf/upstream.conf.example
%{__install} -p -D -m 0644 %{SOURCE8} %{buildroot}/usr/local/nginx/conf/enable-ssl.conf.example
%{__install} -p -D -m 0644 %{SOURCE9} %{buildroot}/usr/local/nginx/conf/nginx-status.conf.example
%{__install} -p -D -m 0755 %{SOURCE10} %{buildroot}/etc/init.d/nginx
%{__install} -p -D -m 0644 %{SOURCE11} %{buildroot}/etc/logrotate.d/nginx

# 清理工作
%clean
rm -rf $RPM_BUILD_ROOT

# 安装前执行的命令
%pre
if ! id www &>/dev/null; then
    useradd -r -M -s /sbin/nologin www
fi

# 安装后
%post
/sbin/chkconfig --add %{name}
/sbin/chkconfig %{name} on

# 卸载前
%preun
/etc/init.d/nginx stop
/sbin/chkconfig --del %{name}

# rpm 打包的文件列表
%files
%defattr(-,root,root,-)
/usr/local/nginx/
/etc/logrotate.d/nginx
%attr(0755,root,root) /etc/init.d/nginx
%config(noreplace) /usr/local/nginx/conf/nginx.conf
%config(noreplace) /usr/local/nginx/conf/limit.conf
%config(noreplace) /usr/local/nginx/conf/geoip2.conf
%config(noreplace) /usr/local/nginx/conf/enable-php.conf

# 更新日志
%changelog
```

*准备 nginx 源码包及相关文件*

```bash
[build@build ~]$ cd rpmbuild/SOURCES/
[build@build SOURCES]$ ls -l
total 12356
-rw-r--r-- 1 build build      207 Mar 17 17:32 enable-php.conf
-rw-r--r-- 1 build build     1137 Mar 17 18:11 enable-ssl.conf.example
-rw-r--r-- 1 build build     1077 Mar 17 21:05 geoip2.conf
-rw-r--r-- 1 build build     1488 Mar 17 17:53 limit.conf
-rw-rw-r-- 1 build build 12589977 Mar 17 20:19 nginx-1.14.2.tar.gz
-rw-r--r-- 1 build build     1913 Mar 17 21:09 nginx.conf
-rw-r--r-- 1 build build     2754 Mar 15 09:35 nginx.init
-rw-r--r-- 1 build build      360 Mar 17 20:36 nginx.logrotate
-rw-r--r-- 1 build build      292 Mar 17 17:32 nginx-status.conf.example
-rw-r--r-- 1 build build      156 Mar 17 17:32 pathinfo.conf
-rw-r--r-- 1 build build      749 Mar 17 20:38 proxy.conf
-rw-r--r-- 1 build build     1031 Mar 17 17:32 upstream.conf.example
```

## 制作 rpm 包

```bash
[build@build ~]$ cd rpmbuild/SPECS/
[build@SPECS ~]# rpmbuild -ba nginx.spec
```

- rpmbuild -bp nginx.spec # 制作到%prep段
- rpmbuild -bc nginx.spec # 制作到%build段
- rpmbuild -bi nginx.spec # 执行 spec 文件的 "%install" 阶段 (在执行了 %prep 和 %build 阶段之后)。这通常等价于执行了一次 "make install"
- rpmbuild -bb nginx.spec # 制作二进制包
- rpmbuild -ba nginx.spec # 表示既制作二进制包又制作src格式包

> Tips: 更新多选项说明使用 `rpmbuild -h`
