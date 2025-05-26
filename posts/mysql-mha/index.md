# MySQL MHA 高可用配置


## MySQL MHA 架构介绍

官方文档: https://github.com/yoshinorim/mha4mysql-manager/wiki

MHA（Master High Availability）目前在MySQL高可用方面是一个相对成熟的解决方案，它由日本 DeNA 公司 youshimaton（现就职于Facebook公司）开发，是一套优秀的作为 MySQL 高可用性环境下故障切换和主从提升的高可用软件。
在MySQL故障切换过程中，MHA能做到在0~30秒之内自动完成数据库的故障切换操作，并且在进行故障切换的过程中，MHA能在最大程度上保证数据的一致性，以达到真正意义上的高可用。

该软件由两部分组成：MHA Manager（管理节点）和MHA Node（数据节点）。

MHA Manager 可以单独部署在一台独立的机器上管理多个 master-slave 集群，也可以部署在一台 slave 节点上。
MHA Node 运行在每台 MySQL 服务器上，MHA Manager 会定时探测集群中的 master 节点，当 master 出现故障时，它可以自动将最新数据的 slave 提升为新的 master，然后将所有其他的 slave 重新指向新的 master。整个故障转移过程对应用程序完全透明（配合 vip）。

在 MHA 自动故障切换过程中，MHA 试图从宕机的主服务器上保存二进制日志，最大程度的保证数据的不丢失，但这并不总是可行的。例如，如果主服务器硬件故障或无法通过 ssh 访问，MHA 没法保存二进制日志，只进行故障转移而丢失了最新的数据。使用 binlog-server 可以最大程度减少日志的缺失，大大降低数据丢失的风险。MHA 可以 binlog-server 结合起来。如果只有一个 slave已经收到了最新的二进制日志，MHA 可以将最新的二进制日志应用于其他所有的 slave 服务器上，因此可以保证所有节点的数据一致性。

目前 MHA 主要支持一主多从的架构，要搭建 MHA,要求一个复制集群中必须最少有三台数据库服务器，一主二从，即一台充当 master，一台充当备用 master，另外一台充当从库，因为至少需要三台服务器，出于机器成本的考虑，淘宝也在该基础上进行了改造，目前淘宝TMHA已经支持一主一从。

> 注: MHA 是一次性高可用，Failover 后, Manager 会自动退出

## MHA 工作原理

可以将 MHA 工作原理总结如下

1. 从宕机崩溃的 master 保存二进制日志事件（binlog events）;
2. 识别含有最新更新的 slave；
3. 应用差异的中继日志（relay log）到其他的 slave；
4. 应用从 master 保存的二进制日志事件（binlog events）；
5. 提升一个 slave 为新的 master；
6. 使其他的 slave 连接新的 master 进行复制；

## MHA 软件说明

MHA 软件由两部分组成，Manager 工具包和 Node 工具包，具体的说明如下。


**Manager 工具包主要包括以下几个工具：**

- `masterha_check_ssh`: 检查MHA的SSH配置状况
- `masterha_check_repl`: 检查MySQL复制状况
- `masterha_manger`: 启动MHA
- `masterha_check_status`: 检测当前MHA运行状态
- `masterha_master_monitor`: 检测master是否宕机
- `masterha_master_switch`: 控制故障转移（自动或者手动）
- `masterha_conf_host`: 添加或删除配置的server信息

**Node工具包（这些工具通常由MHA Manager的脚本触发，无需人为操作）主要包括以下几个工具：**

- `save_binary_logs`: 保存和复制master的二进制日志
- `apply_diff_relay_logs`: 识别差异的中继日志事件并将其差异的事件应用于其他的 slave
- `filter_mysqlbinlog`: 去除不必要的 ROLLBACK 事件（MHA 已不再使用这个工具）
- `purge_relay_logs`: 清除中继日志（不会阻塞 SQL 线程）

## 环境准备

环境说明: 

- 服务器数量: 3台，一主两从（使用 GTID 模式搭建主从环境，搭建过程略）
- 操作系统: Ubuntu 18.04 server,
- MySQL 版本: 5.7.28

> 注意: 如果需要使用 MHA 的 VIP 功能，三台机的网卡名必须一致

