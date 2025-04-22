# Ubuntu Server 安装配置 bind9


域名服务（DNS）是一种Internet服务，可将IP地址和标准域名（FQDN）相互映射。这样，DNS减轻了记住IP地址的需要。运行DNS的计算机称为名称服务器。Ubuntu附带了BIND (Berkley Internet Naming Daemon)，BIND是用于在Linux上维护名称服务器的最常用程序。

## 安装

在终端提示符下，输入以下命令安装 dns:

```bash
sudo apt install bind9
```

dnsutils 软件包是测试和解决 DNS 问题非常有用的。 这些工具通常已经安装，但是要检查或安装 dnsutils，请输入以下内容：

```bash
sudo apt install dnsutils
```

## 配置角色

有许多方法可以配置BIND9。一些最常见的配置是缓存名称服务器，主服务器和辅助服务器。

- 当配置为缓存名称服务器时，BIND9将找到名称查询的答案，并在再次查询域时记住答案。
- 作为主要服务器，BIND9从其主机上的文件中读取区域的数据，并且对该区域具有权威性。
- 作为辅助服务器，BIND9从另一个对该区域具有权威性的名称服务器获取区域数据。


## 配置文件概览

DNS配置文件存储在 `/etc/bind` 目录中。主要配置文件是 `/etc/bind/named.conf` ，在软件包提供的布局中仅包括这些文件。

- /etc/bind/named.conf.options：DNS 全局选项配置文件
- /etc/bind/named.conf.local：自定义区域配置文件
- /etc/bind/named.conf.default-zones：默认区域，例如localhost，其反向和根提示
根名称服务器曾经在文件中描述过 `/etc/bind/db.root` 。 现在由软件包 `/usr/share/dns/root.hints` 附带的文件提供了此功能 dns-root-data，并且在 `named.conf.default-zones` 上面的配置文件中对此进行了引用。

可以将同一服务器配置为缓存名称服务器，主要和辅助名称服务器：这都取决于它所服务的区域。服务器可以是一个区域的授权开始（SOA），同时为另一区域提供辅助服务。同时为本地LAN上的主机提供缓存服务。

## 缓存名称服务器

默认配置充当缓存服务器。只需取消注释并编辑 `/etc/bind/named.conf.options` 即可设置ISP的DNS服务器的IP地址：

```
forwarders {
    1.2.3.4;
    5.6.7.8;
};
```

> 注意:
> 用实际 DNS 服务器的IP地址替换 1.2.3.4 和 5.6.7.8。

要启用新配置，请重新启动DNS服务器。在终端提示下：

```bash
sudo systemctl restart bind9.service
```

## 主服务器

在本节中，将BIND9配置为域的主服务器 `example.com`。只需 `example.com` 用您的FQDN（完全合格的域名）替换即可。

### 转发区域文件

要将DNS区域添加到BIND9，将BIND9变成主服务器，请首先编辑 `/etc/bind/named.conf.local`：

```
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
};
```

> 注意
> 如果bind将像使用DDNS一样接收文件的自动更新，请在此处以及下面的复制命令中使用 `/var/lib/bind/db.example.com` 而不是 `/etc/bind/db.example.com`。

现在，使用现有的区域文件作为模板来创建 `/etc/bind/db.example.com` 文件：

```bash
sudo cp /etc/bind/db.local /etc/bind/db.example.com
```

编辑新的区域文件，`/etc/bind/db.example.com` 然后更改 localhost.为服务器的FQDN，.在末尾保留其他文件。更改 `127.0.0.1` 为名称服务器的IP地址和 `root.localhost` 有效的电子邮件地址，但用`.`代替通常的`@`符号，并再次.在末尾保留。更改注释以指示此文件所针对的域。

为基本域创建`A`记录`example.com`。此外，创建一个`A`记录的`ns.example.com`，在这个例子中，域名服务器：

```
;
; BIND data file for example.com
;
$TTL    604800
@       IN      SOA     example.com. root.example.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

@       IN      NS      ns.example.com.
@       IN      A       192.168.1.10
@       IN      AAAA    ::1
ns      IN      A       192.168.1.10
```

每次更改区域文件时，都必须增加序列号(Serial)。如果在重新启动BIND9之前进行了多次更改，只需增加一次串行。

现在，您可以将DNS记录添加到区域文件的底部。有关详细信息，请[参阅公共记录类型][1]。

