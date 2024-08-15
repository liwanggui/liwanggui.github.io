# 使用 Traefik-2.4 暴露 Kubernetes 内部 TCP 协议


## 简单 TCP 服务

首先部署一个普通的 mongo 服务，资源清单文件如下所示：（mongo.yaml）

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-traefik
  labels:
    app: mongo-traefik
spec:
  selector:
    matchLabels:
      app: mongo-traefik
  template:
    metadata:
      labels:
        app: mongo-traefik
    spec:
      containers:
      - name: mongo
        image: mongo:4.0
        ports:
        - containerPort: 27017
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-traefik
spec:
  selector:
    app: mongo-traefik
  ports:
  - port: 27017
```

*直接创建 mongo 应用：*

```bash
kubectl apply -f mongo.yaml
```

## ingressroute-tcp

创建成功后就可以来为 mongo 服务配置一个路由了。由于 Traefik 中使用 TCP 路由配置需要 SNI，而 SNI 又是依赖 TLS 的，所以我们需要配置证书才行，如果没有证书的话，我们可以使用通配符 * 进行配置，我们这里创建一个 IngressRouteTCP 类型的 CRD 对象（前面我们就已经安装了对应的 CRD 资源）：(mongo-ingressroute-tcp.yaml)

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: mongo-traefik-tcp
spec:
  entryPoints:
    - tcpep
  routes:
  - match: HostSNI(`*`)
    services:
    - name: mongo-traefik
      port: 27017
```

要注意的是这里的 entryPoints 部分，是根据我们启动的 Traefik 的静态配置中的 entryPoints 来决定的，我们当然可以使用前面我们定义得 80 和 443 这两个入口点，但是也可以可以自己添加一个用于 mongo 服务的专门入口点, 这里我们使用 tcpep 这个入口

关于 entryPoints 入口点的更多信息，可以查看文档 [entrypoints](https://www.qikqiak.com/traefik-book/routing/entrypoints/) 了解更多信息。 然后更新 Traefik 后我们就可以直接创建上面的资源对象：

```bash
kubectl apply -f mongo-ingressroute-tcp.yaml
```

创建完成后，同样我们可以去 Traefik 的 Dashboard 页面上查看是否生效, 然后我们配置一个域名 mongo.local 解析到 Traefik 所在的节点，然后通过 8000 端口来连接 mongo 服务：

```bash
mongo --host mongo.local --port 8000
mongo(75243,0x1075295c0) malloc: *** malloc_zone_unregister() failed for 0x7fffa56f4000
MongoDB shell version: 2.6.1
connecting to: mongo.local:8000/test
> show dbs
admin   0.000GB
config  0.000GB
local   0.000GB
```
