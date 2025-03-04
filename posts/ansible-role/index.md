# Ansible playbook 角色


## 目录结构

playbook 目录包括变量定义目录 group_vars、主机组定义文件hosts、全局配置文件site.yml、角色功能目录。
可以使用命令 `ansible-galaxy init role_name` 生成角色相应目录 

```bash
[root@localhost ~]# tree ansible_roles/
ansible_roles/
├── common  # 公共角色目录
│   ├── handlers
│   │   └── main.yml # 定义触发任务
│   ├── tasks
│   │   └── main.yml # 定义任务
│   ├── templates
│   │   └── ntp.conf.j2  # 定义模板
│   └── vars
│       └── main.yml  # 定义角色内的变量
├── ftp  # 安装ftp任务角色
│   ├── handlers
│   │   └── main.yml
│   ├── tasks
│   │   └── main.yml
│   ├── templates
│   │   └── vsftpd2.conf
│   └── vars
├── group_vars # 定义组变量，以组名命名文件
│   ├── all
│   └── ftpservers # 定义 ftpservers 组主机变量
├── hosts  # 主机清单，非必须，可以使用默认。使用时加 -i 选项
└── site.yml  # 程序入口文件
```

## 角色规范

角色定制以下规范，其中 `x` 为角色名。

- 如 `roles/x/tasks/main.yml` 文件存在，其中列出的任务将被添加到执行队列；
- 如 `roles/x/handlers/main.yml` 文件存在，其中所列的处理程序将被添加到执行队列；
- 如 `roles/x/vars/main.yml` 文件存在，其中列出的变量将被添加到执行队列；
- 如 `roles/x/meta/main.yml` 文件存在，所列任何作用的依赖关系将被添加到角色的列表（1.3及更高版本）；
- 任何副本任务可以引用 `roles/x/files/`无需写路径，默认相对或绝对引用；
- 任何模板任务可以引用文件中的 `roles/x/templates/` 无需写路径，默认相对或绝对引用。

## *hosts* 主机配置文件

```bash
[root@localhost ansible_roles]# cat hosts
manages ansible_connection=local ansible_ssh_host=127.0.0.1

[ftpservers]
192.168.17.130
192.168.17.131
```


## *group_vars* 定义主机组变量

*group_vars/ftpservers* 此配置文件内变量只对 ftpservers 组内的主机有效

```bash
[root@localhost ansible_roles]# cat group_vars/ftpservers
userlist: /etc/vsftpd/user_list
welcome: /etc/vsftpd/welcome.txt
```

*group_vars/all*  对所有主机有效

```bash
[root@localhost ansible_roles]# cat group_vars/all
ntpserver: ntp.sjtu.edu.cn
```


## *site.yml* 全局配置文件，程序入口

```bash
[root@localhost ansible_roles]# cat site.yml
---
# 任务名
- name: apply common configuration to all nodes
  hosts: all  # 任务操作主机或主机组
  roles: # 指定任务角色
    - common  # 运行 common角色


- name: configure and deploy the ftpservers
  hosts: ftpservers
  roles:
    - ftp
```

全局配置文件 `site.yml` 引用了两个角色，一个为公共类的 `common`，另一个为 `ftp` 类，分别对应 `nginx/common`、`nginx/web` 目录。以此类推，可以引用更多的角色，如 `db`、`nosql`、`hadoop` 等，前提是我们先要进行定义，通常情况下一个角色对应着一个特定功能服务。通过 `hosts` 参数来绑定角色对应的主机或组.


## *common* (公共)角色文件示例

角色common定义了handlers、tasks、templates、vars 4个功能类，分别存放处理程序、任务列表、模板、变量的配置文件main.yml，需要注意的是，vars/main.yml中定义的变量优先级高于/nginx/group_vars/all，可以从ansible-playbook的执行结果中得到验证。各功能块配置文件定义如下：

*common/tasks/main.yml*

```bash
[root@localhost ansible_roles]# cat common/tasks/main.yml
---
- name: install ntp
  yum: name=ntp state=present

- name: configure ntp file
  template: src=ntp.conf.j2 dest=/etc/ntp.conf
  notify: restart ntp

- name: start the ntp service
  service: name=ntpd state=started enabled=true

- name: test to see if selinux is running
  command: getenforce
  register: sestatus
  changed_when: false
```

*common/handlers/main.yml*

```bash
[root@localhost ansible_roles]# cat common/handlers/main.yml
---
- name: restart ntp
  service: name=ntpd state=restarted
```

*common/templates/main.yml*

```bash
[root@localhost ansible_roles]# cat common/templates/ntp.conf.j2
driftfile /var/lib/ntp/drift
restrict 127.0.0.1
restrict -6 ::1

server {{ ntpserver }}

includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
```

> `{{ ntpserver }}` 变量将从 `common/vars/main.yml` 中获取

*common/vars/main.yml*

```bash
[root@localhost ansible_roles]# cat common/vars/main.yml
ntpserver: 210.72.145.44
```

> *Tips:* 此处定义的变量优先级要高于 `group_vars` 中定义的变量


## *ftp* 角色文件示例

*ftp/tasks/main.yml*

```bash
[root@localhost ansible_roles]# cat ftp/tasks/main.yml
- name: install vsftpd
  yum: pkg=vsftpd state=latest

- name: write the vsftpd config file
  template: src=vsftpd2.conf dest=/etc/vsftpd/vsftpd.conf
  notify:
  - restart vsftpd
- name: start vsftpd
  service: name=vsftpd state=started
```

*ftp/handlers/main.yml*

```bash
[root@localhost ansible_roles]# cat ftp/handlers/main.yml
---
- name: restart vsftpd
  service: name=vsftpd state=restarted
```

*ftp/templates/vsftpd2.conf*

```bash
[root@localhost ansible_roles]# cat ftp/templates/vsftpd2.conf
anonymous_enable=NO

local_enable=YES
write_enable=YES
local_umask=022
local_root=/var/ftp
userlist_enable=YES
userlist_deny=YES
userlist_file={{ userlist }}

use_localtime=YES
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
pam_service_name=vsftpd
tcp_wrappers=YES
banner_file={{ welcome }}
chroot_local_user=YES
pasv_min_port=65530
pasv_max_port=65535
```

