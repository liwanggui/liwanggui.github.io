# 配置 DHCP 服务 实现 ip 地址自动分配


原因：由于公司使用 CentOS6.5 充当网关，为了避免麻烦给同事们一个个地去配置 IP 地址，
所以决定安装使用 dhcp 来自动分配 IP（之前是真一个一个去给他们配置 IP 地址，真他妈的累，烦，卖力而且不讨好~~）

## 1.安装DHCP

```bash
[root@localhost ~]# yum install -y dhcp
```

## 2.配置dhcpd.conf

```bash
[root@localhost ~]# vim /etc/dhcp/dhcpd.conf

#
# DHCP Server Configuration file.
#   see /usr/share/doc/dhcp*/dhcpd.conf.sample
#   see 'man 5 dhcpd.conf'
#
# 全局配置

# 设置客户端域名
option domain-name "wgsc.tv";
option domain-name-servers 192.168.1.60, 192.168.1.61;

# 默认租约12h
default-lease-time 43200;

# 最大租约24h
max-lease-time 86400;

# 不要ddns设定
ddns-update-style none;

# Use this to send dhcp log messages to a different log file (you also
# have to hack syslog.conf to complete the redirection).
log-facility local7;

# 设置DHCP子网段
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.181 192.168.1.230;
    option routers 192.168.1.1;
}


################### 服务器(设备)静态IP配置 ###################
# Java_bug_6
host device_1 {
  hardware ethernet fc:aa:14:3a:42:f0;
  fixed-address 192.168.1.6;
}

# k3-25
host device_2 {
  hardware ethernet fc:aa:14:48:62:98;
  fixed-address 192.168.1.25;
}

# ....省略一大串
```

## 3.配置dhcp监听接口

```bash
[root@localhost ~]# vim /etc/sysconfig/dhcpd
# Command line options here
DHCPDARGS=eth0
```

> *Tips:* CentOS7 以后不需要设置

## 4.关闭iptables

```bash
[root@localhost ~]# /etc/inin.d/iptables stop
[root@localhost ~]# chkconfig iptables off
```

## 5.启动dhcp服务

```bash
[root@localhost ~]# /etc/init.d/dhcpd start
```

> 注： 启动日志信息可以查看 `/var/log/message`  租约信息可查看 `/var/lib/dhcpd/dhcpd.leases`
