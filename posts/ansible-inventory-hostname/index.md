# Ansible 获取 hosts 中的分组 ip


## 获取当前主机 IP 地址

在 ansible 中，可以直接使用命令 `{{ inventory_hostname }}` 来获取，但此方法获取当前主机 IP 地址

```bash
# ansible -i hosts all -m shell -a 'echo {{ inventory_hostname }}'
192.168.142.20 | CHANGED | rc=0 >>
192.168.142.20
```

## 获取组内所有 IP 地址

如果想要获取到分组内的所有 ip，需要通过 {{ groups[组名称] }} 获取组对象来获取

```bash
# ansible -i hosts test -m shell -a 'echo {{ groups["test"] }}'
192.168.142.20 | CHANGED | rc=0 >>
[192.168.142.20, 192.168.142.22]
192.168.142.22 | CHANGED | rc=0 >>
[192.168.142.20, 192.168.142.22]
```

