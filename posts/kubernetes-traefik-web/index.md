# 使用 Traefik-2.4 暴露 Kubernetes 内部 Web 服务


## 部署测试 web 应用

使用 `Deployment` 部署 nginx， 启动两个 pod 实例， 资源配置清单 `nginx.yaml`  如下：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx
  name: nginx
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:stable-alpine
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx
  name: nginx
  namespace: default
spec:
  ports:
  - name: "http"
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
  type: ClusterIP
```

在集群中应用 `nginx.yaml`

```bash
kubectl apply -f nginx.yaml
```

## 配置 traefik IngressRoute

*ingress-route.yaml*

```yaml
apiVersion: traefik.containo.us/v1alpha1
# 使用 ingress route
kind: IngressRoute
metadata:
  name: nginx
  namespace: default
spec:
  # 指定使用的入口，由于是 http 流量，我们使用 web 入口（入口在 traefik 命令行配置参数自行配置）
  entryPoints:
    - web
  routes:
  # 指定匹配规则
  - match: Host(`www.host.com`)
    kind: Rule
    services:
    - name: nginx
      port: 80
```

在集群中应用 `ingress-route.yaml`

```bash
kubectl apply -f ingress-route.yaml
```

> 在内部使用 http 可以减少管理证书的麻烦及简化配置的步骤，我们只要在最外围的反代上配置成 https 即可。
> 如果需要使用 traefik 暴露 https 流量，可以下面步骤操作

1.使用 `cfssl` 命令自签 `www.host.com` 域名证书，参考 [使用 cfssl 自签证书](/posts/cfssl)
2.将自签证书存入 k8s 集群中，以 `secret` 资源存储

```bash
kubectl create secret tls host-com-tls --cert=host.pem --key=host-key.pem
```
> 要注意证书文件名称必须是 tls.crt 和 tls.key

3.配置 `IngressRoute` 的 `entryPoints` 为 `websecure`, 并启用 `tls` 配置

```yaml
apiVersion: traefik.containo.us/v1alpha1
# 使用 ingress route
kind: IngressRoute
metadata:
  name: nginx
  namespace: default
spec:
  # 指定使用的入口，由于是 http 流量，我们使用 web 入口（入口在 traefik 命令行配置参数自行配置）
  entryPoints:
    - websecure
  routes:
  # 指定匹配规则
  - match: Host(`www.host.com`)
    kind: Rule
    services:
    - name: nginx
      port: 80
  tls:
    secretName: host-com-tls
```

> 在配置 nginx 反向代理时后端 web 服务的端口此时就成了 `443` 了，协议为 `https`

## 配置负载均衡反向代理

我们把只要是 `www.host.com` 这个域名的流量（配置中使用通配符）统一反代到 traefik 的 web 入口

```bash
upstream k8s_services {
    server 10.7.50.17;
    server 10.7.149.184;
}

server {
        listen 80;
        server_name *.host.com;

        location / {
        proxy_pass http://k8s_services;
        include proxy.conf;
        }
}
```

## 查看及测试

打开 `traefik-dashboard` 页面，查看配置的规则是否生效，使用域名访问此 web 服务。
