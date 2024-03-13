# Git 仓库完整迁移含历史记录


## 迁移 Git 仓库

如果你想从别的 Git 托管服务器那里复制一份源代码到新的 Git 托管服务器上的话，可以通过以下步骤来操作。

> 这个文档只是让我们知道手动如何操作，大部分的 Git 代码托管平台和管理软件(Github, Gitlab, Gitee，Gogs, Gitea) 都支持仓库的在线克隆

1. 从原地址克隆一份裸版本库，比如原本托管于 GitHub

```bash
git clone --bare git://github.com/username/project.git 
```

2. 然后到新的 Git 服务器上创建一个新项目，比如 GitCafe。
3. 以镜像推送的方式上传代码到 GitCafe 服务器上。

```bash
cd project.git
git push --mirror git@gitcafe.com/username/newproject.git 
```

4. 删除本地代码

```bash
cd ..
rm -rf project.git 
```

5. 到新服务器 GitCafe 上找到 Clone 地址，直接 Clone 到本地就可以了。 

```bash
git clone git@gitcafe.com/username/newproject.git 
```

这种方式可以保留原版本库中的所有内容。提交前要删除本地 remotes 中的分支引用，这样就不会将 remotes 里面的远程分支也推到服务器上去: 

> 来源: [http://blog.csdn.net/candyguy242/article/details/45920111](http://blog.csdn.net/candyguy242/article/details/45920111)

