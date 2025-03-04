# 制作 uos server docker 镜像


由于统信 `UOS Server` 服务器系统官方没有提供 `docker` 基础镜像，所以只能自己动手制作，通过在互联网上查找资料后，制作测试成功并已上传至 [DockerHub 仓库](https://hub.docker.com/r/liwanggui/uos-server)，如需使用可通过以下命令直接获取

```bash
docker pull liwanggui/uos-server
```

下面将介绍镜像制作的具体方法，镜像基于 `uos-server-20-1060a-amd64` 镜像最小化安装制作

## 制作镜像

具体镜像制作步骤如下

1. 最小化安装 `uos-server-20-1060a`
2. 使用如下命令对系统进行打包, 打包时需排除 (`dev/proc/boot/run/sys` 目录), 使用 `-p` 选项保持文件目录权限不变

	```bash
	tar cvpf uos-server.tar bin  etc  home  lib  lib64  media  mnt  opt  root  sbin  srv  sys  tmp  usr  var
    ```

3. 将 `tar` 包导入 `docker` 

	```bash
	docker import uos-server.tar uos-server:v20-1060a
	```


以上直接打包的 tar 包中会存在一些垃圾文件，可以 `tar --delete` 命令删除

示例, 删除 `var/lock` 软链接文件

```bash
tar --delete --file=uos-server.tar var/lock
```

> 提示: 如需要删除一些不必要的软件包，可以在 步骤2 前进行操作

> 参考文章: https://cloud.tencent.com/developer/article/1920079