- Master:
    - ip: 10.10.1.2/24
    - vip: 10.10.1.10/24 (应用连接主库使用的 ip 地址)
    - server_id: 2
    - mha_role: node
- Slave1:
    - ip: 10.10.1.3/24
    - server_id: 3
    - mha_role: node
- Slave2:
    - ip: 10.10.1.4/24
    - server_id: 4
    - mha_role: node, manager

**创建 mha 管理 mysql 用户， 在主库执行**

```sql
create user mha@'10.10.1.%' identified by 'YMhHZawmFAFBEf6T';
grant all privileges on *.* to 'mha'@'10.10.1.%';
```

**配置 `mysql`, `mysqlbinlog` 软链接**

```bash
ln -s /usr/local/mysql/bin/mysql /usr/bin/
ln -s /usr/local/mysql/bin/mysqlbinlog /usr/bin/
```

### 配置 SSH 互信

MHA Manager 在内部通过 SSH 连接到 MySQL 服务器。最新从站上的 MHA 节点还通过 SSH（scp）在内部将中继日志文件发送到其他从站。为了使这些过程自动化，通常建议在不使用口令的情况下启用SSH公钥身份验证。您可以使用 MHA Manager 中包含的 masterha_check_ssh 命令来检查SSH连接是否正常工作。

*slave2 机器上操作*

```bash
ssh-keygen -t rsa
...（略）
ssh-copy -i /root/.ssh/id_rsa.pub 10.10.1.4

rsync -arvP /root/.ssh/ 10.10.1.2:/root./ssh
rsync -arvP /root/.ssh/ 10.10.1.3:/root./ssh
```

## 安装 MHA

MHA 下载地址:  
- mha4mysql-node: https://github.com/yoshinorim/mha4mysql-node/releases
- mha4mysql-manager: https://github.com/yoshinorim/mha4mysql-manager/releases

### 安装 mha4mysql-node

在三台机器执行安装

```bash
dpkg -i mha4mysql-node_0.58-0_all.deb
apt install -f
```

**修复 mha4mysql-node bug**

