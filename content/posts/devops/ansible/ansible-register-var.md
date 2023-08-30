---
title: "Ansible 变量注册"
date: 2023-08-30T15:51:29+08:00
draft: false
categories: 
- devops
- ansible
tags:
- ansible
---

## 使用 register 注册变量

当 `playbook` 运行的时候，经常需要中途收集一些数据，后面使用它。 使用 `register` 注册变量是最简单、最常用的一种方式。

### 执行一条命令并把返回结果注册为变量

```yaml
- hosts: all
  tasks:
  - name: define a var1
    shell: "whoami"
    register: whoami

  - name: show var
    debug:
      msg: "whoami: {{ whoami }}"

  - name: show var.stdout
    debug:
      msg: "whoami.stdout: {{ whoami.stdout }}"
```

*执行结果输出*

```bash
PLAY [all] ****************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************
ok: [192.168.142.20]

TASK [define a var1] ******************************************************************************************************
changed: [192.168.142.20]

TASK [show var] ***********************************************************************************************************
ok: [192.168.142.20] => {
    "msg": "whoami: {'cmd': 'whoami', 'stdout': 'root', 'stderr': '', 'rc': 0, 'start': '2023-08-30 16:02:55.497249', 'end': '2023-08-30 16:02:55.501304', 'delta': '0:00:00.004055', 'changed': True, 'stdout_lines': ['root'], 'stderr_lines': [], 'failed': False}"
}

TASK [show var.stdout] ****************************************************************************************************
ok: [192.168.142.20] => {
    "msg": "whoami.stdout: root"
}

PLAY RECAP ****************************************************************************************************************
192.168.142.20             : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

> 注意： `ansible` 执行结果一般都会返回一个字典类型的数据，你会看到很多你不关心的字段，可以通过指定字典的 `key`，例如 `stdout` `或stdout_lines` ，只看到你关心的数据。


### 列表遍历的结果注册为变量

```yaml
- hosts: all
  vars:
    userss: []

  tasks:
    - name: define users in a loop
      shell: "grep {{ item }} /etc/passwd"
      register: users
      with_items:
        - root
        - nginx
    
    - name: show users
      debug:
        msg: "{{ users }}"

    - name: show users.results
      debug:
        msg: "{{ users.results }}"

    - name: define userss by set_fact
      set_fact: 
        userss: "{{userss +item.stdout_lines}}"
      with_list: "{{ users.results }}"

    - name: print userss
      debug:
        msg: "{{ userss }}"
    
    - name: print userss one by one
      debug:
        msg: "{{ item }}"
      with_list: "{{ userss}}"

    - name: print part of userss one by one
      debug:
        msg: "{{ item.split(':')[6] }}"
      with_list: "{{ userss}}"
```

*执行结果输出*

```bash
PLAY [all] ****************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************
ok: [192.168.142.20]

TASK [define users in a loop] *********************************************************************************************
changed: [192.168.142.20] => (item=root)
changed: [192.168.142.20] => (item=nginx)

TASK [show users] *********************************************************************************************************
ok: [192.168.142.20] => {
    "msg": {
        "changed": true,
        "msg": "All items completed",
        "results": [
            {
                "ansible_loop_var": "item",
                "changed": true,
                "cmd": "grep root /etc/passwd",
                "delta": "0:00:00.003829",
                "end": "2023-08-30 16:05:18.237586",
                "failed": false,
                "invocation": {
                    "module_args": {
                        "_raw_params": "grep root /etc/passwd",
                        "_uses_shell": true,
                        "argv": null,
                        "chdir": null,
                        "creates": null,
                        "executable": null,
                        "removes": null,
                        "stdin": null,
                        "stdin_add_newline": true,
                        "strip_empty_ends": true,
                        "warn": true
                    }
                },
                "item": "root",
                "rc": 0,
                "start": "2023-08-30 16:05:18.233757",
                "stderr": "",
                "stderr_lines": [],
                "stdout": "root:x:0:0:root:/root:/bin/bash\noperator:x:11:0:operator:/root:/sbin/nologin",
                "stdout_lines": [
                    "root:x:0:0:root:/root:/bin/bash",
                    "operator:x:11:0:operator:/root:/sbin/nologin"
                ]
            },
            {
                "ansible_loop_var": "item",
                "changed": true,
                "cmd": "grep nginx /etc/passwd",
                "delta": "0:00:00.005357",
                "end": "2023-08-30 16:05:18.620858",
                "failed": false,
                "invocation": {
                    "module_args": {
                        "_raw_params": "grep nginx /etc/passwd",
                        "_uses_shell": true,
                        "argv": null,
                        "chdir": null,
                        "creates": null,
                        "executable": null,
                        "removes": null,
                        "stdin": null,
                        "stdin_add_newline": true,
                        "strip_empty_ends": true,
                        "warn": true
                    }
                },
                "item": "nginx",
                "rc": 0,
                "start": "2023-08-30 16:05:18.615501",
                "stderr": "",
                "stderr_lines": [],
                "stdout": "nginx:x:1000:1001::/home/nginx:/bin/bash",
                "stdout_lines": [
                    "nginx:x:1000:1001::/home/nginx:/bin/bash"
                ]
            }
        ]
    }
}