> 注意，许多管理员喜欢使用最后编辑的日期作为区域的序列号(Serial)，例如2020012100，它是yyyymmddss(其中ss是序列号)


对区域文件进行了更改之后，需要重新启动BIND9以使更改生效

```bash
sudo systemctl restart bind9.service
```

### 反向区域文件

现在已经设置了区域并将名称解析为IP地址，现在需要添加反向区域以允许DNS将地址解析为名称。

编辑 `/etc/bind/named.conf.local` 并添加以下内容：

```
zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192";
};
```

> 注意:
> 将 `1.168.192` 替换为所用网络的前三个八位位组。 另外，适当命名区域文件 `/etc/bind/db.192`。 它应与网络的第一个八位位组匹配。

现在创建 `/etc/bind/db.192` 文件:

```bash
sudo cp /etc/bind/db.127 /etc/bind/db.192
```

接下来编辑 `/etc/bind/db.192`，更改与`/etc/bind/db.example.com`相同的选项：

```
;
; BIND reverse data file for local 192.168.1.XXX net
;
$TTL    604800
@       IN      SOA     ns.example.com. root.example.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.
10      IN      PTR     ns.example.com.
```

每次更改时，“反向”区域中的序列号也需要增加。 对于您在`/etc/bind/db.example.com`中配置的每个A记录（即针对另一个地址），您需要在`/etc/bind/db.192`中创建一个PTR记录。

创建反向区域文件后，重新启动BIND9

```bash
sudo systemctl restart bind9.service
```

## 辅助服务器

一旦配置了主服务器，强烈建议使用辅助服务器，以在主服务器不可用时维持域的可用性。

首先，在主服务器上，需要允许区域传输。将 `allow-transfer` 选项添加到示例正向和反向区域定义中 `/etc/bind/named.conf.local`：

```
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-transfer { 192.168.1.11; };
};
    
zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192";
    allow-transfer { 192.168.1.11; };
};
```

> 注意
> 替换192.168.1.11为辅助名称服务器的IP地址。

在主服务器上重新启动BIND9：

```
sudo systemctl restart bind9.service
```

接下来，在辅助服务器上，以与主服务器相同的方式安装bind9软件包。然后编辑，`/etc/bind/named.conf.local` 并为正向和反向区域添加以下声明：

```
zone "example.com" {
    type slave;
    file "db.example.com";
    masters { 192.168.1.10; };
};        
          
zone "1.168.192.in-addr.arpa" {
    type slave;
    file "db.192";
    masters { 192.168.1.10; };
};
```

> 注意
> 替换`192.168.1.10`为您的主要名称服务器的IP地址。

在辅助服务器上重新启动BIND9：

```bash
sudo systemctl restart bind9.service
```

在其中，`/var/log/syslog` 您应该看到类似以下内容的内容（为了适应本文档的格式，对某些行进行了拆分）：

```
client 192.168.1.10#39448: received notify for zone '1.168.192.in-addr.arpa'
zone 1.168.192.in-addr.arpa/IN: Transfer started.
transfer of '100.18.172.in-addr.arpa/IN' from 192.168.1.10#53:
 connected using 192.168.1.11#37531
zone 1.168.192.in-addr.arpa/IN: transferred serial 5
transfer of '100.18.172.in-addr.arpa/IN' from 192.168.1.10#53:
 Transfer completed: 1 messages, 
6 records, 212 bytes, 0.002 secs (106000 bytes/sec)
zone 1.168.192.in-addr.arpa/IN: sending notifies (serial 5)

client 192.168.1.10#20329: received notify for zone 'example.com'
zone example.com/IN: Transfer started.
transfer of 'example.com/IN' from 192.168.1.10#53: connected using 192.168.1.11#38577
zone example.com/IN: transferred serial 5
transfer of 'example.com/IN' from 192.168.1.10#53: Transfer completed: 1 messages, 
8 records, 225 bytes, 0.002 secs (112500 bytes/sec)
```

> 注意：仅当主服务器上的序列号大于辅助服务器上的序列号时，才会传输区域。如果要让您的主DNS通知其他辅助DNS服务器区域更改，则可以将其添加`also-notify { ipaddress; };`到`/etc/bind/named.conf.local`以下示例中：

```
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-transfer { 192.168.1.11; };
    also-notify { 192.168.1.11; }; 
};

zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192";
    allow-transfer { 192.168.1.11; };
    also-notify { 192.168.1.11; }; 
};
```

