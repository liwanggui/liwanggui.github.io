# 使用 metrics-server 采集 Kubernetes 集群性能指标


## 部署 Metrics Server

在 `kubernetes` 中 `HPA` 自动伸缩指标依据，`kubectl top` 命令的资源使用率，可以通过 `metrics-server` 来获取。 dashboard 也会引用 `metrics-server` 展示资源负载情况图表。但是官方明确表示，该指标不应该用于监控指标采集。

官方主页: https://github.com/kubernetes-sigs/metrics-server

在大部分情况下，使用 deployment 部署一个副本即可，最多支持5000个 node，每个 node 消耗 3m CPU 和 3M 内存

可以从官方主页获取资源配置清单文件，也可以直接使用下面的配置文件。

`metrics-server` 配置参数

```
- args:
  - --cert-dir=/tmp
  - --secure-port=4443
  - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
  - --kubelet-use-node-status-port
  - --kubelet-insecure-tls
```

部署 `metrics-server` 

```bash
kubectl apply -f metrics-server.yaml
```

> 由于国内环境导致无法下载 `metrics-server` 镜像，在网上也没有找到可用的代理的服务器。请自行解决此问题。

### Dashboard 页面效果展示

`metrics-server` 安装完成后可以在 `dashboard` 页面中看到效果

{{< figure src="/images/metrics-server.png" title="dashboard metrics" >}}