TASK [show users.results] *************************************************************************************************
ok: [192.168.142.20] => {
    "msg": [
        {
            "ansible_loop_var": "item",
            "changed": true,
            "cmd": "grep root /etc/passwd",
            "delta": "0:00:00.003829",
            "end": "2023-08-30 16:05:18.237586",
            "failed": false,
            "invocation": {
                "module_args": {
                    "_raw_params": "grep root /etc/passwd",
                    "_uses_shell": true,
                    "argv": null,
                    "chdir": null,
                    "creates": null,
                    "executable": null,
                    "removes": null,
                    "stdin": null,
                    "stdin_add_newline": true,
                    "strip_empty_ends": true,
                    "warn": true
                }
            },
            "item": "root",
            "rc": 0,
            "start": "2023-08-30 16:05:18.233757",
            "stderr": "",
            "stderr_lines": [],
            "stdout": "root:x:0:0:root:/root:/bin/bash\noperator:x:11:0:operator:/root:/sbin/nologin",
            "stdout_lines": [
                "root:x:0:0:root:/root:/bin/bash",
                "operator:x:11:0:operator:/root:/sbin/nologin"
            ]
        },
        {
            "ansible_loop_var": "item",
            "changed": true,
            "cmd": "grep nginx /etc/passwd",
            "delta": "0:00:00.005357",
            "end": "2023-08-30 16:05:18.620858",
            "failed": false,
            "invocation": {
                "module_args": {
                    "_raw_params": "grep nginx /etc/passwd",
                    "_uses_shell": true,
                    "argv": null,
                    "chdir": null,
                    "creates": null,
                    "executable": null,
                    "removes": null,
                    "stdin": null,
                    "stdin_add_newline": true,
                    "strip_empty_ends": true,
                    "warn": true
                }
            },
            "item": "nginx",
            "rc": 0,
            "start": "2023-08-30 16:05:18.615501",
            "stderr": "",
            "stderr_lines": [],
            "stdout": "nginx:x:1000:1001::/home/nginx:/bin/bash",
            "stdout_lines": [
                "nginx:x:1000:1001::/home/nginx:/bin/bash"
            ]
        }
    ]
}

TASK [define userss by set_fact] ******************************************************************************************
ok: [192.168.142.20] => (item={'cmd': 'grep root /etc/passwd', 'stdout': 'root:x:0:0:root:/root:/bin/bash\noperator:x:11:0:operator:/root:/sbin/nologin', 'stderr': '', 'rc': 0, 'start': '2023-08-30 16:05:18.233757', 'end': '2023-08-30 16:05:18.237586', 'delta': '0:00:00.003829', 'changed': True, 'invocation': {'module_args': {'_raw_params': 'grep root /etc/passwd', '_uses_shell': True, 'warn': True, 'stdin_add_newline': True, 'strip_empty_ends': True, 'argv': None, 'chdir': None, 'executable': None, 'creates': None, 'removes': None, 'stdin': None}}, 'stdout_lines': ['root:x:0:0:root:/root:/bin/bash', 'operator:x:11:0:operator:/root:/sbin/nologin'], 'stderr_lines': [], 'failed': False, 'item': 'root', 'ansible_loop_var': 'item'})
ok: [192.168.142.20] => (item={'cmd': 'grep nginx /etc/passwd', 'stdout': 'nginx:x:1000:1001::/home/nginx:/bin/bash', 'stderr': '', 'rc': 0, 'start': '2023-08-30 16:05:18.615501', 'end': '2023-08-30 16:05:18.620858', 'delta': '0:00:00.005357', 'changed': True, 'invocation': {'module_args': {'_raw_params': 'grep nginx /etc/passwd', '_uses_shell': True, 'warn': True, 'stdin_add_newline': True, 'strip_empty_ends': True, 'argv': None, 'chdir': None, 'executable': None, 'creates': None, 'removes': None, 'stdin': None}}, 'stdout_lines': ['nginx:x:1000:1001::/home/nginx:/bin/bash'], 'stderr_lines': [], 'failed': False, 'item': 'nginx', 'ansible_loop_var': 'item'})

