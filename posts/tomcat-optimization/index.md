# Tomcat 配置及运行权限优化


## 配置优化

### 修改 `Server` 节点 `shutdown` 属性值为长随机数

```xml
<Server port="8005" shutdown="d41d8cd98f00b204e9800998ecf8427e">
```

### 启用 tomcat 线程池

使用线程池，用较少的线程处理较多的访问，可以提高tomcat处理请求的能力。使用方式：

打开 conf/server.xml，增加

```xml
<Executorname="tomcatThreadPool"
namePrefix="catalina-exec-"
maxThreads="500"
minSpareThreads="20"
maxIdleTime="60000"
prestartminSpareThreads="true"
maxQueueSize="100"/>
```

**属性说明**

- `name`: 线程名称
- `namePrefix`: 线程前缀
- `maxThreads` : 最大并发连接数，不配置时默认200，一般建议设置500~ 800 ，要根据自己的硬件设施条件和实际业务需求而定。
- `minSpareThreads`：Tomcat 启动初始化的线程数，默认值25
- `prestartminSpareThreads`：在 Tomcat 初始化的时候就初始化 `minSpareThreads` 的值
- `maxQueueSize`: 最大的等待队列数，超过则拒绝请求
- `maxIdleTime`：线程最大空闲时间60秒

然后，修改 `Connector` 节点，增加 `executor` 属性，如:

```xml
<Connector port="8080" protocol="org.apache.coyote.http11.Http11NioProtocol"
               executor="tomcatThreadPool"
               connectionTimeout="20000"
               enableLookups="false"
               redirectPort="8443"
               maxPostSize="20971520"
               acceptCount="2000"
               acceptorThreadCount="2"
               disableUploadTimeout="true"
               URIEncoding="utf-8"/>
```

**属性说明**

- `port` ：连接端口。
- `protocol`：连接器使用的传输方式。 
- `executor`： 连接器使用的线程池名称
- `enableLookups`：禁用DNS 查询
- `acceptCount`：指定当所有可以使用的处理请求的线程数都被使用时，可以放到处理队列中的请求数，超过这个数的请求将不予处理，默认设置 100 。
- `maxPostSize`：限制以 FORM URL 参数方式的POST请求的内容大小，单位字节，默认是 2097152(2M)，10485760 为 10M。如果要禁用限制，则可以设置为 -1。
- `acceptorThreadCount`： 用于接收连接的线程的数量，默认值是1。一般这个指需要改动的时候是因为该服务器是一个多核CPU，如果是多核 CPU 一般配置为 2。
- `disableUploadTimeout`：上传时是否使用超时机制，以是 servlet 有较长时间来完成它的执行，默认值为 false；
- `URIEncoding`: 指定 Url 字符编码，防止出现乱码

## 运行权限优化

默认情况下 Tomcat 服务是以 root 用户运行的，为了减少安全隐患需要更改为普通用户运行 Tomcat 服务

```bash
[root@10-7-171-239 apache-tomcat-9.0.43]# cd bin/
[root@10-7-171-239 bin]# tar xzf commons-daemon-native.tar.gz
[root@10-7-171-239 bin]# cd commons-daemon-1.2.4-native-src/unix/
[root@10-7-171-239 unix]# ./configure
[root@10-7-171-239 unix]# make
[root@10-7-171-239 unix]# mv jsvc /usr/local/apache-tomcat-9.0.43/bin
[root@10-7-171-239 unix]# cd /usr/local/apache-tomcat-9.0.43/bin
[root@10-7-171-239 bin]# cat > setenv.sh <<EOF
#!/bin/bash
JAVA_HOME=/usr/local/jdk
TOMCAT_USER=tomcat
JSVC_OPTS='-jvm server'
JAVA_OPTS="-server -Xms3072m -Xmx3072m -Djava.security.egd=file:/dev/./urandom"
# 开启监控配置
#CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.port=<监听端口> -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=<本机ip地址> -Dcom.sun.management.jmxremote"
EOF
[root@10-7-171-239 bin]# useradd -r tomcat
[root@10-7-171-239 apache-tomcat-9.0.43]# chown -R tomcat.tomcat /usr/local/apache-tomcat-9.0.43/
```

> 注意 setenv.sh 配置文件中的 jvm 内存大小，请根据实际情况进行配置。

此时就可以使用 `daemon.sh` 脚本对 Tomcat 服务进行启停操作了

```bash
[root@10-7-171-239 apache-tomcat-9.0.43]# ./bin/daemon.sh start
[root@10-7-171-239 apache-tomcat-9.0.43]# ps -ef | grep tomcat
root     31610     1  0 11:54 ?        00:00:00 jsvc.exec -jvm server -java-home /usr/local/jdk -user tomcat -pidfile /usr/local/apache-tomcat-9.0.43/logs/catalina-daemon.pid -wait 10 -umask 0027 -outfile /usr/local/apache-tomcat-9.0.43/logs/catalina-daemon.out -errfile &1 -classpath /usr/local/apache-tomcat-9.0.43/bin/bootstrap.jar:/usr/local/apache-tomcat-9.0.43/bin/commons-daemon.jar:/usr/local/apache-tomcat-9.0.43/bin/tomcat-juli.jar -Djava.util.logging.config.file=/usr/local/apache-tomcat-9.0.43/conf/logging.properties -server -Xms512m -Xmx512m -Djava.security.egd=file:/dev/./urandom -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Dignore.endorsed.dirs= -Dcatalina.base=/usr/local/apache-tomcat-9.0.43 -Dcatalina.home=/usr/local/apache-tomcat-9.0.43 -Djava.io.tmpdir=/usr/local/apache-tomcat-9.0.43/temp org.apache.catalina.startup.Bootstrap
tomcat   31611 31610 30 11:54 ?        00:00:03 jsvc.exec -jvm server -java-home /usr/local/jdk -user tomcat -pidfile /usr/local/apache-tomcat-9.0.43/logs/catalina-daemon.pid -wait 10 -umask 0027 -outfile /usr/local/apache-tomcat-9.0.43/logs/catalina-daemon.out -errfile &1 -classpath /usr/local/apache-tomcat-9.0.43/bin/bootstrap.jar:/usr/local/apache-tomcat-9.0.43/bin/commons-daemon.jar:/usr/local/apache-tomcat-9.0.43/bin/tomcat-juli.jar -Djava.util.logging.config.file=/usr/local/apache-tomcat-9.0.43/conf/logging.properties -server -Xms512m -Xmx512m -Djava.security.egd=file:/dev/./urandom -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Dignore.endorsed.dirs= -Dcatalina.base=/usr/local/apache-tomcat-9.0.43 -Dcatalina.home=/usr/local/apache-tomcat-9.0.43 -Djava.io.tmpdir=/usr/local/apache-tomcat-9.0.43/temp org.apache.catalina.startup.Bootstrap
root     31645 29718  0 11:54 pts/0    00:00:00 grep --color=auto tomcat
```

> 从上面的进程信息可以看到 Tomcat 服务的进程，现在已经是使用的 tomcat 用户运行了。