`mha4mysql-node-0.58` 版本中 `/usr/share/perl5/MHA/NodeUtil.pm` 文件在执行 `masterha_check_repl` 命令时会提示错误，修复方法: 直接从 `mha4mysql-node` 存储库下载最新的 [NodeUtil.pm](https://github.com/yoshinorim/mha4mysql-node/blob/master/lib/MHA/NodeUtil.pm) 覆盖即可


### 安装 mha4mysql-manager

在 slave2 机器上安装 mha4mysql-manager

```bash
dpkg -i mha4mysql-manager_0.58-0_all.deb
```

## 配置 MHA

### 生成 MHA 配置文件

```bash
# 创建配置目录
mkdir /etc/mha
# 配置 mha 配置文件
cat > /etc/mha/app1.conf <<EOF
[server default]
# mha 的工作目录
manager_workdir=/var/log/masterha
# mha-manager 的日志文件
manager_log=/var/log/masterha/app1.log
# 主库的 BINLOG 日志存储路径
master_binlog_dir=/data/mysql/3306
# MHA管理器 ping 主库主机的频率
ping_interval=2
# mha 管理 mysql 的用户名和密码
user=mha
password=123456
# mysql replication username and password
repl_user=repl
repl_password=123456
# ssh 连接其他服务器的用户名
ssh_user=root
# 主库故障切换时 VIP 漂移脚本文件，需要自定义
master_ip_failover_script=/usr/local/bin/master_ip_failover
# 故障切换时发送邮箱提示, 自定义脚本(可以调用通讯工具的 api 发送消息, 例如: 微信)
report_script=/usr/local/bin/alarm.sh

[server1]
hostname=10.10.1.2
port=3306

[server2]
hostname=10.10.1.3
port=3306
# 配置为备选主，但是如果日志量落后 master 太多话也可能不会选为新主
# 此时需要配合 check_repl_delay = 0 参数
candidate_master=1
# 不检查日志落后量
check_repl_delay=0

[server3]
hostname=10.10.1.4
port=3306

[binlog1]
# 不参与选主
no_master=1
hostname=10.10.1.4
# 注意此参数必须与 [server default] 下配置值不同
master_binlog_dir=/data/mysql/binlog
EOF
```

binlogserver 配置：找一台额外的机器，必须要有 MySQL 5.6 以上的版本，支持 gtid 并开启

> 注意: mha 配置文件名是可以自己随意指定，建议和业务有关。mha 可以管理多套主从高可用

### 配置 vip

#### vip 配置项

```ini
[server default]
master_ip_failover_script=/usr/local/bin/master_ip_failover
```

> 注意: 需要先在主库手动配置上 vip 地址，本例是: `10.10.1.10/24`

#### vip 切换脚本

注意: 使用 mha vip 功能需要保证所有机器的网卡名是一致的

脚本内容修改说明: 根据实际情况修改脚本 vip 变量: `$vip`, `$ssh_start_vip`, `$ssh_stop_vip`

```perl
#!/usr/bin/env perl

#  Copyright (C) 2011 DeNA Co.,Ltd.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#  Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

## Note: This is a sample script and is not complete. Modify the script based on your environment.

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use MHA::DBHelper;

my (
  $command,        $ssh_user,         $orig_master_host,
  $orig_master_ip, $orig_master_port, $new_master_host,
  $new_master_ip,  $new_master_port,  $new_master_user,
  $new_master_password
);

# vip 变量配置处
my $vip = '10.10.1.10/24';
my $ssh_start_vip = "/sbin/ip addr add $vip dev ens33";
my $ssh_stop_vip = "/sbin/ip addr del $vip dev ens33";

GetOptions(
  'command=s'             => \$command,
  'ssh_user=s'            => \$ssh_user,
  'orig_master_host=s'    => \$orig_master_host,
  'orig_master_ip=s'      => \$orig_master_ip,
  'orig_master_port=i'    => \$orig_master_port,
  'new_master_host=s'     => \$new_master_host,
  'new_master_ip=s'       => \$new_master_ip,
  'new_master_port=i'     => \$new_master_port,
  'new_master_user=s'     => \$new_master_user,
  'new_master_password=s' => \$new_master_password,
);

exit &main();

sub main {
  if ( $command eq "stop" || $command eq "stopssh" ) {

    # $orig_master_host, $orig_master_ip, $orig_master_port are passed.
    # If you manage master ip address at global catalog database,
    # invalidate orig_master_ip here.
    my $exit_code = 1;
    eval {

      # updating global catalog, etc
      $exit_code = 0;
    };
    if ($@) {
      warn "Got Error: $@\n";
      exit $exit_code;
    }
    exit $exit_code;
  }
    elsif ( $command eq "start" ) {

        # all arguments are passed.
        # If you manage master ip address at global catalog database,
        # activate new_master_ip here.
        # You can also grant write access (create user, set read_only=0, etc) here.
        my $exit_code = 10;
        eval {
            print "Enabling the VIP - $vip on the new master - $new_master_host \n";
            &start_vip();
            &stop_vip();
            $exit_code = 0;
        };
        if ($@) {
            warn $@;
            exit $exit_code;
        }
        exit $exit_code;
    }
    elsif ( $command eq "status" ) {
        print "Checking the Status of the script.. OK \n";
        `ssh $ssh_user\@$orig_master_host \" $ssh_start_vip \"`;
        exit 0;
    }
    else {
        &usage();
        exit 1;
    }
}


sub start_vip() {
    `ssh $ssh_user\@$new_master_host \" $ssh_start_vip \"`;
}
# A simple system call that disable the VIP on the old_master
sub stop_vip() {
   `ssh $ssh_user\@$orig_master_host \" $ssh_stop_vip \"`;
}


