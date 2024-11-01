# CentOS 7 重置 root 密码


1. 重启开机 
2. 按 e 编辑启动选项

{{< image src="/images/66b437a3-f85e-4c59-be11-aace46fed07f.png" caption="编辑启动选项-1" >}}

3. 编辑修改两处：`ro` 改为 `rw`, 在 `LANG=en_US.UFT-8` 后面添加 `init=/bin/bash`

{{< image src="/images/7907bae2-8fa0-42a6-b141-290fef05b58c.png" caption="编辑启动选项-2" >}}

4. 按 `Ctrl+X` 重启，并修改密码, 输入 `passwd root` 命令重置 `root` 密码
5. 由于 `selinux` 开启着的需要执行以下命令更新系统信息, 否则重启之后密码未生效

```bash
touch /.autorelabel
```

6. 重启系统

```bash
exec /sbin/init
```
