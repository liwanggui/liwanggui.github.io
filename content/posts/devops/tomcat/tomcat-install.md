---
title: Tomcat 的简单使用
date: "2021-02-22T09:58:19+08:00"
draft: false
categories:
- devops
- tomcat
tags:
- tomcat
---

## Tomcat 介绍

Tomcat 是 Apache 软件基金会（Apache Software Foundation）项目中的一个核心项目，由 Apache、Sun 和其他一些公司及个人共同开发而成。

Tomcat 服务器是一个免费的开放源代码的 Web 应用服务器，属于轻量级应用服务器，在中小型系统和并发访问用户不是很多的场合下被普遍使用，是开发和调试 JSP 程序的首选。

> 实际生产环境中建议和 nginx 配合一起使用，nginx 处理静态，tomcat 处理动态程序

## 开始安装

安装 tomcat 前需先安装 JDK 工具包。 JDK 是 java 语言的软件开发工具包，它包含了 java 的运行环境（jvm + java 系统类库）和 java 工具。

### 安装 JDK

> JDK 下载地址: https://www.oracle.com/java/technologies/javase-downloads.html

> 这里我们选择安装 JDK 8

```bash
[root@10-7-171-239 src]# wget https://download.oracle.com/otn/java/jdk/8u281-b09/89d678f2be164786b292527658ca1605/jdk-8u281-linux-x64.tar.gz?AuthParam=1614219040_36465185941d2c06fb1457b5fc724aee -O jdk-8u281-linux-x64.tar.gz
[root@10-7-171-239 src]# tar xzf jdk-8u281-linux-x64.tar.gz -C /usr/local
[root@10-7-171-239 src]# cd /usr/local/
[root@10-7-171-239 local]# ln -s jdk1.8.0_281/ jdk
```

配置 JDK 环境变量

```bash
[root@10-7-171-239 local]# cat > /etc/profile.d/jdk.sh << EOF
> export JAVA_HOME=/usr/local/jdk
> export PATH=\$JAVA_HOME/bin:\$PATH
> EOF
[root@10-7-171-239 local]# source /etc/profile
[root@10-7-171-239 local]# java -version
java version "1.8.0_281"
Java(TM) SE Runtime Environment (build 1.8.0_281-b09)
Java HotSpot(TM) 64-Bit Server VM (build 25.281-b09, mixed mode)
```

### 安装 Tomcat

> Tomcat 下载地址: https://tomcat.apache.org/download-90.cgi

```bash
[root@10-7-171-239 src]# wget https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-9/v9.0.43/bin/apache-tomcat-9.0.43.tar.gz
[root@10-7-171-239 src]# tar xzf apache-tomcat-9.0.43.tar.gz -C /usr/local/
```

> Tomcat 的安装很简单，只要下载解压即可开始使用


### Tomcat 服务启停介绍

默认 Tomcat 启动可以直接执行 `bin` 目录的 `startup.sh` 脚本，停止使用 `shutdown.sh` 脚本，如果你查看这两个脚本文件中的内容会发现它们都是通过调用 `catalina.sh` 脚本并传递相应的参数进行启动的。 所以我们可以直接使用 .`catalina.sh` 脚本进行 Tomcat 服务的启动与停止.


**catalina.sh 脚本帮助信息**

```bash
[root@10-7-171-239 bin]# ./catalina.sh
Using CATALINA_BASE:   /usr/local/apache-tomcat-9.0.43
Using CATALINA_HOME:   /usr/local/apache-tomcat-9.0.43
Using CATALINA_TMPDIR: /usr/local/apache-tomcat-9.0.43/temp
Using JRE_HOME:        /usr/local/jdk
Using CLASSPATH:       /usr/local/apache-tomcat-9.0.43/bin/bootstrap.jar:/usr/local/apache-tomcat-9.0.43/bin/tomcat-juli.jar
Using CATALINA_OPTS:
Usage: catalina.sh ( commands ... )
commands:
  debug             Start Catalina in a debugger
  debug -security   Debug Catalina with a security manager
  jpda start        Start Catalina under JPDA debugger
  run               Start Catalina in the current window
  run -security     Start in the current window with security manager
  start             Start Catalina in a separate window
  start -security   Start in a separate window with security manager
  stop              Stop Catalina, waiting up to 5 seconds for the process to end
  stop n            Stop Catalina, waiting up to n seconds for the process to end
  stop -force       Stop Catalina, wait up to 5 seconds and then use kill -KILL if still running
  stop n -force     Stop Catalina, wait up to n seconds and then use kill -KILL if still running
  configtest        Run a basic syntax check on server.xml - check exit code for result
  version           What version of tomcat are you running?
Note: Waiting for the process to end and use of the -force option require that $CATALINA_PID is defined
```

### 启动 Tomcat 服务

