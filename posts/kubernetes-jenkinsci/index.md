# 使用 jenkins 实现 Kubernetes CI


## 部署 Jenkins

*rbac.yaml*

创建 `ServiceAccount: jenkins-ci` 授予 `cluster-admin` 权限， `jenkins` 在 kubernetes 集群中创建工作节点需要权限

> 你也可以在 kubernetes 插件中配置验证信息

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins-ci
  namespace: devops
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-ci
  namespace: devops
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: jenkins-ci
  namespace: devops
```

*pvc.yaml*

为 `jenkins` 划分一块存储，用于持久化 `jenkins` 数据

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-data
  namespace: devops
spec:
  storageClassName: managed-nfs-storage
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
```

*jenkins-ci.yml*

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: devops
spec:
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      terminationGracePeriodSeconds: 10
      securityContext:
        runAsUser: 0
      containers:
      - name: jenkins
        image: jenkinsci/blueocean:1.24.6
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
          name: web
          protocol: TCP
        - containerPort: 50000
          name: agent
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 60
          timeoutSeconds: 5
          failureThreshold: 12
        readinessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 60
          timeoutSeconds: 5
          failureThreshold: 12
        volumeMounts:
        - name: data
          mountPath: /var/jenkins_home
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: jenkins-data
---

apiVersion: v1
kind: Service
metadata:
  labels:
    app: jenkins
  name: jenkins
  namespace: devops
spec:
  ports:
  - name: "web"
    port: 8080
    protocol: TCP
    targetPort: 8080
  - name: "agent"
    port: 50000
    protocol: TCP
    targetPort: 50000
  selector:
    app: jenkins
  type: ClusterIP
```

*ingress-route.yml*

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: jenkins
  namespace: devops
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`jenkins.host.com`)
    kind: Rule
    services:
    - name: jenkins
      port: 8080
```

应用资源配置清单

```bash
kubectl apply -f rbac.yaml
kubectl apply -f pvc.yaml
kubectl apply -f configmap.yml
kubectl apply -f jenkins-ci.yml
kubectl apply -f ingress-route.yml
```

## 配置 jenkins 

### 首次登录配置

在浏览器打开 `http://jenkins.host.com` 开始配置 `jenkins` 

![jenkins-config](/images/jenkins-config.png)

下一步安装推荐插件即可，等待插件安装完成

![jenkins-plugins](/images/jenkins-plugins.png)

创建管理用户

![jenkins-admin](/images/jenkins-admin.png)

### 配置管理节点 (kubernetes)

#### kubernetes Cloud

通过 `kubernetes` 插件可以让 `jenkins` 在 `kubernetes` 集群以 `pod` 的方式运行工作节点，下面我们安装 `kubernetes` 插件, 安装完成后重启生效

![jenkins-plugins-install](/images/jenkins-plugins-install.png)

现在我们配置 Jenkins 使用 Kubernetes Pod 运行管理节点

依次点击 `系统管理` -> `节点管理` -> `Configure Clouds` -> `Add a new cloud` 添加 kubernetes 集群

点击 `Kubernetes Cloud details` 配置 `kubernetes` 集群

- Kubernetes 地址: `https://kubernetes.default.svc`
- Jenkins 地址: `http://jenkins.devops.svc.cluster.local:8080`
- Jenkins 通道: `jenkins.devops.svc.cluster.local:50000`

点击 `Save` 保存

![jenkins-k8s](/images/jenkins-k8s.png)

#### POD 模板

在配置 POD 模板之前，我们需要规划好需要此 POD 工作节点执行哪些操作？

1. 对项目进行编译 (以 `Java` 项目为例, 使用 `maven` 完成)
2. 将编译好的项目制作成 `Docker` 镜像并推送至 `harbor` 仓库 (需要调用 docker 命令)
3. 更新 `kubernetes` 资源配置清单，并应用至 `kubernetes` 集群中 (需要调用 kubectl 命令)

理清楚步骤后我们开始配置 `POD` 模板，

依次点击 `系统管理` -> `节点管理` -> `Configure Clouds` -> `POD Template` -> `添加 POD 模板`

