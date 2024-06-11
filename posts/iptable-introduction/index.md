# iptable 简单入门


## 规则表

- filter表，包含三个规则链：INPUT、FORWARD、OUTPUT。主要用于对数据包进行过滤
- nat表，包含三个规则链：PREROUTING、POSTROUTING、OUTPUT。主要用于网络地址转换（修改数据包的IP地址）
- mangle表，包含五个规则链：PREROUTING、POSTROUTING、INPUT、OUTPUT、FORWARD。主要用于修改数据包的TOS（服务类型）、TTL（生存周期）值以及为数据包设置Mark标记，以实现Qos调整以及策略路由等应用，由于需要相应的路由设备支持，因为应用并不广泛。
- raw表，包含两条规则链：OUTPUT、PREROUTING。主要用于决定数据包是否被状态跟踪机制处理。在匹配数据包时，raw表优先于其他表。

## 规则链

- INPUT链：当接收到访问防火墙本机地址的数据包（入站）时，应用此链的规则
- OUTPUT链：当防火墙本机向外发送数据包（出站）时应用此链的规则
- FORWARD链：当接收到需要通过防火墙发送给其他地址的数据包（转发）时，应用此链的规则
- PREROUTING链：在对数据包作路由选择之前，应用此链的规则
- POSTROUTING链：在对数据包作路由选择之后，应用此链的规则

## 应用顺序

1、规则表之间的应用顺序

当数据包抵达防火墙时，将依次应用raw、mangle、nat、filter表中对应链内的规则（如果有的话）。

2、规则链之间的应用顺序

- 入站数据流向：来自外界的数据包到达防火墙后，首先由PREROUTING规则链处理（是否修改数据包地址等），之后会进行路由选择（判断该数据包该发往何处），如果数据包的目标地址是防火墙本机（如Internet 用户访问防火墙中的Web服务的数据包），那么内核将其传递给INPUT链进行处理（决定是否允许通过等），通过以后再交给系统上层的应用程序（如httpd服务器）进行响应。
- 转发数据流向：来自外界的数据包到达防火墙后，首先被PREROUTING规则处理，之后会进行路由选择，如果数据包的目标地址是其他外部地址（如局域网用户通过网关访问QQ站点的数据包），则内核将其传给FORWARD链进行处理（是否转发或拦截），然后在交给POSTROUTING规则链（是否修改数据包的地址等）进行处理。
- 出站的数据流向：防火墙本机向外部地址发送的数据包（如防火墙主机中测试公网DNS服务时），首先被OUTPUT规则链处理，之后进行路由选择，然后传递给POSTROUTING规则链（是否修改数据包地址等）进行处理。

## iptables 基础语法

### iptable 参数说明

```bash
-A 在链的末尾添加一个规则 
-I 在链中插入一条规则，如未指定规则序号，则插入在首行
-D 删除一个规则，按规则序号或内容删除
-F 清空链中所有规则，如未指定链则清空表中所有链的规则
-L 以列表的形式显示规则
-N 新建一个条用户自定义的规则链
-P 指定链的默认规则
-n 以数字的形式显示结果
-v 查看规则列表时显示详细信息
--line-numbers 查看规则列表时，同时显示规则序号
```

### 添加及插入规则

在 filter 表的 INPUT 链中添加一条规则

```bash
iptables -t filter -A INPUT -p tcp -j ACCEPT
```

在 filter 表的 INPUT 链中插入一条规则

```bash
iptables -t filter -I INPUT -p udp -j ACCEPT
```

在 filter 表的 INPUT 链中插入一条规则（作为链中的第二条规则）

```bash
iptables -t filter -I INPUT 2 -p icmp -j ACCEPT
```

### 显示规则列表

查看 filter 表 INPUT 链中的所有规则，同时显示各条规则的顺序号

```bash
iptables -L INPUT --line-numbers
```

查看 filter 表各链所有规则的详细信息，同时以数字（速度更快）的形式显示地址及端口信息

```bash
iptables -vnL
```

### 删除、清空规则

删除第二条规则

```bash
iptables -D INPUT 2
```

清空 filter 表中所有链内的规则

```bash
iptables -F
iptables -t filter -F
```

清空 nat/mangle 表中所有链内的规则

```bash
iptables -t nat -F
iptables -t mangle -F
```