sub usage {
  print
"Usage: master_ip_failover --command=start|stop|stopssh|status --orig_master_host=host --orig_master_ip=ip --orig_master_port=port --new_master_host=host --new_master_ip=ip --new_master_port=port\n";
}
```

### 配置故障切换告警

故障切换告警脚本需自行开发，可以调用通讯应用的 api 接口发送信息，例如: 微信，叮叮等

```ini
[server default]
report_script=/usr/local/bin/alarm.sh
```

### 配置 binlogserver

#### mha 的 binlogserver 配置项

```ini
[binlog1]
no_master=1
hostname=10.10.1.4
# 注意此参数须与 [server default] 下配置值不同
master_binlog_dir=/data/mysql/binlog
```

#### 启动 binlogserver 服务

```bash
# 必须进入到自己创建好的目录
cd /data/mysql/binlog 
mysqlbinlog -R --host=10.10.1.10 --user=mha --password=mha --raw --stop-never mysql-bin.000001 &
```

- `--host=10.10.1.10`: 从主库拉取二进制日志
- `mysql-bin.000001`: 拉取二进制日志的起始日志文件名，可以在从库 `show slave status\G` 查看获取

> 注意： 拉取日志的起点, 需要按照目前从库的已经获取到的二进制日志点为起点 <br/>
> binlogserver 服务可以使用 supervisor 程序管理

### 环境检测

#### 检查 ssh 连接

```bash
root@db3:~# masterha_check_ssh --conf=/etc/mha/app1.conf
Tue Dec 29 20:09:18 2020 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Tue Dec 29 20:09:18 2020 - [info] Reading application default configuration from /etc/mha/app1.conf..
Tue Dec 29 20:09:18 2020 - [info] Reading server configuration from /etc/mha/app1.conf..
Tue Dec 29 20:09:18 2020 - [info] Starting SSH connection tests..
Tue Dec 29 20:09:23 2020 - [debug]
Tue Dec 29 20:09:19 2020 - [debug]  Connecting via SSH from root@10.10.1.4(10.10.1.4:22) to root@10.10.1.2(10.10.1.2:22)..
Tue Dec 29 20:09:20 2020 - [debug]   ok.
Tue Dec 29 20:09:20 2020 - [debug]  Connecting via SSH from root@10.10.1.4(10.10.1.4:22) to root@10.10.1.3(10.10.1.3:22)..
Tue Dec 29 20:09:22 2020 - [debug]   ok.
Tue Dec 29 20:09:24 2020 - [debug]
Tue Dec 29 20:09:19 2020 - [debug]  Connecting via SSH from root@10.10.1.3(10.10.1.3:22) to root@10.10.1.2(10.10.1.2:22)..
Tue Dec 29 20:09:22 2020 - [debug]   ok.
Tue Dec 29 20:09:22 2020 - [debug]  Connecting via SSH from root@10.10.1.3(10.10.1.3:22) to root@10.10.1.4(10.10.1.4:22)..
Tue Dec 29 20:09:23 2020 - [debug]   ok.
Tue Dec 29 20:09:24 2020 - [debug]
Tue Dec 29 20:09:18 2020 - [debug]  Connecting via SSH from root@10.10.1.2(10.10.1.2:22) to root@10.10.1.3(10.10.1.3:22)..
Tue Dec 29 20:09:20 2020 - [debug]   ok.
Tue Dec 29 20:09:20 2020 - [debug]  Connecting via SSH from root@10.10.1.2(10.10.1.2:22) to root@10.10.1.4(10.10.1.4:22)..
Tue Dec 29 20:09:23 2020 - [debug]   ok.
Tue Dec 29 20:09:24 2020 - [info] All SSH connection tests passed successfully.
```

#### 检查 mysql 连接

```bash
root@db3:~# masterha_check_ssh --conf=/etc/mha/app1.conf
Tue Dec 29 20:09:18 2020 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Tue Dec 29 20:09:18 2020 - [info] Reading application default configuration from /etc/mha/app1.conf..
Tue Dec 29 20:09:18 2020 - [info] Reading server configuration from /etc/mha/app1.conf..
Tue Dec 29 20:09:18 2020 - [info] Starting SSH connection tests..
Tue Dec 29 20:09:23 2020 - [debug]
Tue Dec 29 20:09:19 2020 - [debug]  Connecting via SSH from root@10.10.1.4(10.10.1.4:22) to root@10.10.1.2(10.10.1.2:22)..
Tue Dec 29 20:09:20 2020 - [debug]   ok.
Tue Dec 29 20:09:20 2020 - [debug]  Connecting via SSH from root@10.10.1.4(10.10.1.4:22) to root@10.10.1.3(10.10.1.3:22)..
Tue Dec 29 20:09:22 2020 - [debug]   ok.
Tue Dec 29 20:09:24 2020 - [debug]
Tue Dec 29 20:09:19 2020 - [debug]  Connecting via SSH from root@10.10.1.3(10.10.1.3:22) to root@10.10.1.2(10.10.1.2:22)..
Tue Dec 29 20:09:22 2020 - [debug]   ok.
Tue Dec 29 20:09:22 2020 - [debug]  Connecting via SSH from root@10.10.1.3(10.10.1.3:22) to root@10.10.1.4(10.10.1.4:22)..
Tue Dec 29 20:09:23 2020 - [debug]   ok.
Tue Dec 29 20:09:24 2020 - [debug]
Tue Dec 29 20:09:18 2020 - [debug]  Connecting via SSH from root@10.10.1.2(10.10.1.2:22) to root@10.10.1.3(10.10.1.3:22)..
Tue Dec 29 20:09:20 2020 - [debug]   ok.
Tue Dec 29 20:09:20 2020 - [debug]  Connecting via SSH from root@10.10.1.2(10.10.1.2:22) to root@10.10.1.4(10.10.1.4:22)..
Tue Dec 29 20:09:23 2020 - [debug]   ok.
Tue Dec 29 20:09:24 2020 - [info] All SSH connection tests passed successfully.
root@db3:~# masterha_check_repl --conf=/etc/mha/app1.conf
Tue Dec 29 20:09:59 2020 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Tue Dec 29 20:09:59 2020 - [info] Reading application default configuration from /etc/mha/app1.conf..
Tue Dec 29 20:09:59 2020 - [info] Reading server configuration from /etc/mha/app1.conf..
Tue Dec 29 20:09:59 2020 - [info] MHA::MasterMonitor version 0.58.
Tue Dec 29 20:10:01 2020 - [info] GTID failover mode = 1
Tue Dec 29 20:10:01 2020 - [info] Dead Servers:
Tue Dec 29 20:10:01 2020 - [info] Alive Servers:
Tue Dec 29 20:10:01 2020 - [info]   10.10.1.2(10.10.1.2:3306)
Tue Dec 29 20:10:01 2020 - [info]   10.10.1.3(10.10.1.3:3306)
Tue Dec 29 20:10:01 2020 - [info]   10.10.1.4(10.10.1.4:3306)
Tue Dec 29 20:10:01 2020 - [info] Alive Slaves:
Tue Dec 29 20:10:01 2020 - [info]   10.10.1.3(10.10.1.3:3306)  Version=5.7.28-log (oldest major version between slaves) log-bin:enabled
Tue Dec 29 20:10:01 2020 - [info]     GTID ON
Tue Dec 29 20:10:01 2020 - [info]     Replicating from 10.10.1.2(10.10.1.2:3306)
Tue Dec 29 20:10:01 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Tue Dec 29 20:10:01 2020 - [info]   10.10.1.4(10.10.1.4:3306)  Version=5.7.28-log (oldest major version between slaves) log-bin:enabled
Tue Dec 29 20:10:01 2020 - [info]     GTID ON
Tue Dec 29 20:10:01 2020 - [info]     Replicating from 10.10.1.2(10.10.1.2:3306)
Tue Dec 29 20:10:01 2020 - [info] Current Alive Master: 10.10.1.2(10.10.1.2:3306)
Tue Dec 29 20:10:01 2020 - [info] Checking slave configurations..
Tue Dec 29 20:10:01 2020 - [info] Checking replication filtering settings..
Tue Dec 29 20:10:01 2020 - [info]  binlog_do_db= , binlog_ignore_db=
Tue Dec 29 20:10:01 2020 - [info]  Replication filtering check ok.
Tue Dec 29 20:10:01 2020 - [info] GTID (with auto-pos) is supported. Skipping all SSH and Node package checking.
Tue Dec 29 20:10:01 2020 - [info] HealthCheck: SSH to 10.10.1.4 is reachable.
Tue Dec 29 20:10:02 2020 - [info] Binlog server 10.10.1.4 is reachable.
Tue Dec 29 20:10:02 2020 - [info] Checking recovery script configurations on 10.10.1.4(10.10.1.4:3306)..
Tue Dec 29 20:10:02 2020 - [info]   Executing command: save_binary_logs --command=test --start_pos=4 --binlog_dir=/data/mysql/binlog --output_file=/var/tmp/save_binary_logs_test --manager_version=0.58 --start_file=mybinlog.000005
Tue Dec 29 20:10:02 2020 - [info]   Connecting to root@10.10.1.4(10.10.1.4:22)..
  Creating /var/tmp if not exists..    ok.
  Checking output directory is accessible or not..
   ok.
  Binlog found at /data/mysql/binlog, up to mybinlog.000005
