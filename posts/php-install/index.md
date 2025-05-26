# 如何在 CentOS 7 和 RHEL 7 服务器上安装 PHP 7.x


众所周知，PHP 是 LAMP 应用程序（WordPress，Joomla，Drupal和Media Wiki等）中最重要的部分。 现在，大多数这些应用程序都需要PHP 7进行安装和配置。 PHP 7.x的主要优点在于，它可以更快地加载Web应用程序，并且消耗更少的服务器资源（例如CPU和RAM）。

默认情况下，PHP 5.4 在 CentOS 7 和 RHEL 7 YUM 存储库中可用。 在本文中，我们将演示如何在 CentOS 7 和 RHEL 7 服务器上安装最新版本的 PHP。

> 文档出处: [https://www.linuxtechi.com/install-php-7-centos-7-rhel-7-server/](https://www.linuxtechi.com/install-php-7-centos-7-rhel-7-server/)

## CentOS 7服务器上PHP 7.0、7.1和7.2的安装步骤

### 1）安装 yum-utils 并启用 EPEL 存储库

登录到您的服务器并使用以下 yum 命令安装 yum-utils 并启用 epel 存储库

```bash
[root@linuxtechi ~]# yum install epel-release yum-utils -y
```

### 2) 使用yum命令下载并安装remirepo

```bash
[root@linuxtechi ~]# yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
```

### 3)  根据您的要求，配置PHP 7.x存储库

> 要配置PHP 7.0存储库，请使用以下命令，

```bash
[root@linuxtechi ~]# yum-config-manager --enable remi-php70
```

> 要配置PHP 7.1存储库，请使用以下命令，

```bash
[root@linuxtechi ~]# yum-config-manager --enable remi-php71
```

> 要配置PHP 7.2 存储库，请使用以下命令，

```bash
[root@linuxtechi ~]# yum-config-manager --enable remi-php72
```

### 4) 安装PHP 7.2及其依赖项。

在本教程中，我将安装最新版本的PHP 7.2及其模块，在yum命令下运行

```bash
[root@linuxtechi ~]# yum install php php-common php-opcache php-mcrypt php-cli php-gd php-curl php-mysql -y
```

> 注意：要搜索所有PHP模块，请使用以下命令：

```bash
[root@linuxtechi ~]# yum search php | more
```

### 5）验证PHP版本

在步骤 4 中安装完所有PHP 7.2及其依赖项之后，请使用以下命令验证已安装的PHP版本，

```bash
[root@linuxtechi ~]# php -v
PHP 7.2.7 (cli) (built: Jun 20 2018 08:21:26) ( NTS )
Copyright (c) 1997-2018 The PHP Group
Zend Engine v3.2.0, Copyright (c) 1998-2018 Zend Technologies
    with Zend OPcache v7.2.7, Copyright (c) 1999-2018, by Zend Technologies
```

## PHP 7.x在RHEL 7 Server上的安装步骤

### 1）启用EPEL，RHEL 7 Server可选存储库并安装remirepo rpm

登录到RHEL 7 Server并依次运行以下命令以启用EPEL存储库，安装remirepo并启用RHEL 7 Server可选存储库

```bash
[root@linuxtechi ~]# rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
[root@linuxtechi ~]# wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
[root@linuxtechi ~]# rpm -Uvh remi-release-7.rpm epel-release-latest-7.noarch.rpm
[root@linuxtechi ~]# subscription-manager repos --enable=rhel-7-server-optional-rpms
```

### 2）配置PHP 7.x存储库

```bash
[root@linuxtechi ~]# yum install yum-utils
[root@linuxtechi ~]# yum-config-manager --enable remi-php72
```

### 3）安装PHP 7.2及其依赖项

```bash
[root@linuxtechi ~]# yum install php php-common php-opcache php-mcrypt php-cli php-gd php-curl php-mysql -y
```

### 4）验证PHP版本

```bash
[root@linuxtechi ~]# php -v
```
