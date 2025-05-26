# Ansible 常用模块


*ansible 命令格式：*

```bash
ansible all -m command -a "uptime"
```

- `-m` 指定使用的模块
- `-a` 指定模块的参数

> 默认使用 `/etc/ansible/hosts` 文件中定义的主机，也可以使用 `-i /path/hosts` 主机清单文件的位置

## 1. command

*command* 命令模块, 不支持管道 "|" 与 变量

```bash
[root@localhost ~]# ansible all -m command -a 'uptime'
192.168.17.130 | SUCCESS | rc=0 >>
 03:05:54 up 36 min,  3 users,  load average: 0.02, 0.04, 0.05

192.168.17.131 | SUCCESS | rc=0 >>
 03:05:54 up 32 min,  3 users,  load average: 0.01, 0.03, 0.03
```

## 2. shell

*shell* 功能基本与 `command` 类似,但是 `shell` 使用远程主机的 `/bin/sh` 运行命令,支持管道 。

```bash
[root@localhost ~]# ansible webserver -m shell -a '/tmp/test.sh'
192.168.17.131 | SUCCESS | rc=0 >>
UserName:  root
Ip address:  192.168.17.131

192.168.17.130 | SUCCESS | rc=0 >>
UserName:  root
Ip address:  192.168.17.130
```

## 3. script

*script* 是对指定的远程主机执行"本地脚本"，执行"远程脚本"请使用 `shell` 模块

```bash
[root@localhost ~]# ls
anaconda-ks.cfg  test.sh
[root@localhost ~]# ansible webserver -m script -a '/root/test.sh'
192.168.17.131 | SUCCESS => {
    "changed": true,
    "rc": 0,
    "stderr": "Shared connection to 192.168.17.131 closed.\r\n",
    "stdout": "UserName:  root\r\nIp address:  192.168.17.131\r\n",
    "stdout_lines": [
        "UserName:  root",
        "Ip address:  192.168.17.131"
    ]
}
192.168.17.130 | SUCCESS => {
    "changed": true,
    "rc": 0,
    "stderr": "Shared connection to 192.168.17.130 closed.\r\n",
    "stdout": "UserName:  root\r\nIp address:  192.168.17.130\r\n",
    "stdout_lines": [
        "UserName:  root",
        "Ip address:  192.168.17.130"
    ]
}
```

## 4. copy

```bash
[root@localhost ~]# ansible webserver -m copy -a 'src=/root/test.sh dest=/tmp/test.sh owner=root group=root mode=0755'
192.168.17.131 | SUCCESS => {
    "changed": true,
    "checksum": "15bd17b3f24fe74c6b2bd515469510a7c46423c9",
    "dest": "/tmp/test.sh",
    "gid": 0,
    "group": "root",
    "md5sum": "ef47fd4c2ae9500503156fea0fa11a12",
    "mode": "0644",
    "owner": "root",
    "size": 150,
    "src": "/root/.ansible/tmp/ansible-tmp-1498789225.9-220641470038608/source",
    "state": "file",
    "uid": 0
}
192.168.17.130 | SUCCESS => {
    "changed": true,
    "checksum": "15bd17b3f24fe74c6b2bd515469510a7c46423c9",
    "dest": "/tmp/test.sh",
    "gid": 0,
    "group": "root",
    "md5sum": "ef47fd4c2ae9500503156fea0fa11a12",
    "mode": "0644",
    "owner": "root",
    "size": 150,
    "src": "/root/.ansible/tmp/ansible-tmp-1498789225.91-98116970360767/source",
    "state": "file",
    "uid": 0
}
```

## 5. stat

获取远程文件状态信息，包括：`atime` `ctime` `mtime` `md5` `uid` `git` 等信息

```bash
[root@localhost ~]# ansible webserver -m stat -a 'path=/etc/hosts'
```

## 6. get_url

实现远程主机下载指定的 `url` 到本地

```bash
[root@localhost ~]# ansible all -m get_url -a 'url=http://www.baidu.com dest=/tmp/baidu.html mode=400 force=yes'
```

## 7. yum

linux 平台软件包管理工具操作模块，常见的有 `yum` `apt`

```bash
[root@localhost ~]# ansible all -m yum -a 'name=curl state=latest'
[root@localhost ~]# ansible all -m apt -a 'pkg=curl state=latest'
```

- latest 表示最新版本

## 8. cron

远程主机 `crontab` 配置

```bash
[root@localhost ~]# ansible all -m cron -a 'name="check dirs" hour="5,2" job="ls -lh"'
```

*效果如下*

```bash
[root@localhost ~]# crontab -l
#Ansible: check dirs
* 5,2 * * * ls -lh
```

## 9. mount

远程主机分区挂载

```bash
[root@localhost ~]# ansible all -m mount -a 'name=/mnt src=/dev/sdb3 fstype=ext3 opts=ro state=present'
```

## 10. service

远程主机系统服务管理

```bash
[root@localhost ~]# ansible all -m service -a 'name=crond state=stopped'
[root@localhost ~]# ansible all -m service -a 'name=crond state=started'
[root@localhost ~]# ansible all -m service -a 'name=crond state=restarted'
[root@localhost ~]# ansible all -m service -a 'name=crond state=reloaded'
```

- stopped 停止
- started 启动
- restarted 重启
- reloaded 重载

## 11. sysctl

远程主机 sysctl 配置

```bash
[root@localhost ~]# ansible all -m sysctl -a 'name=net.ipv4.ip_forward value=1 sysctl_file=/etc/sysctl.conf reload=yes'
```

## 12. user

远程主机用户管理

```bash
# 添加用户
[root@localhost ~]# ansible all -m user -a 'name=liwg shell=/sbin/bash home=/home/liwg'
# 删除用户
[root@localhost ~]# ansible all -m user -a 'name=liwg state=absent remove=yes'
```