> 注意
> 非权威区域文件的默认目录为`/var/cache/bind/`。该目录还在AppArmor中配置为允许命名守护程序向其写入。有关AppArmor的更多信息，请参见[Security-AppArmor][2]。


## 测试

### resolv.conf

测试BIND9的第一步是将名称服务器的IP地址添加到主机解析器。应该配置主要名称服务器以及另一个主机，以仔细检查。有关将名称服务器地址添加到网络客户端的详细信息，请参阅DNS客户端配置。最后，您的`nameserver`一行`/etc/resolv.conf`应指向，`127.0.0.53`并且您应该`search`为您的域指定一个参数。像这样：

```
nameserver  127.0.0.53
search example.com
```

要检查您的本地解析器正在使用哪个DNS服务器，请运行：

```
systemd-resolve --status
```

> 注意
> 如果主要服务器不可用，您还应该将辅助名称服务器的IP地址添加到客户端配置中。

### dig

如果安装了dnsutils软件包，则可以使用DNS查找实用程序dig测试设置：

安装完BIND9之后，请对环回接口使用dig来确保它正在侦听端口53。从终端提示符下：

```
dig -x 127.0.0.1
```

您应该在命令输出中看到类似于以下内容的行：

```
;; Query time: 1 msec
;; SERVER: 192.168.1.10#53(192.168.1.10)
```

如果您已将BIND9配置为缓存名称服务器，则“挖掘”外部域以检查查询时间：

```
dig ubuntu.com
```

注意查询时间接近命令输出的末尾：

```
;; Query time: 49 msec
```

经过第二次挖掘后，应该有所改进：

```
;; Query time: 1 msec
```


### ping 

现在演示应用程序如何使用DNS解析主机名，使用ping实用程序发送ICMP回显请求：

```
ping example.com
```

这测试名称服务器是否可以将名称解析为`ns.example.com` IP 地址。 命令输出应类似于：

```
PING ns.example.com (192.168.1.10) 56(84) bytes of data.
64 bytes from 192.168.1.10: icmp_seq=1 ttl=64 time=0.800 ms
64 bytes from 192.168.1.10: icmp_seq=2 ttl=64 time=0.813 ms
```

### named-checkzone

测试区域文件的一种好方法是使用 `named-checkzone` 与bind9软件包一起安装的实用程序。使用此实用程序，可以在重新启动BIND9并使更改生效之前确保配置正确。

要测试我们的示例正向区域文件，请从命令提示符处输入以下内容：

```
named-checkzone example.com /etc/bind/db.example.com
```

如果一切配置正确，您应该会看到类似以下的输出：

```
zone example.com/IN: loaded serial 6
OK
```

同样，要测试反向区域文件，请输入以下内容：

```
named-checkzone 1.168.192.in-addr.arpa /etc/bind/db.192
```

输出应类似于：

```
zone 1.168.192.in-addr.arpa/IN: loaded serial 3
OK
```

## 日志

BIND9有多种可用的日志记录配置选项，但是两个主要的选项是`channel`和`category`，它们分别配置日志的去向和要记录的信息。

如果未配置任何日志记录选项，则默认配置为：

```
logging {
     category default { default_syslog; default_debug; };
     category unmatched { null; };
};
```

让我们将BIND9配置为将与DNS查询相关的调试消息发送到单独的文件。

我们需要配置一个通道以指定要将消息发送到的文件，以及一个category。在此示例中，类别将记录所有查询。编辑`/etc/bind/named.conf.local`并添加以下内容：

```
logging {
    channel query.log {
        file "/var/log/named/query.log";
        severity debug 3;
    };
    category queries { query.log; };
};
```

> 注意
> 该调试选项可以从1设置为3。如果没有指定级别，1级是默认的。

由于命名守护程序以绑定用户身份运行，因此`/var/log/named`必须创建目录并更改所有权：

```
sudo mkdir /var/log/named
sudo chown bind:bind /var/log/named
```

现在重新启动BIND9，以使更改生效：

```
sudo systemctl restart bind9.service
```

您应该看到文件中`/var/log/named/query.log`填充了查询信息。这是BIND9日志记录选项的简单示例。


> 注意
> 您的区域文件的序列号可能会有所不同。


  [1]: https://ubuntu.com/server/docs/service-domain-name-service-dns#heading--dns-record-types
  [2]: https://ubuntu.com/server/docs/security-apparmor