TASK [print userss] *******************************************************************************************************
ok: [192.168.142.20] => {
    "msg": [
        "root:x:0:0:root:/root:/bin/bash",
        "operator:x:11:0:operator:/root:/sbin/nologin",
        "nginx:x:1000:1001::/home/nginx:/bin/bash"
    ]
}

TASK [print userss one by one] ********************************************************************************************
ok: [192.168.142.20] => (item=root:x:0:0:root:/root:/bin/bash) => {
    "msg": "root:x:0:0:root:/root:/bin/bash"
}
ok: [192.168.142.20] => (item=operator:x:11:0:operator:/root:/sbin/nologin) => {
    "msg": "operator:x:11:0:operator:/root:/sbin/nologin"
}
ok: [192.168.142.20] => (item=nginx:x:1000:1001::/home/nginx:/bin/bash) => {
    "msg": "nginx:x:1000:1001::/home/nginx:/bin/bash"
}

TASK [print part of userss one by one] ************************************************************************************
ok: [192.168.142.20] => (item=root:x:0:0:root:/root:/bin/bash) => {
    "msg": "/bin/bash"
}
ok: [192.168.142.20] => (item=operator:x:11:0:operator:/root:/sbin/nologin) => {
    "msg": "/sbin/nologin"
}
ok: [192.168.142.20] => (item=nginx:x:1000:1001::/home/nginx:/bin/bash) => {
    "msg": "/bin/bash"
}

PLAY RECAP ****************************************************************************************************************
192.168.142.20             : ok=8    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## 使用 set_fact 注册变量

### 使用 set_fact 注册一个普通变量

*playbook*

```yaml
- hosts: all
  tasks:
    - name: define a var1
      shell: "whoami"
      register: whoami

    - debug:
        msg: "whoami: {{ whoami }}"

    - debug:
        msg: "whoami.stdout: {{whoami.stdout}}"

    - name: define a var by set_fact
      set_fact:
         whoami: "{{ whoami.stdout  }}"

    - name:  show a var after defined by set_fact
      debug:
         msg: "{{ whoami }}"
```

*结果输出*

```bash
PLAY [all] ****************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************
ok: [192.168.142.20]

TASK [define a var1] ******************************************************************************************************
changed: [192.168.142.20]

TASK [debug] **************************************************************************************************************
ok: [192.168.142.20] => {
    "msg": "whoami: {'cmd': 'whoami', 'stdout': 'root', 'stderr': '', 'rc': 0, 'start': '2023-08-30 16:08:28.677690', 'end': '2023-08-30 16:08:28.682671', 'delta': '0:00:00.004981', 'changed': True, 'stdout_lines': ['root'], 'stderr_lines': [], 'failed': False}"
}

TASK [debug] **************************************************************************************************************
ok: [192.168.142.20] => {
    "msg": "whoami.stdout: root"
}

TASK [define a var by set_fact] *******************************************************************************************
ok: [192.168.142.20]

TASK [show a var after defined by set_fact] *******************************************************************************
ok: [192.168.142.20] => {
    "msg": "root"
}

PLAY RECAP ****************************************************************************************************************
192.168.142.20             : ok=6    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```


> 来源: https://blog.51cto.com/byygyy/3858303
