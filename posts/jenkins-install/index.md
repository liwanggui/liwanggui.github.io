# Jenkins 安装配置


## 安装

- 官方安装文档: [https://pkg.jenkins.io/redhat-stable/](https://pkg.jenkins.io/redhat-stable/)

```bash
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install jenkins
```

## 配置

### 配置方法1

配置前先启动 `jenkins` 服务, 在浏览器打开 `http://<your_server_ip_address>:8080`

```bash
systemctl start jenkins
```

执行以下命令

```bash
mkdir -p /var/lib/jenkins/update-center-rootCAs
wget https://cdn.jsdelivr.net/gh/lework/jenkins-update-center/rootCA/update-center.crt -O /var/lib/jenkins/update-center-rootCAs/update-center.crt
chown jenkins.jenkins -R /var/lib/jenkins/update-center-rootCAs
sed -i 's#https://updates.jenkins.io/update-center.json#https://cdn.jsdelivr.net/gh/lework/jenkins-update-center/updates/huawei/update-center.json#' /var/lib/jenkins/hudson.model.UpdateCenter.xml
```

在浏览器进行下一步时如果提示 "安装过程中出现一个错误： No such plugin: cloudbees-folder" 错误信息，这时我们只需要在 `url` 后面加 `/restart` 跳过安装插件的界面，重启 `jenkins` 即可

### 配置方法2

1. 启动 `jenkins` 服务，打开浏览器完成初始化
2. 进入 `Manage Jenkins` -> `Manage Plugin` -> `Advanced` 最下面有 `Update Site` 设置为：`https://mirrors.huaweicloud.com/jenkins/updates/update-center.json`， 点击 `Submit` 提交，然后在点击 `check now`
3. 修改 jenkins 配置，进入 `/var/lib/jenkins` 目录 ， 将 `updates/default.json` 其中的  `https://updates.jenkins.io/download` 替换为 `https://mirrors.huaweicloud.com/jenkins` ，然后把 `www.google.com` 修改为 `www.baidu.com`
4. 重启 `Jenkins` 服务
5. 享受加速下载插件的快感吧！

**替换为华为源**

```bash
sed -i 's@https://updates.jenkins.io/download@https://mirrors.huaweicloud.com/jenkins@g' /var/lib/jenkins/updates/default.json
```

**替换为清华大学源**

重复以上步骤，地址进行相应的替换

- 源地址: [https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json](https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json)

```bash
sed -i 's@https://updates.jenkins.io/download@https://mirrors.tuna.tsinghua.edu.cn/jenkins@g' /var/lib/jenkins/updates/default.json
```
