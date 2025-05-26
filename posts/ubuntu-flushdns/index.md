# Ubuntu 刷新/删除 DNS 缓存


如果你没有在 Linux 下安装和运行 `Systemd-Resolved`、`DNSMasq`、`Nscd` 缓存服务，那就没有操作系统级的 DNS 缓存，不同的 Linux 发行版在刷新 DNS 缓存上方法是不同的。

> 以下操作在 Ubuntu 18.04 操作系统下进行

## 刷新 Systemd Resolved 缓存

`Ubuntu 18.04` 系统是使用 `Systemd Resolved` 服务来缓存 DNS 的，所以可以运行以下命令确定该服务是否运行：

```bash
sudo systemctl is-active systemd-resolved.service
```

如果服务运行，则会看到返回的活动状态信息，否则只会看到非活动状态。

删除 `Systemd Resolved` DNS 缓存的方法，运行以下命令：

```bash
sudo systemd-resolve --flush-caches
```

## 刷新 DNSMasq 缓存

如果你在 Ubuntu 18.04 下使用 `DNSMasq` 作为缓存服务器，要删除 DNS 缓存，请运行以下命令：

```bash
sudo systemctl restart dnsmasq.service
```

## 刷新 Nscd 缓存


如果使用了 Nscd，删除 DNS 缓存只需要运行以下命令：

```bash
sudo systemctl restart nscd.service
```

或者运行：

```bash
sudo service nscd restart
```
