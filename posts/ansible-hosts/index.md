# Ansible 资源配置清单


## 主机与组基本配置

`ansible` 默认使用的主机配置文件路径为 `/etc/ansible/hosts`，使用 `ini` 文件格式，主机可以使用域名，IP，别名进行标识。

```ini
mail.example.com
192.168.1.10

[webserver]
192.168.1.11
192.168.1.12

[dbserver]
192.168.1.13:7733
```

> 其中 192.168.1.13:7733 的意思是定义一个ssh服务端口为7733的主机。

有时我们也可以使用别名的方式来描述一台主机

```ini
db1 ansible_ssh_port=4422 ansible_ssh_host=192.168.1.14
```

`db1` 为定义一个别名，`ansible_ssh_port` 为主机 `ssh` 端口，`ansible_ssh_host` 为主机 `ip` 地址，更多保留主机变量如下：

- `ansible_ssh_host`，连接目标主机的地址。
- `ansible_ssh_port`，连接目标主机SSH端口，端口22无需指定。
- `ansible_ssh_user`，连接目标主机默认用户。
- `ansible_ssh_pass`，连接目标主机默认用户密码。
- `ansible_connection`，目标主机连接类型，可以是local、ssh或paramiko。
- `ansible_ssh_private_key_file`, 连接目标主机的ssh私钥。
- `ansible_*_interpreter`，指定采用非Python的其他脚本语言，如 Ruby、Perl或其他类似 `ansible_python_interpreter` 解释器。

当然正则也是可以使用的

```ini
[webservers]
www[01:50].example.com

[databases]
db-[a:f].example.com
```

- `[01:50]`  表示匹配 01 至 50 所有主机
- `[a:f]`  表示匹配 a 至 f 当中所有的字母


## 定义主机变量

主机可以指定变量，以便后面供Playbooks配置使用，比如定义主机 `hosts1` 及 `hosts2` 上 `Apache` 参数 `http_port` 及 `maxRequestsPerChild` ，目的是让两台主机产生 `Apache` 配置文件 `httpd.conf` 差异化，定义格式如下：

```ini
[atlanta]
host1 http_port=80 maxRequestsPerChild=808
host2 http_port=303 maxRequestsPerChild=909
```

## 定义组变量

组变量的作用域是覆盖组所有成员，通过定义一个新块，块名由组名+“:vars”组成，定义格式如下：

```ini
[atlanta]
host1
host2

[atlanta:vars]
ntp_server=ntp.atlanta.example.com
proxy=proxy.atlanta.example.com
```

## 组嵌套组

同时 Ansible 支持组嵌套组，通过定义一个新块，块名由组名+":children"组成，格式如下：

```ini
[atlanta]
host1
host2

[raleigh]
host2
host3

[southeast:children]
atlanta
raleigh

[southeast:vars]
some_server=foo.southeast.example.com
halon_system_timeout=30
self_destruct_countdown=60
escape_pods=2

[usa:children]
southeast
northeast
southwest
southeast
```

> 嵌套组只能使用在 `/usr/bin/ansible-playbook` 中，在 `/usr/bin/ansible` 中不起作用。

