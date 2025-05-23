# fpm - 简单的包制作工具


## fpm 简介

`fpm` 的目标是使得构建二进制包 (`deb`, `rpm`, `osx` 等) 变得简单快速

- fpm 项目地址: [https://github.com/jordansissel/fpm](https://github.com/jordansissel/fpm)
- fpm 文档地址: [https://fpm.readthedocs.io/en/latest/](https://fpm.readthedocs.io/en/latest/)

## fpm 依赖

`fpm` 使用 `Ruby` 开发, 所以你得先安装 `Ruby`. 有些系统中默认已经安装了 `Ruby`, 例如: OSX, 有些系统可能没有安装 `Ruby`, 此时你需要执行下命令进行安装:

**OSX/macOS:**

```bash
brew install gnu-tar
brew install rpm
```

**Red Hat systems (Fedora 22 or older, CentOS, etc):**

```bash
yum install ruby-devel gcc make rpm-build rubygems
```

> 注意: CentOS 源中的 ruby 版本过低，需要手动源码编译安装较新的 Ruby 版本

*编译安装 Ruby*

```bash
yum install gcc openssl-devel make
wget https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.3.tar.gz
tar xzf ruby-2.7.3.tar.gz
cd ruby-2.7.3
./configure --prefix=/usr/local/ruby
make
make install
```

*配置环境变量*

```bash
echo 'export PATH=/usr/local/ruby/bin:$PATH' > /etc/profile.d/ruby.sh
source /etc/profile
```

*配置 Ruby 源*

```bash
gem sources -l # 查看当前源
gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
```

**Fedora 23 or newer:**

```bash
dnf install ruby-devel gcc make rpm-build libffi-devel
```

**Oracle Linux 7.x systems:**

```bash
yum-config-manager --enable ol7_optional_latest
yum install ruby-devel gcc make rpm-build rubygems
```

**Debian-derived systems (Debian, Ubuntu, etc):**

```bash
apt-get install ruby ruby-dev rubygems build-essential
```

## 安装 fpm

*可以使用 gem 工具安装 fpm*

```bash
gem install --no-document fpm
```

*检查是否安装*

```bash
fpm --version
```

*常用参数说明*

```
-s 指定源类型
-t 指定目标类型，即想要制作为什么包
-n 指定包的名字
-v 指定包的版本号
-C 在搜索文件之前将目录更改为此处
-d 指定依赖于哪些包
-a 架构名称，通常匹配 'uname -m', 可以使用 '-a all' 或者 '-a native'
-f 第二次打包时目录下如果有同名安装包存在，则覆盖它
-p 输出的安装包的目录，不想放在当前目录下就需要指定
--iteration 指定包的发布次数，例 RPM 的 release 字段
--post-install 软件包安装完成之后所要运行的脚本；同 --after-install
--pre-install 软件包安装完成之前所要运行的脚本；同 --before-install
--post-uninstall 软件包卸载完成之后所要运行的脚本；同 --after-remove
--pre-uninstall 软件包卸载完成之前所要运行的脚本；同 --before-remove
```

## 使用示例

以 `nodejs` 为例，

将 `nodejs` 构建成3个包: `nodejs`, `nodejs-dev`, `nodejs-doc`

在示例中需要我们在 `make install` 时设置 `DESTDIR` 将编译好的文件安装到特定的目录中

### 制作 nodejs 包

*正常编译步骤*

```bash
% wget http://nodejs.org/dist/v0.6.0/node-v0.6.0.tar.gz
% tar -zxf node-v0.6.0.tar.gz
% cd node-v0.6.0
% ./configure --prefix=/usr
% make
```

*将 nodejs 安装至临时目录*

```bash
% mkdir /tmp/installdir
% make install DESTDIR=/tmp/installdir
```

*制作 nodejs 包*

```bash
# Create a nodejs deb with only bin and lib directories:
# The 'VERSION' and 'ARCH' strings are automatically filled in for you
# based on the other arguments given.
% fpm -s dir -t deb -n nodejs -v 0.6.0 -C /tmp/installdir \
  -p nodejs_VERSION_ARCH.deb \
  -d "libssl0.9.8 > 0" \
  -d "libstdc++6 >= 4.4.3" \
  usr/bin usr/lib
```

> `nodejs` 包中只包含 `usr/bin`  `usr/lib` 中的文件，此为 nodejs 基础运行包

*安装 nodejs 包，测试一下*

```
# 'fpm' just produced us a nodejs deb:
% file nodejs_0.6.0-1_amd64.deb
nodejs_0.6.0-1_amd64.deb: Debian binary package (format 2.0)
% sudo dpkg -i nodejs_0.6.0-1_amd64.deb

% /usr/bin/node --version
v0.6.0
```

### 制作 nodejs-doc 包

*创建 nodejs 文档手册包*

```bash
# Create a package of the node manpage
% fpm -s dir -t deb -p nodejs-doc_VERSION_ARCH.deb -n nodejs-doc -v 0.6.0 -C /tmp/installdir usr/share/man
```

*查看 nodejs-doc 包*

```bash
% dpkg -c nodejs-doc_0.6.0-1_amd64.deb | grep node.1
-rw-r--r-- root/root       945 2011-01-02 18:35 usr/share/man/man1/node.1
```

### 制作 nodejs-dev 包

最后，打包用于开发的 `headers` 文件:

```bash
% fpm -s dir -t deb -p nodejs-dev_VERSION_ARCH.deb -n nodejs-dev -v 0.6.0 -C /tmp/installdir usr/include
% dpkg -c nodejs-dev_0.6.0-1_amd64.deb | grep -F .h
-rw-r--r-- root/root     14359 2011-01-02 18:33 usr/include/node/eio.h
-rw-r--r-- root/root      1118 2011-01-02 18:33 usr/include/node/node_version.h
-rw-r--r-- root/root     25318 2011-01-02 18:33 usr/include/node/ev.h
...
```

## 注意事项

当我们需要将某个目录制作成二进制包时，需要注意 "相对路径" 与 "绝对路径" 问题，以 `nginx` 为例

*相对路径*

```bash
% cd /usr/local/nginx
% fpm -s dir -t rpm -n nginx -v 1.16.1 --iteration 1.el7 .
no value for epoch is set, defaulting to nil {:level=>:warn}
no value for epoch is set, defaulting to nil {:level=>:warn}
Created package {:path=>"nginx-1.16.1-1.el7.x86_64.rpm"}

# 查看 rpm 包文件列表
$ rpm -qpl nginx-1.16.1-1.el7.x86_64.rpm
/client_body_temp
/conf/extra/dynamic_pools
/conf/extra/static_pools
...
```

*绝对路径*

```bash
$ fpm -s dir -t rpm -n nginx -v 1.16.1 --iteration 2.el7 /usr/local/nginx
no value for epoch is set, defaulting to nil {:level=>:warn}
no value for epoch is set, defaulting to nil {:level=>:warn}
Created package {:path=>"nginx-1.16.1-2.el7.x86_64.rpm"}

# 查看 rpm 包文件列表
$ rpm -qpl nginx-1.16.1-2.el7.x86_64.rpm
/usr/local/nginx/client_body_temp
/usr/local/nginx/conf/extra/dynamic_pools
/usr/local/nginx/conf/extra/static_pools
/usr/local/nginx/conf/fastcgi.conf
/usr/local/nginx/conf/fastcgi.conf.default
...
```

> 更多使用帮助请查看 fpm 官方文档 [https://fpm.readthedocs.io/en/latest/](https://fpm.readthedocs.io/en/latest/)

