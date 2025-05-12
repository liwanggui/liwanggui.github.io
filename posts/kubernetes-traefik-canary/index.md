# 使用 Traefik-2.4 进行灰度发布


## Traefik 灰度发布概述

`Traefik2.0` 的一个更强大的功能就是灰度发布，灰度发布我们有时候也会称为金丝雀发布（Canary），主要就是让一部分测试的服务也参与到线上去，经过测试观察看是否符号上线要求

![canary deployment](/images/traefik-canary-demo.jpg)

## 测试灰度发布

比如现在我们有两个名为 `appv1` 和 `appv2` 的服务，我们希望通过 `Traefik` 来控制我们的流量，将 `3⁄4` 的流量路由到 `appv1`，`1/4` 的流量路由到 `appv2` 去，这个时候就可以利用 `Traefik2.0` 中提供的带权重的轮询（WRR）来实现该功能，首先在 `Kubernetes` 集群中部署上面的两个服务。为了对比结果我们这里提供的两个服务一个是 `whoami`，一个是 `nginx`，方便测试。

appv1 服务的资源清单如下所示：（appv1.yaml）

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: appv1
spec:
  selector:
    matchLabels:
      app: appv1
  template:
    metadata:
      labels:
        use: test
        app: appv1
    spec:
      containers:
      - name: whoami
        image: traefik/whoami
        ports:
        - containerPort: 80
          name: portv1
---
apiVersion: v1
kind: Service
metadata:
  name: appv1
spec:
  selector:
    app: appv1
  ports:
  - name: http
    port: 80
    targetPort: portv1
```

appv2 服务的资源清单如下所示：（appv2.yaml）

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: appv2
spec:
  selector:
    matchLabels:
      app: appv2
  template:
    metadata:
      labels:
        use: test
        app: appv2
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
          name: portv2
---
apiVersion: v1
kind: Service
metadata:
  name: appv2
spec:
  selector:
    app: appv2
  ports:
  - name: http
    port: 80
    targetPort: portv2
```

直接创建上面两个服务：

```bash
kubectl apply -f appv1.yaml
kubectl apply -f appv2.yaml
```

在 `Traefik 2.1` 中新增了一个 `TraefikService` 的 `CRD` 资源，我们可以直接利用这个对象来配置 WRR，之前的版本需要通过 `File Provider`，比较麻烦，新建一个描述 WRR 的资源清单：(wrr.yaml)

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: app-wrr
spec:
  weighted:
    services:
      - name: appv1
        weight: 3  # 定义权重
        port: 80
        kind: Service  # 可选，默认就是 Service
      - name: appv2
        weight: 1
        port: 80
```

然后为我们的灰度发布的服务创建一个 `IngressRoute` 资源对象：(ingressroute.yaml)

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: wrringressroute
  namespace: default
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`wrr.wglee.cn`)
    kind: Rule
    services:
    - name: app-wrr
      kind: TraefikService
```

不过需要注意的是现在我们配置的 `Service` 不再是直接的 `Kubernetes` 对象了，而是上面我们定义的 `TraefikService` 对象，直接创建上面的两个资源对象，这个时候我们对域名 `wrr.wglee.cn` 做上解析，去浏览器中连续访问 4 次，我们可以观察到 `appv1` 这应用会收到 3 次请求，而 `appv2` 这个应用只收到 1 次请求，符合上面我们的 `3:1` 的权重配置。