Tue Dec 29 20:10:03 2020 - [info] Binlog setting check done.
Tue Dec 29 20:10:03 2020 - [info] Checking SSH publickey authentication settings on the current master..
Tue Dec 29 20:10:03 2020 - [info] HealthCheck: SSH to 10.10.1.2 is reachable.
Tue Dec 29 20:10:03 2020 - [info]
10.10.1.2(10.10.1.2:3306) (current master)
 +--10.10.1.3(10.10.1.3:3306)
 +--10.10.1.4(10.10.1.4:3306)

Tue Dec 29 20:10:03 2020 - [info] Checking replication health on 10.10.1.3..
Tue Dec 29 20:10:03 2020 - [info]  ok.
Tue Dec 29 20:10:03 2020 - [info] Checking replication health on 10.10.1.4..
Tue Dec 29 20:10:03 2020 - [info]  ok.
Tue Dec 29 20:10:03 2020 - [info] Checking master_ip_failover_script status:
Tue Dec 29 20:10:03 2020 - [info]   /usr/local/bin/master_ip_failover --command=status --ssh_user=root --orig_master_host=10.10.1.2 --orig_master_ip=10.10.1.2 --orig_master_port=3306
Checking the Status of the script.. OK
RTNETLINK answers: File exists
Tue Dec 29 20:10:04 2020 - [info]  OK.
Tue Dec 29 20:10:04 2020 - [warning] shutdown_script is not defined.
Tue Dec 29 20:10:04 2020 - [info] Got exit code 0 (Not master dead).

