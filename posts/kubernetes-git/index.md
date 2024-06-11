# 使用 Gogs 服务实现代码仓库管理


## 部署 Gogs

互联网常用的 git 代码仓库管理软件有 `gitlab`, `gogs`, `gitea`(gogs 的克隆版) 等，本例为了简单点使用 `gogs` 作为 `git` 仓库管理工作部署在 `kubernetes` 集群中

> 提示: `gitea` 部署过和 `gogs` 基本一致

准备 `gogs` 资源部署清单，由于 `git` 代码仓库需要使用持久化存储，因此我们需要为 `gogs` 创建一个 `pvc`, `gitops` 资源统一放在 `devops` 名称空间下。

```bash
kubectl create namespace devops
```

*pvc.yaml*

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gogs-data
  namespace: devops
spec:
  storageClassName: managed-nfs-storage
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
```

*deployment.yaml*

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gogs
  namespace: devops
spec:
  selector:
    matchLabels:
      app: gogs
  template:
    metadata:
      labels:
        app: gogs
    spec:
      terminationGracePeriodSeconds: 10
     # nodeSelector:
     #   workrole: cicd
      securityContext:
        runAsUser: 0
      containers:
      - name: gogs
        image: gogs/gogs:0.12.3
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
          name: web
          protocol: TCP
        - containerPort: 22
          name: ssh
          protocol: TCP
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: gogs-data
---

apiVersion: v1
kind: Service
metadata:
  labels:
    app: gogs
  name: gogs
  namespace: devops
spec:
  ports:
  - name: "web"
    port: 3000
    protocol: TCP
    targetPort: 3000
  - name: "ssh"
    port: 22
    protocol: TCP
    targetPort: 22
  selector:
    app: gogs
  type: ClusterIP
```  

*ingress-route.yaml*

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: gogs
  namespace: devops
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`git.host.com`)
    kind: Rule
    services:
    - name: gogs
      port: 3000
```

*应用资源清单* 

```bash
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f ingress-route.yaml
```

## 配置 gogs 

浏览器打开 http://git.host.com 进入 gogs 配置页面

![gogs-config](/images/gogs-config1.png)


![gogs-config](/images/gogs-config2.png)

*点击 “立即安装” ，安装完成后，进入管理界面*

![gogs-login](/images/gogs-login.png)

## 访问 git 仓库

在集群内可以使用 `gogs` 的集群内部名称来进行访问: `http://gogs.devops.svc.cluster.local:3000`

在集群外直接使用域名访问即可

如需要使用 `ssh` 连接 `git` 仓库需要配置 `traefik` 的 `ingressroutetcp` 规则

