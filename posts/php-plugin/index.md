# PHP 插件安装


## redis 插件

```bash
wget http://pecl.php.net/get/redis-4.2.0.tgz
tar xzf redis-4.2.0.tgz
cd redis-4.2.0
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install

cat > /etc/php/conf.d/redis.ini << EOF
[redis]
extension=redis.so
EOF
```

## RabbitMQ 插件

*安装 rabbitmq-c*

```bash
wget -O rabbitmq-c-0.9.0.tar.gz  https://github.com/alanxz/rabbitmq-c/archive/v0.9.0.tar.gz
tar xzf rabbitmq-c-0.9.0.tar.gz
cd rabbitmq-c-0.9.0
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/rabbitmq-c ..
cmake --build .  --target install
```

*到这里就已经安装完成了。不过这里有一个坑。你可以看一下`/usr/local/rabbitmq-c`下的目录只有`include`和`lib64`。因为后面编译安装`amqp`扩展的时候系统会到`/usr/local/rabbitmq-c/lib`目录下搜索依赖库，导致错误。所以这里需要加一步*

```bash
cd /usr/local/rabbitmq-c
ln -s lib64 lib
```

*安装 amqp*

```bash
wget https://pecl.php.net/get/amqp-1.9.4.tgz
tar xzf amqp-1.9.4.tgz
cd amqp-1.9.4
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config /
--with-amqp --with-librabbitmq-dir=/usr/local/rabbitmq-c
make && make install

cat > /etc/php/conf.d/amqp.ini << EOF
[amqp]
extension=amqp.so
EOF
```

## 安装 mcrypt

```bash
yum install libmcrypt libmcrypt-devel mcrypt mhash
wget https://pecl.php.net/get/mcrypt-1.0.2.tgz
tar xzf mcrypt-1.0.2.tgz
cd mcrypt-1.0.2
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install

cat > /etc/php/conf.d/mcrypt.ini << EOF
[mcrypt]
extension=mcrypt.so
EOF
```

## 使用 pecl 安装扩展

使用 pecl 命令可以快速帮我们安装 PHP 扩展，使用方法如下

*以安装 redis 扩展为例*

```bash
pecl install redis
pecl install redis-4.2.0
pecl install https://pecl.php.net/get/redis-4.2.0.tgz

cat > /etc/php/conf.d/redis.ini << EOF
[redis]
extension=redis.so
EOF
```

> 注意: `pecl` 会自动向 `php.ini` 文件添加 `extension=redis.so`，请自行修改