```bash
[root@10-7-171-239 apache-tomcat-9.0.43]# /usr/local/apache-tomcat-9.0.43/bin/startup.sh
Using CATALINA_BASE:   /usr/local/apache-tomcat-9.0.43
Using CATALINA_HOME:   /usr/local/apache-tomcat-9.0.43
Using CATALINA_TMPDIR: /usr/local/apache-tomcat-9.0.43/temp
Using JRE_HOME:        /usr/local/jdk
Using CLASSPATH:       /usr/local/apache-tomcat-9.0.43/bin/bootstrap.jar:/usr/local/apache-tomcat-9.0.43/bin/tomcat-juli.jar
Using CATALINA_OPTS:
Tomcat started.
[root@10-7-171-239 apache-tomcat-9.0.43]# ss -anptl | grep java
LISTEN     0      1         ::ffff:127.0.0.1:8005                    :::*                   users:(("java",pid=30004,fd=68))
LISTEN     0      100         :::8080                    :::*                   users:(("java",pid=30004,fd=57))
```

> Tomcat 默认监听于 8080 端口，直接在浏览器上访问 http://<your_server_ipaddress>:8080


```bash
[root@10-7-171-239 apache-tomcat-9.0.43]# ps -ef | grep tomcat
root     30004     1  8 10:23 pts/0    00:00:02 /usr/local/jdk/bin/java -Djava.util.logging.config.file=/usr/local/apache-tomcat-9.0.43/conf/logging.properties -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djdk.tls.ephemeralDHKeySize=2048 -Djava.protocol.handler.pkgs=org.apache.catalina.webresources -Dorg.apache.catalina.security.SecurityListener.UMASK=0027 -Dignore.endorsed.dirs= -classpath /usr/local/apache-tomcat-9.0.43/bin/bootstrap.jar:/usr/local/apache-tomcat-9.0.43/bin/tomcat-juli.jar -Dcatalina.base=/usr/local/apache-tomcat-9.0.43 -Dcatalina.home=/usr/local/apache-tomcat-9.0.43 -Djava.io.tmpdir=/usr/local/apache-tomcat-9.0.43/temp org.apache.catalina.startup.Bootstrap start
root     30038 29718  0 10:24 pts/0    00:00:00 grep --color=auto tomcat
```

> 通过查看 tomcat 进程可以看到 tomcat 默认使用 root 用户启动，这会存在安全风险，那该如何使用普通用户启动呢？


## Tomcat 目录结构

```bash
[root@10-7-171-239 apache-tomcat-9.0.43]# tree -L 1 -d
.
├── bin     # 管理脚本存放路径
├── conf    # 配置文件目录
├── lib     # 公共程序库目录
├── logs    # 日志目录
├── temp    
├── webapps  # 默认 web 应用程序目录
└── work
```

### webapps 目录

`webapps` 目录存放都是 web 应用，每个目录都是单独的应用。其中 `ROOT` 比较特殊，`ROOT` 目录中的应用是打开网页可以直接访问到的，例如 `http://localhost:8080` 访问的是 `ROOT` 目录中的应用，如果需要访问 `docs` 应用需要在 url 上加上 `http://localhost:8080/docs/` 路径。

```bash
[root@10-7-171-239 apache-tomcat-9.0.43]# tree webapps -L 1 -d
webapps
├── docs
├── examples
├── host-manager
├── manager
└── ROOT
```

> 默认 webapps 中有 Tomcat 自带管理应用，不用可以移除。


## 配置 Tomcat 

### 配置介绍

Tomcat 的配置文件存放在 `conf` 目录中，其中 `server.xml` 为主配置文件。默认配置信息如下

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- port: tomcat 服务管理端口， 
shutdown: 服务停止字符，如果从服务管理端口接收到此字符 tomcat 服务将会停止，
有安全风险，建议更改为更复杂的字符串。 
可以使用 cat /dev/urandom | head -n 1 | md5sum 生成
-->
<Server port="8005" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
  <GlobalNamingResources>
    <Resource name="UserDatabase" auth="Container"
              type="org.apache.catalina.UserDatabase"
              description="User database that can be updated and saved"
              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
              pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>
  <Service name="Catalina">
  <!-- HTTP 服务监听的端口 -->
    <Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
     <!-- defaultHost: 定义缺省处理请求的虚拟主机域名 -->
    <Engine name="Catalina" defaultHost="localhost">
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>
      <!-- 虚拟主机定义, name: 域名， appBase: WEB 应用程序路径  -->
      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">
       
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />
      </Host>
    </Engine>
  </Service>
</Server>
```

### Tomcat url 路径配置

如果想让 Tomcat 的根指向为 `webapps` 中的 `test` 应用该如何配置？？

*准备测试数据*

```bash
[root@10-7-171-239 webapps]# mkdir test
[root@10-7-171-239 webapps]# echo 'hello test file' > test/index.html
```

*修改 server.xml 配置文件, 在 `Host` 节点加入 `Context` 配置项，具体内容如下*

```xml
<Context path="/" docBase="test/" reloadable="false" debug="0" />
```

- `path`: 指定 url 路径，如果是 / 可以忽略不写
- `docBase`: 用于指定 WEB 应用路径，可以是相当路径（相对于 Host 的 `appBase` 属性的值），也可以是绝对路径
- `reloadable`: 是否自动重载，建议值设置为 `false`，此属性会影响服务性能

*重启服务，测试*

```bash
[root@10-7-171-239 apache-tomcat-9.0.43]# ./bin/shutdown.sh
[root@10-7-171-239 apache-tomcat-9.0.43]# ./bin/startup.sh
[root@10-7-171-239 apache-tomcat-9.0.43]# curl localhost:8080
hello test file
```