MySQL Replication Health is OK.
```

### 启动 MHA 

由于 `masterha_manager` 需要手动将程序放入后台运行，这里使用 `supervisor` 作为进程管理工具

```bash
# 安装 supervisor
root@db3:~# apt install supervisor
# 启动 supervisor
root@db3:~# systemctl start supervisor.service
# 编写 supervisor mha 配置文件
root@db3:~# cd /etc/supervisor/conf.d/
root@db3:/etc/supervisor/conf.d# cat > mha.conf <<EOF
[program:mha]
command=/usr/bin/masterha_manager --conf=/etc/mha/app1.conf --remove_dead_master_conf --ignore_last_failover
process_name=%(program_name)s
numprocs=1
directory=/var/log/masterha
umask=022
autostart=true
startsecs=1
startretries=3
autorestart=unexpected
exitcodes=0,2
stopsignal=QUIT
stopwaitsecs=10
stopasgroup=false
killasgroup=false
user=root
redirect_stderr=true
stdout_logfile=/var/log/masterha/app1.log
stderr_logfile=/var/log/masterha/app1.log
EOF
# 更新 supervisor 配置
root@db3:/etc/supervisor/conf.d# supervisorctl update
# 查看 supervisor 管理进程信息
root@db3:/etc/supervisor/conf.d# supervisorctl status
```

## 故障测试

### 测试故障

停止主库进程，查看 masterha_manager 日志信息，检查主从复制状态, 请自行测试！

### 恢复过程

主库宕机后，binlogserver 自动停掉，masterha_manager 也会自动停止

处理思路:

1. 检查主从复制状态
2. 检查 masterha_manager 配置文件，查看前主库信息是否已经删除 (--remove_dead_master_conf 选项会自动删除故障主库配置信息)，如果存在故障切换可能失败。
3. 查看 masterha_manager 日志文件
4. 清理 binlogserver 二进制日志，重新获取新主库的 binlog 到 binlogserver 中 (使用了 vip 连接不需更改，启动服务即可)
5. 修复故障库，手工加入主从。
6. 重新配置 masterha_manager 配置文件 
7. 最后再启动 MHA

## 最后

虽然 mha 高可用解决了主库故障问题，但真实使用的只有一台主库别两台从库处于空闲状态，资源得不到有效的利用。
此时为了更好地利用资源，提升效率，我们可以在 mha 高可用的基础上加入读写分离架构进行优化提升效率。

> 参考资源: 
> 1. https://www.jianshu.com/p/0f7b5a962ba7
> 2. MHA 官方文档: https://github.com/yoshinorim/mha4mysql-manager/wiki
