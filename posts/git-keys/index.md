# Git 使用指定的 key 连接


当 `ssh key` 文件不放在标准目录下， `git` 进行 `clone` `push` 操作时如何使用指定位置的 `ssh key`

## 最佳解决方案

在 `~/.ssh/config` 中添加配置

```ssh
host github.com
 HostName github.com
 IdentityFile /data/sshkey/github_rsa
 User git
```

> 保持密钥的权限为 `400`

## 次佳解决方案

**环境变量 `GIT_SSH_COMMAND`**

> 从 Git 版本 2.3.0 可以使用环境变量 `GIT_SSH_COMMAND` 如下所示

```bash
GIT_SSH_COMMAND="ssh -i /data/sshkey/github_rsa" git clone git@github.com:test/test.git
```

> 请注意，`-i` 有时可以被您的配置文件覆盖，在这种情况下，您应该给 SSH 一个空配置文件，如下所示

```bash
GIT_SSH_COMMAND="ssh -i /data/sshkey/github_rsa -F /dev/null" git clone git@github.com:test/test.git
```

**配置 core.sshCommand：**

从 Git 版本 2.10.0，您可以配置每个 repo 或全局，所以您不必再设置环境变量！

```bash
git config core.sshCommand "ssh -i ~/.ssh/id_rsa_example -F /dev/null"
git pull
git push
```

> 参考文档: [https://blog.csdn.net/SCHOLAR_II/article/details/72191042](https://blog.csdn.net/SCHOLAR_II/article/details/72191042)

