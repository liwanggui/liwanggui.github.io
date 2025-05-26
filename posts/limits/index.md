# limits.conf 超过限制导致 ssh 登录失败


## 问题

由于想放开系统最大连接数限制修改了 `/etc/security/limits.conf` 配置文件，配置如下

```bash
root soft nofile 6553500
root hard nofile 6553500
* soft nofile 6553500
* hard nofile 6553500
```

保存退出后， SSH 再也连不上了，通过[网络搜索查询得知](https://blog.csdn.net/my_miuye/article/details/119121330)

> limits.conf 文件实际是 Linux PAM（插入式认证模块，Pluggable Authentication Modules）中 pam_limits.so 的配置文件，而且只针对单个会话。即在登录shell时，需要设定limits的值，但由于设定的值过大导致设置失败，无法登录shell，ssh 自然也就连接不上了

> `limits.conf` 最大值不得超过 `/proc/sys/fs/nr_open`
