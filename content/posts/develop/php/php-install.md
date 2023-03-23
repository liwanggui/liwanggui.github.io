---
title: "PHP 源码编译安装"
date: 2019-08-26T17:02:26+08:00
draft: false
categories: 
- php
tags:
- php
---

## 环境准备

*准备编译环境*

```bash
yum install -y gcc gcc-c++ make cmak autoconf
```

*安装相关依赖*

```bash
yum install -y libmcrypt libmcrypt-devel mcrypt mhash
yum install -y gmp-devel libxml2-devel openssl-devel bzip2-devel /
libcurl-devel libjpeg-devel libpng-devel freetype-devel /
libmcrypt-devel readline-devel libxslt-devel libicu-devel /
gettext-devel libc-client-devel pam-devel
```

## 编译安装

```bash
./configure --prefix=/usr/local/php /
--sysconfdir=/etc/php /
--with-config-file-path=/etc/php /
--with-config-file-scan-dir=/etc/php/conf.d /
--enable-fpm /
--with-fpm-user=www /
--with-fpm-group=www /
--enable-mysqlnd /
--with-mysqli=mysqlnd /
--with-pdo-mysql=mysqlnd /
--with-iconv-dir /
--with-freetype-dir /
--with-jpeg-dir /
--with-png-dir /
--with-zlib /
--with-curl /
--with-gettext /
--with-imap /
--enable-exif /
--with-libxml-dir /
--enable-xml /
--disable-rpath /
--enable-bcmath /
--enable-shmop /
--enable-sysvsem /
--enable-inline-optimization /
--enable-mbregex /
--enable-mbstring /
--enable-intl /
--enable-pcntl /
--enable-ftp /
--with-gd /
--with-openssl /
--with-mhash /
--enable-pcntl /
--enable-sockets /
--with-xmlrpc /
--enable-zip /
--enable-soap /
--with-gettext /
--enable-opcache /
--with-xsl

make
make install
```

## 配置 PHP

```bash
MemTotal=`free -m | grep Mem | awk '{print $2}'`

/bin/cp -f php.ini-production /etc/php/php.ini

sed -i 's/post_max_size =.*/post_max_size = 50M/g' /etc/php/php.ini
sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' /etc/php/php.ini
sed -i 's/;date.timezone =.*/date.timezone = PRC/g' /etc/php/php.ini
sed -i 's/short_open_tag =.*/short_open_tag = On/g' /etc/php/php.ini
sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' /etc/php/php.ini
sed -i 's/max_execution_time =.*/max_execution_time = 300/g' /etc/php/php.ini
sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' /etc/php/php.ini

/bin/cp -f /etc/php/php-fpm.conf.default /etc/php/php-fpm.conf
sed -i "s#^;pid.*#pid = /var/run/php-fpm.pid#" /etc/php/php-fpm.conf
sed -i "s#^;error_log.*#error_log = /var/log/php-fpm.log#" /etc/php/php-fpm.conf
sed -i "s#^;log_level.*#log_level = notice#" /etc/php/php-fpm.conf

cat >/etc/php/php-fpm.d/www.conf<<EOF
[www]
listen = /var/run/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = /var/log/slow.log
EOF

if [[ ${MemTotal} -gt 1024 && ${MemTotal} -le 2048 ]]; then
    sed -i "s#pm.max_children.*#pm.max_children = 20#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.start_servers.*#pm.start_servers = 10#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 10#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 20#" /etc/php/php-fpm.d/www.conf
elif [[ ${MemTotal} -gt 2048 && ${MemTotal} -le 4096 ]]; then
    sed -i "s#pm.max_children.*#pm.max_children = 40#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.start_servers.*#pm.start_servers = 20#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 20#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 40#" /etc/php/php-fpm.d/www.conf
elif [[ ${MemTotal} -gt 4096 && ${MemTotal} -le 8192 ]]; then
    sed -i "s#pm.max_children.*#pm.max_children = 60#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.start_servers.*#pm.start_servers = 30#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 30#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 60#" /etc/php/php-fpm.d/www.conf
elif [[ ${MemTotal} -gt 8192 ]]; then
    sed -i "s#pm.max_children.*#pm.max_children = 80#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.start_servers.*#pm.start_servers = 40#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 40#" /etc/php/php-fpm.d/www.conf
    sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 80#" /etc/php/php-fpm.d/www.conf
fi
```

**复制服务启动文件**

*CentOS 6.x*

```bash
/bin/cp -f sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
sed -i "s#php_fpm_PID=.*#php_fpm_PID=/var/run/php-fpm.pid#" /etc/init.d/php-fpm
```

*CentOS 7.x*

```bash
/bin/cp -f sapi/fpm/php-fpm.service /usr/lib/systemd/system/php-fpm.service
```