### 设置规则链的默认策略

设置 filter 表的 INPUT 链默认策略为 DROP

```bash
iptables -t filter -P INPUT DROP 
```

设置 filter 表的 OUTPUT 链默认策略为 ACCEPT

```bash
iptables -t filter -P OUTPUT ACCEPT
```

### 获得 iptables 相关选项用法的帮助信息

```bash
iptables -p icmp -h
```

## iptables 条件匹配

协议匹配：用于检查数据包的网络协议，允许使用的协议名包含在 `/etc/protocols` 文件中。使用 `-p`

拒绝所有 icmp 包进入

```bash
iptables -I INPUT -p icmp -j REJECT
```

允许转发所有非 icmp 协议的数据包（！取反）

```bash
iptables -A FORWARD -p ! icmp -j ACCEPT
```

地址匹配：用于检查数据包的IP地址、网络地址。使用 `-s`

拒绝转发源地址为192.168.1.11主机的数据

```bash
iptables -A FORWARD -s 192.168.1.11 -j REJECT
```

拒绝转发目标地址为 `192.168.2.0/24` 网段的数据

```bash
iptables -A FORWARD -d 192.168.2.0/24 -j REJECT
```

网络接口匹配：使用 `-o` 出接口 `-i` 进接口

```bash
iptables -A INPUT -i eth1 -s 192.168.0.11 -j DROP
iptables -A INPUT -o eth0 -d 192.168.1.10 -j ACCEPT
```

端口匹配：使用 `--dport` `--sport` 需要以 "`-p tcp`" 或 "`-p udp`" 为前提

允许转发局域网的 DNS 请求

```bash
iptables -A FORWARD -s 192.168.0.0/24 -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -d 192.168.0.0/24 -p udp --sport 53 -j ACCEPT
```

允许开放本机从 `TCP` 端口 `20~1024` 提供服务

```bash
iptables -A INPUT -p tcp --dport 20:1024 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 20:1024 -j ACCEPT
```

## 示例

```
# Firewall configuration written by system-config-securitylevel
# Manual customization of this file is not recommended.
*filter
# 默认策略
:INPUT DROP [5278:800028]   
:FORWARD DROP [5278:800028]
:OUTPUT ACCEPT [5278:800028]
:RH-Firewall-1-INPUT - [5278:800028]
# 自定义规则链
-A INPUT -j RH-Firewall-1-INPUT 
-A FORWARD -j RH-Firewall-1-INPUT
# 允许回环接口访问
-A RH-Firewall-1-INPUT -i lo -j ACCEPT 
# 状态检测，RELATED（相关的状态），ESTABLISHED(建立的)
-A RH-Firewall-1-INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
# 允许icmp 
-A RH-Firewall-1-INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT  
# 允许icmp
-A RH-Firewall-1-INPUT -p icmp -m icmp --icmp-type 3 -j ACCEPT  
# 开放相应服务的端口
-A RH-Firewall-1-INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A RH-Firewall-1-INPUT -p tcp -m state --state NEW -m tcp --dport 8001:8015 -j ACCEPT
-A RH-Firewall-1-INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
-A RH-Firewall-1-INPUT -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
-A RH-Firewall-1-INPUT -p tcp -m state --state NEW -m tcp --dport 3000 -j ACCEPT
-A RH-Firewall-1-INPUT -p tcp -m state --state NEW -m tcp --dport 3001 -j ACCEPT
-A RH-Firewall-1-INPUT -p tcp -m state --state NEW -m tcp --dport 110 -j ACCEPT
-A RH-Firewall-1-INPUT -p tcp -m state --state NEW -m tcp --dport 25 -j ACCEPT
-A RH-Firewall-1-INPUT -s 183.62.255.122,183.62.255.123,120.236.168.22,10.30.0.167 -p tcp -m state --state NEW -m tcp --dport 3306 -j ACCEPT
# 开放zabbix服务端口
-A RH-Firewall-1-INPUT -s 10.30.0.167 -m state --state NEW -m tcp -p tcp --dport 10050:10051 -j ACCEPT
-A RH-Firewall-1-INPUT -s 10.30.0.167 -m state --state NEW -m udp -p udp --dport 10050:10051 -j ACCEPT
COMMIT
```