- 名称: `maven-3.6`
- 命名空间: `devops` (默认就是这个；和 jenkins 部署所在 namespace 一致)
- 容器名: `maven`
- Docker 镜像: `maven:3.6-openjdk-11`

![jenkins-k8s-pod](/images/jenkins-k8s-pod.png)

**准备挂载 (mount) 资源**

给 maven POD 分配一个存储用于缓存从互联网下载的的资源，以便重复利用减少网络带宽占用节约等待时间

*maven-pvc.yaml*

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: maven-data
  namespace: devops
spec:
  storageClassName: managed-nfs-storage
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
```

创建 PVC

```bash
kubectl apply -f maven-pvc.yaml
```

配置 `docker push` 镜像时所需要的验证信息，并挂载至 `pod` 容器的 `/root/.docker` 目录

*docker 验证配置以 configmap 的形式存放在 集群中: configmap.yaml*

```yaml
apiVersion: v1
data:
  config.json: "{\n\t\"auths\": {\n\t\t\"harbor.wfugui.com\": {\n\t\t\t\"auth\": \"YWRtaW46SGFyYm9yMTIzNDU=\"\n\t\t}\n\t},\n\t\"HttpHeaders\":
    {\n\t\t\"User-Agent\": \"Docker-Client/19.03.15 (linux)\"\n\t}\n}"
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: docker-auth
  namespace: devops
```

创建 configmap

```bash
kubectl apply -f configmap.yaml
```

点击添加卷，添加如下卷

1. Persistent Volume Claim
    - 申请值: `maven-data`
    - 挂载路径: `/root/.m2`
2. Config Map Volume:
    - Config Map 名称: `docker-auth`
    - 挂载路径: `/root/.docker`
3. Host Path Volume: 
    - 主机路径: `/var/run/docker.sock`
    - 挂载路径: `/root/.docker`
4. Host Path Volume: 
    - 主机路径: `/usr/bin/docker`
    - 挂载路径: `/usr/bin/docker`
5. Host Path Volume: 
    - 主机路径: `/usr/bin/kubectl`
    - 挂载路径: `/usr/bin/kubectl`

配置 `Server Account` 为 `jenkins-ci`

![jenkins-k8s-pod-storage](/images/jenkins-k8s-pod-storage.png)

## 使用 Jenkins 实现 CI

### 准备测试项目

1. 登录 `http://git.host.com` , 创建一个 `test` 组织,
2. 克隆 `https://github.com/liwanggui/spring-boot-helloworld` 项目到 `test` 组织下
3. 创建一个名 `jenkins` 的用户，将其加入到 test 组织中

*项目文件结构*

```bash
├── Dockerfile          # 使用此 Dockerfile build docker 镜像
├── jenkins
│   ├── deliver.sh      # jenkins 流水线中会调用此脚本
│   ├── Jenkinsfile     # jenkins 声明式流水线配置
│   └── k8s             # 项目 kubernetes 资源配置清单
│       ├── deployment.yaml
│       ├── ingress.yaml
│       └── service.yaml
├── pom.xml
├── README.md
└── src
    ├── main
    │   └── java
    │       └── hello
    │           ├── Application.java
    │           └── HelloController.java
    └── test
        └── java
            └── hello
                ├── HelloControllerIT.java
                └── HelloControllerTest.java
```

### 配置流水线

在 `Jenkins` 管理界面，点击新建任务创建一个名称为 `spring-boot-helloworld` 类型为流水线(pipeline)的任务

配置 `spring-boot-helloworld` 任务配置界面点击流水线，选择 Pipenline script from SCM

- SCM: Git
    - Repository Url: `http://gogs.devops.svc.cluster.local:3000/test/spring-boot-helloworld`
    - Credentials: 配置 git 仓库验证信息，使用上面创建的 jenkins 用户
脚本本路径: `jenkins/Jenkinsfile`

保存

![jenkins-pipeline](/images/jenkins-pipeline.png)

### 构建项目和查看结果

> 点击开始构建，在构建过程可以点进去查看实时输出日志信息
