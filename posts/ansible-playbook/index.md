# Ansible Playbook 示例


## playbook 示例1

使用 `ansible-playbook` (单文件)批量安装 `vsftp` 服务

*playbook*

```yaml
---
- hosts: all   # 指定操作的主机
  vars:  # 定义变量，此变量会传入模板
    userlist: /etc/vsftpd/user_list
    welcome: /etc/vsftpd/welcome.txt
  remote_user: root
  tasks:
  - name: install vsftpd
    yum: pkg=vsftpd state=latest
  - name: write vsftp config file
    template: src=/root/playbook/templates/vsftpd.conf dest=/etc/vsftpd/vsftpd.conf
    # 只有配置发生变化才会触发以下任务
    notify: # 触发任务，下面指定任务名
    - restart vsftpd
  - name: start vsftpd
    service: name=vsftpd state=started
  handlers:  # 定义触发任务
    - name: restart vsftpd
      service: name=vsftpd state=restarted
```

*templates* 模板

```bash
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

## playbook 示例2

将 playbook 分解成多个文件方便复用，文件夹结构如下：

```bash
[root@localhost playbook]# tree
.
├── handlers
│   └── restart.yaml
├── services
│   └── vsftpd.yaml
├── templates
│   └── vsftpd.conf
└── vsftpd.yaml
```

*vsftpd.yaml*

```bash
---
- hosts: all
  remote_user: root
  vars:
    userlist: /etc/vsftpd/user_list
    welcome: /etc/vsftpd/welcome.txt
  tasks:
    - include: /root/playbook/services/vsftpd.yaml
  handlers:
    - include: /root/playbook/handlers/restart.yaml server_name=vsftpd
```

*services/vsftpd.yaml* 

```bash
---
- name: install vsftpd
  yum: name=vsftpd state=present
- name: start vsftpd
  service: name=vsftpd state=started
- name: configure vsftpd
  template: src=/root/playbook/templates/vsftpd.conf dest=/etc/vsftpd/vsftpd.conf
  notify:
  - restart vsftpd
```

*templates/vsftpd.conf*

```bash
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

*handlers/restart.yaml*

```bash
---
- name: restart {{ server_name }}
  service: name={{ server_name }} state=restarted
```

