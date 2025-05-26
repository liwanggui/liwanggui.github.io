# 利用多核 CPU 进行解/压缩


linux 下最受欢迎的多线程归档器是 pigz（而不是gzip）和 pbzip2（而不是bzip2)

## 开始使用

`pigz` 可以当做是 `gzip` 高级版，可以执行 `gzip` 的工作，但是在压缩时会将工作分散到多个处理器和内核上。

`pbzip2` 可以当做是 `bzip2` 高级版, 在和 `tar` 命令一起使用时需要手动使用的压缩程序, 信息如下:

```bash
  -I, --use-compress-program=PROG
```

默认情况系统并没有安装 `pigz`，`pbzip2`, 需要手动安装执行下以下命令安装

```bash
$ yum install -y pigz pbzip2
```

## 示例

```bash
$ tar -I pbzip2 -cf OUTPUT_FILE.tar.bz2 paths_to_archive
$ tar --use-compress-program=pigz -cf OUTPUT_FILE.tar.gz paths_to_archive
```

Archiver 必须接受 `-d` 如果替换实用程序没有此参数和/或您需要指定其他参数，则使用管道（如有必要，添加参数）：

```bash
$ tar cf - paths_to_archive | pbzip2 > OUTPUT_FILE.tar.gz
$ tar cf - paths_to_archive | pigz > OUTPUT_FILE.tar.gz
```

> 解压只需要将 `-c` 替换为 `-x` 即可.
