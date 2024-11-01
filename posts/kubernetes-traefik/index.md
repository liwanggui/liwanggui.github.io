# 部署 Traefik 2.4


## Traefik 简介

![traefik-architecture](/images/traefik-architecture.png)

Traefik 是一个开源的可以使服务发布变得轻松有趣的边缘路由器。它负责接收你系统的请求，然后使用合适的组件来对这些请求进行处理。

除了众多的功能之外，Traefik 的与众不同之处还在于它会自动发现适合你服务的配置。当 Traefik 在检查你的服务时，会找到服务的相关信息并找到合适的服务来满足对应的请求。

Traefik 兼容所有主流的集群技术，比如 Kubernetes，Docker，Docker Swarm，AWS，Mesos，Marathon，等等；并且可以同时处理多种方式。（甚至可以用于在裸机上运行的比较旧的软件。）

使用 Traefik，不需要维护或者同步一个独立的配置文件：因为一切都会自动配置，实时操作的（无需重新启动，不会中断连接）。使用 Traefik，你可以花更多的时间在系统的开发和新功能上面，而不是在配置和维护工作状态上面花费大量时间。

官方文档 -- [https://doc.traefik.io/traefik/](https://doc.traefik.io/traefik/)

## 核心概念

![architecture-overview](/images/architecture-overview.png)

`Traefik` 是一个边缘路由器，是你整个平台的大门，拦截并路由每个传入的请求：它知道所有的逻辑和规则，这些规则确定哪些服务处理哪些请求；传统的反向代理需要一个配置文件，其中包含路由到你服务的所有可能路由，而 `Traefik` 会实时检测服务并自动更新路由规则，可以自动服务发现。

首先，当启动 `Traefik` 时，需要定义 `entrypoints`（入口点），然后，根据连接到这些 `entrypoints` 的路由来分析传入的请求，来查看他们是否与一组规则相匹配，如果匹配，则路由可能会将请求通过一系列中间件转换过后再转发到你的服务上去。在了解 Traefik 之前有几个核心概念我们必须要了解：

- `Providers` 用来自动发现平台上的服务，可以是编排工具、容器引擎或者 key-value 存储等，比如 Docker、Kubernetes、File
- `Entrypoints` 监听传入的流量（端口等…），是网络入口点，它们定义了接收请求的端口（HTTP 或者 TCP）。
- `Routers` 分析请求（host, path, headers, SSL, …），负责将传入请求连接到可以处理这些请求的服务上去。
- `Services` 将请求转发给你的应用（load balancing, …），负责配置如何获取最终将处理传入请求的实际服务。
- `Middlewares` 中间件，用来修改请求或者根据请求来做出一些判断（authentication, rate limiting, headers, …），中间件被附件到路由上，是一种在请求发送到你的服务之前（或者在服务的响应发送到客户端之前）调整请求的一种方法。

## 安装 Traefik 2.4

由于 `Traefik 2.x` 版本和之前的 `1.x` 版本不兼容，我们这里选择功能更加强大的 `2.x` 版本来和大家进行讲解，我们这里使用的镜像是 `traefik:2.4`。

在 `Traefik` 中的配置可以使用两种不同的方式：

- 动态配置：完全动态的路由配置
- 静态配置：启动配置

`静态配置`中的元素（这些元素不会经常更改）连接到 `providers` 并定义 `Treafik` 将要监听的 `entrypoints`。

> 在 Traefik 中有三种方式定义静态配置：在配置文件中、在命令行参数中、通过环境变量传递

`动态配置`包含定义系统如何处理请求的所有配置内容，这些配置是可以改变的，而且是无缝热更新的，没有任何请求中断或连接损耗。

安装 `Traefik` 到 `Kubernetes` 集群中的资源清单文件可以到官方文档中找到，链接: https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/

将配置资源清单保存到本地，资源清单文件我这里准备好了（做了些修改，traefik 容器网络模式改为与共用宿主机网络，详细查看配置文件），通过以下命令应用。

> 请根据自己的需求修改资源配置清单

```bash
kubectl apply -f https://liwanggui.com/files/k8s/traefik2/crd.yaml  
kubectl apply -f https://liwanggui.com/files/k8s/traefik2/rbac.yaml
kubectl apply -f https://liwanggui.com/files/k8s/traefik2/traefik.yaml
kubectl apply -f https://liwanggui.com/files/k8s/traefik2/traefik-ui.yaml
```

其中 `traefik.yaml` 使用的是 `DaemonSet` 部署方式，如果你需要修改可以下载下来做相应的修改即可。我们这里是通过命令行参数来做的静态配置：

```
args:
  - --log.level=INFO
  - --accesslog
  - --api=true   # 开启 api/dashboard 会创建一个名为 api@internal 的特殊 service，在 dashboard 中可以直接使用这个 service 来访问
  - --api.insecure
  - --metrics.prometheus=true
  - --metrics.prometheus.addentrypointslabels
  - --metrics.prometheus.addserviceslabels
  - --entrypoints.web.address=:80 # 定义名为 web 的入口
  - --entryPoints.websecure.address=:443 # 定义名为 websecure 的入口
  - --entrypoints.tcpep.address=:8000 # 定义名为 tcpep 的入口
  - --entrypoints.web.forwardedheaders.insecure # 信任 web 入口 所有转发的 header 头信息，可以用于获取客户端真实 IP 地址
  - --entrypoints.websecure.forwardedheaders.insecure # 信任 websecure 入口 所有转发的 header 头信息，可以用于获取客户端真实 IP 地址
  - --providers.kubernetescrd
  - --providers.kubernetesingress
```

`traefik-ui.yaml` 中定义的是访问 `traefik WEB UI` 的资源配置清单，可以根据自己的实际情况修改。

```bash
$ kubectl get pods -n kube-system -l app=traefik
NAME            READY   STATUS    RESTARTS   AGE
traefik-7s6wk   1/1     Running   0          7m27s
traefik-bx6m8   1/1     Running   0          7m27s
```

部署完成后我们可以通过域名 `traefik.host.cn` 访问 `Traefik` 的 `Dashboard` 页面了

![traefik-dashboard](/images/traefik-dashboard.png)

> 资源参考 [https://www.qikqiak.com/post/traefik-2.1-101/](https://www.qikqiak.com/post/traefik-2.1-101/)
