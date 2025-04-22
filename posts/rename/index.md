# 利用 rename 批量重命名


**查看 rename 命令帮助信息**

```bash
[root@localhost ~]# rename --help

Usage:
 rename [options] expression replacement file...
 rename <要替换的字符> <替换后的字符>  <要修改的文件（可以使用通配符批量操作）>

Options:
 -v, --verbose    explain what is being done
 -s, --symlink    act on symlink target

 -h, --help     display this help and exit
 -V, --version  output version information and exit
```

**示例**

批量将 file 开头的文件, 由 file 改为 linux

```bash
[root@localhost tmp]# ls file*
file1  file2  file3  file4  file5
[root@localhost tmp]# rename file linux file*
[root@localhost tmp]# ls linux*
linux1  linux2  linux3  linux4  linux5
```

