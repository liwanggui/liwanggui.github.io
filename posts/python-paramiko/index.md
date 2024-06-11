# Paramiko SSH 远程连接 Linux 主机


> Paramiko Github 仓库: [https://github.com/paramiko/paramiko](https://github.com/paramiko/paramiko)

> Paramiko 扩展模块 scp.py Github 仓库: [https://github.com/jbardin/scp.py](https://github.com/jbardin/scp.py)

## 安装 paramiko 

```bash
pip install paramiko
```

## SSH 连接

### 用户名密码

```python
import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy)
client.connect(hostname='192.168.31.100', port=22, username='root', password='123456')
stdin, stdout, stderr = client.exec_command('ls')

for line in stdout:
    print('... ' + line.strip('\n'))
client.close()
```

### 使用私钥

```python
import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy)

client.connect(hostname='192.168.31.100', port=22, username='root', key_filename="<你的私钥路径>", passphrase="<私钥密码>")

# pkey = paramiko.RSAKey(data=None, filename='<你的私钥路径>', password='<私钥密码>')
# client.connect('118.193.40.147', username='root', pkey=pkey)

stdin, stdout, stderr = client.exec_command('ls')

for line in stdout:
    print('... ' + line.strip('\n'))
client.close()
```

### 使用代理

**paramiko 实现网关代理连接功能**

由于 paramiko 在 windows 下不能使用 ssh 代理连接远程主机，经过苦苦寻找，终于在 fabirc 源代码找到解决方案（fabric 命令有一个选项 gateway 允许用户指定一台网关机，然后所有主机连接都会经过这台网关主机中转连接），代码如下：

```python
import paramiko

gateway = paramiko.SSHClient()
gateway.set_missing_host_key_policy(paramiko.MissingHostKeyPolicy())
gateway.connect(hostname="192.168.92.131", port=22, username="root", password='liwanggui', timeout=5)

# 关键就这一步了
sock = gateway.get_transport().open_channel('direct-tcpip', ('192.168.22.2', int(22)), ('', 0))

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.MissingHostKeyPolicy())
ssh.connect(hostname="192.168.22.2", port=22, username="root", password='liwanggui', sock=sock, timeout=5)

session = ssh.get_transport().open_session()

session.exec_command('uptime')

exit_status = session.recv_exit_status()
stdout = session.makefile('r').read()
stderr = session.makefile_stderr('r').read()

print(exit_status, stdout, stderr)

ssh.close()
gateway.close()
```

**通过 ProxyCommand 实现**

> *此方法仅适用于类 `unix` 系统*, 代码如下：

```python
import paramiko
import time

private_key_file = "/root/.ssh/id_rsa"
proxy_command = r"ssh -i /root/.ssh/id_rsa -p 22 -o StrictHostKeyChecking=no root@192.168.92.131 -W 192.168.22.2:22"

sock = paramiko.proxy.ProxyCommand(proxy_command)
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.MissingHostKeyPolicy())
ssh.connect(hostname="192.168.22.2", port=22, username="root", key_filename=private_key_file, sock=sock, timeout=5)

chan = ssh.get_transport().open_session()
chan.exec_command('uptime')
# 命令执行退出状态 0 成功， 其他数字 失败
exit_status = chan.recv_exit_status()
# 标准输出结果
stdout = chan.makefile('r').read()
# 标准错误输出结果
stderr = chan.makefile_stderr('r').read()

print(exit_status, stdout, stderr)

```

**通过 socks 代理实现**

通过 `PySocks` 模块实现 `socks5` 代理功能，在 `linux` 平台使用没有问题，在 `windows` 中出错，代码如下：

```python
import socks
import socket
import paramiko

socks.setdefaultproxy(socks.PROXY_TYPE_SOCKS5, '127.0.0.1', 1080)
socket.socket = socks.socksocket

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
try:
    ssh.connect('192.168.22.2', 22, 'root', 'liwanggui', timeout=5)
except paramiko.AuthenticationException:
    print('password is error.')

chan = ssh.get_transport().open_session()
chan.exec_command('uptime')
exit_status = chan.recv_exit_status()
stdout = chan.makefile('r').read()
stderr = chan.makefile_stderr('r').read()
print(exit_status, stdout, stderr)
```

## 文件操作

这我们使用 `paramiko` 第三方扩展库 `scp.py` 进行文件上传下载操作，当然你也可以使用 `paramiko` 库进行文件上传下载

*安装 scp.py*

```bash
pip instal scp
```

### 简单的文件上传

```python
import paramiko

from scp import SCPClient

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy)
ssh.connect(hostname='192.168.31.100', port=22, username='root', key_filename="<你的私钥路径>", passphrase="<私钥密码>")

scp = SCPClient(ssh.get_transport())

# 上传下载文件，不指定完整路径默认就是用户的家目录
scp.put('/etc/hosts', 'mhost')
# 从用户的家目录下载 mhost 文件到当前目录下
scp.get('mhost')

# 上传目录至远程主机，并改名为 mail
scp.put('postfix', remote_path='/data/mail', recursive=True)
# 下载目录到当前路径下
scp.get('/data/mail', recursive=True)
scp.close()
```

### 使用 with 语法

```python
from paramiko import SSHClient
from scp import SCPClient

with SSHClient() as ssh:
    ssh.load_system_host_keys()
    ssh.connect('example.com')

    with SCPClient(ssh.get_transport()) as scp:
        scp.put('test.txt', 'test2.txt')
        scp.get('test2.txt')
```

### 上传文件类对象

使用 putfo 方法可用于上传文件类对象

```python
import io
from paramiko import SSHClient
from scp import SCPClient

ssh = SSHClient()
ssh.load_system_host_keys()
ssh.connect('example.com')

# SCPCLient takes a paramiko transport as an argument
scp = SCPClient(ssh.get_transport())

# generate in-memory file-like object
fl = io.BytesIO()
fl.write(b'test')
fl.seek(0)
# upload it directly from memory
scp.putfo(fl, '/tmp/test.txt')
# close connection
scp.close()
# close file handler
fl.close()
```

### 显示文件上传下载进度

跟踪文件上载/下载的进度

`progress` 函数可以作为对 `SCPClient` 的回调，以处理当前 SCP 操作如何处理传输的进度。在下面的示例中，我们打印文件传输的完成百分比。

```python
from paramiko import SSHClient
from scp import SCPClient
import sys

ssh = SSHClient()
ssh.load_system_host_keys()
ssh.connect('example.com')

# Define progress callback that prints the current percentage completed for the file
def progress(filename, size, sent):
    sys.stdout.write("%s's progress: %.2f%%   \r" % (filename, float(sent)/float(size)*100) )

# SCPCLient takes a paramiko transport and progress callback as its arguments.
scp = SCPClient(ssh.get_transport(), progress=progress)

# you can also use progress4, which adds a 4th parameter to track IP and port
# useful with multiple threads to track source
def progress4(filename, size, sent, peername):
    sys.stdout.write("(%s:%s) %s's progress: %.2f%%   \r" % (peername[0], peername[1], filename, float(sent)/float(size)*100) )
scp = SCPClient(ssh.get_transport(), progress4=progress4)

scp.put('test.txt', '~/test.txt')
# Should now be printing the current progress of your put function.

scp.close()
```
