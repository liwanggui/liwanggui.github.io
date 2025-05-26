# 使用 Kubeadm 快速部署 Kubernetes 集群


## 主机环境

本示例中的 Kubernetes 集群部署将基于以下环境进行。

- OS: `Ubuntu 18.04.5`
- Kubernetes：`v1.18.1`
- Container Runtime:  `Docker CE 19.03.15`

## 环境说明

测试使用的 `kubernetes` 集群可由一个 `master` 主机及一个以上（建议至少两个）`node` 主机组成，这些主机可以是物理服务器，也可以运行于 `vmware`、`virtualbox` 或 `kvm` 等虚拟化平台上的虚拟机，甚至是公有云上的 `VPS` 主机。

本测试环境将由 `master1.host.com`、`node1.host.com`、`node2.host.com` 3个独立的主机组成，它们分别拥有 4 核心的 CPU 及 8G 的内存资源，操作系统环境均为最小化部署的 `Ubuntu Server 18.04.5 LTS`，启用了 `SSH` 服务，域名为 `host.com`。此外，各主机需要预设的系统环境如下：

- 借助于 `chronyd` 服务（程序包名称 `chrony`）设定各节点时间精确同步；
- 通过 `DNS` 完成各节点的主机名称解析；
- 各节点禁用所有的 `Swap` 设备；
- 各节点禁用默认配置的 `iptables` 防火墙服务；

> 注意：为了便于操作，后面将在各节点直接以系统管理员 `root` 用户进行操作。若用户使用了普通用户，建议将如下各命令以 `sudo` 方式运行。

## 网络规划

Kubernetes 网络分为三类:

- Pod 网络：`172.16.0.0/16`
- Service 网络: `192.168.0.0/16`
- Node 网络: `10.7.0.0/16`

> 注意: 请按照实际情况进行网络规划。

## 设定时钟同步

若节点可直接访问互联网，安装 chrony 程序包后，可直接启动 chronyd 系统服务，并设定其随系统引导而启动。随后，chronyd 服务即能够从默认的时间服务器同步时间。

```bash
apt install chrony
systemctl start chronyd.service  
```

不过，建议用户配置使用本地的的时间服务器，在节点数量众多时尤其如此。存在可用的本地时间服务器时，修改节点的 `/etc/chrony/chrony.conf` 配置文件，并将时间服务器指向相应的主机即可，配置格式如下： 

```
server CHRONY-SERVER-NAME-OR-IP iburst
```

## 主机名称解析（可选）

使用 `bind9` 提供 `dns` 服务, 本环境直接在主节点安装 `bind9`

```bash
apt install bind9
```

> 更新多详细配置参考 [Ubuntu Server 安装配置 bind9](/posts/ubuntu-bind/)

*host.com zone 配置文件示例*

```bash
;
; BIND data file for local loopback interface
;
$TTL    604800
@       IN      SOA     host.com. root.host.com. (
                         2              ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@           IN      NS      ns.host.com.
@           IN      A       10.7.79.148
ns          IN      A       10.7.79.148
master1     IN      A       10.7.79.148
node1       IN      A       10.7.50.17
node2       IN      A       10.7.149.184
apiserver   IN      A       10.7.79.148
```

> 由于本实验中使用的机器较小，使用 `hosts` 文件实现本地域名解析

## 禁用 Swap 设备

部署集群时，`kubeadm` 默认会预先检查当前主机是否禁用了 `Swap` 设备，并在未禁用时强制终止部署过程。因此，在主机内存资源充裕的条件下，需要禁用所有的 `Swap` 设备，否则，就需要在后文的 `kubeadm init` 及 `kubeadm join` 命令执行时额外使用相关的选项忽略检查错误。

关闭 Swap 设备，需要分两步完成。首先是关闭当前已启用的所有 Swap 设备： 

```bash
swapoff -a
```

而后编辑 `/etc/fstab` 配置文件，注释用于挂载 `Swap` 设备的所有行。

另外，若确需在节点上使用 `Swap` 设备，也可选择让 `kubeam` 忽略 `Swap` 设备的相关设定。我们编辑 `kubelet` 的配置文件 `/etc/default/kubelet`，设置其忽略 `Swap` 启用的状态错误即可，文件内容如下： 

```
KUBELET_EXTRA_ARGS="--fail-swap-on=false"
```

## 禁用默认的防火墙服务

Ubuntu 和 Debian 等 Linux 发行版默认使用 ufw（Uncomplicated FireWall）作为前端来简化 iptables 的使用，处于启用状态时，它默认会生成一些规则以加强系统安全。出于降低配置复杂度之目的，本文选择直接将其禁用。

```bash
ufw disable 
ufw status
```

## 安装程序包

> 提示：以下操作需要在本示例中的所有三台主机上分别进行

### 安装 docker 

此时我们需要安装指定版本的 docker，docker 安装请参考 [Docker 快速安装](/posts/docker-install/)

`kubelet` 需要让 `docker` 容器引擎使用 `systemd` 作为 `CGroup` 的驱动，其默认值为 `cgroupfs，因而，我们还需要编辑` docker 的配置文件 `/etc/docker/daemon.json`，添加如下内容 

```json
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn", "http://hub-mirror.c.163.com"], # 镜像加速器

  "insecure-registries":["harbor.host.com"],  # 第三方仓库或自建仓库地址，可以配置为 http

  "data-root": "/data/docker",  # docker 数据存储目录
  "exec-opts": ["native.cgroupdriver=systemd"], # 额外参数,部署 k8s 时需要指定此选项
  "log-driver": "json-file",
  "log-opts": { "max-size": "100m"},
  "live-restore": true
}
```

配置完成后即可启动 `docker` 服务，并将其设置为随系统启动而自动引导：

```bash
systemctl daemon-reload
systemctl start docker.service
systemctl enable docker.service
```

### 安装配置 kubelet 和 kubeadm

首先，在各主机上生成 `kubelet` 和 `kubeadm` 等相关程序包的仓库，这里以阿里云的镜像服务为例：

```bash
apt update && apt install -y apt-transport-https
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 

cat  >/etc/apt/sources.list.d/kubernetes.list<<EOF
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

apt update
```

接着，在各主机安装 kubelet、kubeadm 和 kubectl 程序包，并将其设置为随系统启动而自动引导：

```bash
apt install -y kubelet=1.18.1-00 kubeadm=1.18.1-00 kubectl=1.18.1-00
systemctl enable kubelet
```

> 安装完成后，要确保 kubeadm 等程序文件的版本，这将也是后面初始化 Kubernetes 集群时需要明确指定的版本号

## 初始化第一个主节点

该步骤开始尝试构建 `Kubernetes` 集群的 `master` 节点，配置完成后，各 `worker` 节点直接加入到集群中的即可。需要特别说明的是，由 `kubeadm` 部署的 `Kubernetes` 集群上，集群核心组件 `kube-apiserver`、`kube-controller-manager`、`kube-scheduler` 和 `etcd` 等均会以`静态 Pod` 的形式运行，它们所依赖的镜像文件默认来自于 `gcr.io` 这一 `Registry` 服务之上。但我们无法直接访问该服务，常用的解决办法有如下两种，本示例将选择使用更易于使用的后一种方式。

使用能够到达该服务的代理服务；使用国内的镜像服务器上的服务，例如 `gcr.azk8s.cn/google_containers` 和 `registry.aliyuncs.com/google_containers` 等。

### 初始化 master 节点

在 `master1.host.com` 上完成如下操作

在运行初始化命令之前先运行如下命令单独获取相关的镜像文件，而后再运行后面的 `kubeadm init` 命令，以便于观察到镜像文件的下载过程。

```bash
# 查看镜像列表
kubeadm config images list --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.18.1

# 获取镜像文件至本地
kubeadm config images pull --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.18.1
``` 

而后即可进行 `master` 节点初始化。`kubeadm init` 命令支持两种初始化方式，一是通过命令行选项传递关键的部署设定，另一个是基于 yaml 格式的专用配置文件，后一种允许用户自定义各个部署参数。下面分别给出了两种实现方式的配置步骤，建议采用第二种方式进行。

**初始化方式一**

运行如下命令完成 `master` 节点的初始化：

```bash
kubeadm init \
--image-repository registry.aliyuncs.com/google_containers \
--control-plane-endpoint apiserver.host.com \
--kubernetes-version v1.18.1 \
--apiserver-advertise-address 10.7.79.148 \
--service-cidr 192.168.0.0/16 \
--pod-network-cidr 172.16.0.0/16 \
--token-ttl 0 \
--upload-certs
```

命令中的各选项简单说明如下： 

- `--image-repository`： 指定要使用的镜像仓库，默认为 `gcr.io`；
- `--kubernetes-version`：`kubernetes` 程序组件的版本号，它必须要与安装的 `kubelet` 程序包的版本号相同；
- `--control-plane-endpoint`：控制平面的固定访问端点，可以是 IP 地址或 DNS 名称，会被用于集群管理员及集群组件的 `kubeconfig` 配置文件的 `API Server` 的访问地址；单控制平面部署时可以不使用该选项；
- `--pod-network-cidr`：`Pod` 网络的地址范围，其值为 `CIDR` 格式的网络地址，通常，`Flannel` 网络插件的默认为 `10.244.0.0/16`, `Calico` 插件的默认值为 `192.168.0.0/16`；
- `--service-cidr`：`Service` 的网络地址范围，其值为 `CIDR` 格式的网络地址，默认为 `10.96.0.0/12`；通常，仅 `Flannel`一类的网络插件需要手动指定该地址；
- `--apiserver-advertise-address`：`apiserver` 通告给其他组件的IP地址，一般应该为 `Master` 节点的用于集群内部通信的IP地址，`0.0.0.0` 表示节点上所有可用地址；
- `--upload-certs`: 将控制平面证书上传到 kubeadm-certs secret。
- `--token-ttl`：共享令牌（token）的过期时长，默认为 24小时，0 表示永不过期；为防止不安全存储等原因导致的令牌泄露危及集群安全，建议为其设定过期时长。未设定该选项时，在 token 过期后，若期望再向集群中加入其它节点，可以使用如下命令重新创建 token，并生成节点加入命令。 

```bash
kubeadm token create --print-join-command
```

> 需要注意的是，若各节点未禁用Swap设备，还需要附加选项 “--ignore-preflight-errors=Swap”，从而让 kubeadm 忽略该错误设定。   


**初始化方式二**

`kubeadm` 也可通过配置文件加载配置，以定制更丰富的部署选项。以下是个符合前述命令设定方式的使用示例，不过，它明确定义了 `kubeProxy` 的模式为 `ipvs`，并支持通过修改 `imageRepository` 的值修改获取系统镜像时使用的镜像仓库。

> 默认配置可以通过 `kubeadm config print init-defaults` 获取

```yaml
---
apiVersion: kubeadm.k8s.io/v1beta2
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  # 这里的地址即为初始化的控制平面第一个节点的IP地址；
  advertiseAddress: 192.168.31.11
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  # 第一个控制平面节点的主机名称；
  name: master1.host.com
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta2
# 控制平面的接入端点，我们这里选择适配到 apiserver.host.com 这一域名上
controlPlaneEndpoint: "apiserver.host.com:6443"
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    # 配置 etcd 数据存储路径
    dataDir: /data/etcd
# 配置镜像拉取站点
imageRepository: registry.aliyuncs.com/google_containers
kind: ClusterConfiguration
# 版本号要与部署的目标版本保持一致
kubernetesVersion: v1.18.1
networking:
  # 要使用的集群域名，默认为 cluster.local
  dnsDomain: cluster.local
  # Pod 的网络地址段
  podSubnet: 172.16.0.0/16
  # Service 的网络地址段
  serviceSubnet: 192.168.0.0/16
scheduler: {}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
# 用于配置 kube-proxy 上为 Service 指定的代理模式，默认为 iptables
mode: "ipvs"
ipvs:
  scheduler: "nq"
```

将上面的内容保存于配置文件中，例如 `kubeadm-config.yaml`，而后执行如下命令即能实现类似前一种初始化方式中的集群初始配置，但这里将 `Service` 的代理模式设定为了 `ipvs`。

*初始化命令*

```bash
kubeadm init --config kubeadm-config.yaml
```

> `kubeadm init` 命令完整参考指南请移步官方文档，地址为 https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/

### 初始化完成后的操作步骤

> 注意：对于 Kubernetes 系统的新用户来说，无论使用上述哪种方法，命令运行结束后，请记录最后的 kubeadm join 命令输出的最后提示的操作步骤。下面的内容是需要用户记录的一个命令输出示例，它提示了后续需要的操作步骤：

```W0309 06:48:46.484983   48909 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
[init] Using Kubernetes version: v1.18.1
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [master1.host.com kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local apiserver.host.com] and IPs [10.10.0.1 192.168.31.11]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [master1.host.com localhost] and IPs [192.168.31.11 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [master1.host.com localhost] and IPs [192.168.31.11 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
W0309 06:48:52.172442   48909 manifests.go:225] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
[control-plane] Creating static Pod manifest for "kube-scheduler"
W0309 06:48:52.173496   48909 manifests.go:225] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 26.002622 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.18" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node master1.host.com as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node master1.host.com as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: x3oo6y.ytmywnftdx6khuh5
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

# 提示集群初始化成功
Your Kubernetes control-plane has initialized successfully!

# 为了完成初始化操作，管理员需要额外手动完成几个必要的步骤
To start using your cluster, you need to run the following as a regular user:

# 第1个步骤提示， Kubernetes 集群管理员认证到 Kubernetes 集群时使用的 kubeconfig 配置文件
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 我们也可以不做上述设定，而使用环境变量 KUBECONFIG 为 kubectl 等指定默认使用的 kubeconfig
# export KUBECONFIG=/etc/kubernetes/admin.conf

# 第2个步骤提示，为 Kubernetes 集群部署一个网络插件，具体选用的插件则取决于管理员；
You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

# 第3个步骤提示，向集群添加额外的控制平面节点。
You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

# 在部署好 kubeadm 等程序包的其他控制平面节点上以 root 用户的身份运行类似如下命令，
# 命令中的 hash 信息对于不同的部署环境来说会各不相同；该步骤只能在其它控制平面节点上执行；
  kubeadm join apiserver.host.com:6443 --token x3oo6y.ytmywnftdx6khuh5 \
    --discovery-token-ca-cert-hash sha256:7708b5166572b6f33094b27d3c457d080213ec3bd701161d4d648367c53f1013 \
    --control-plane

# 第4个步骤提示，向集群添加工作节点
Then you can join any number of worker nodes by running the following on each as root:
# 在部署好kubeadm等程序包的各工作节点上以root用户运行类似如下命令
kubeadm join apiserver.host.com:6443 --token x3oo6y.ytmywnftdx6khuh5 \
    --discovery-token-ca-cert-hash sha256:7708b5166572b6f33094b27d3c457d080213ec3bd701161d4d648367c53f1013
```

#### 配置 kubectl 

`kubectl` 是 `kube-apiserver` 的命令行客户端程序，实现了除系统部署之外的几乎全部的管理操作，是 `kubernetes` 管理员使用最多的命令之一。`kubectl` 需经由 `API server` 认证及授权后方能执行相应的管理操作，`kubeadm` 部署的集群为其生成了一个具有管理员权限的认证配置文件 `/etc/kubernetes/admin.conf`，它可由 `kubectl` 通过默认的 `$HOME/.kube/config` 的路径进行加载。当然，用户也可在 `kubectl` 命令上使用 `--kubeconfig` 选项指定一个别的位置。

下面复制认证为 Kubernetes 系统管理员的配置文件至目标用户（例如当前用户root）的家目录下：

```bash
mkdir ~/.kube
cp /etc/kubernetes/admin.conf  ~/.kube/config
```

*配置 kubectl 命令补全*

```bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
source ~/.bashrc
```

#### 部署网络插件

`Kubernetes` 系统上 `Pod` 网络的实现依赖于第三方插件进行，这类插件有近数十种之多，较为著名的有 `flannel`、`calico`、`canal` 和 `kube-router` 等，简单易用的实现是为 `CoreOS` 提供的 `flannel` 项目。下面的命令用于在线部署 `flannel` 至 `Kubernetes` 系统之上：

*下载 flannel 资源配置文件*

```bash
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

由于我们自定义的 `pod` 网络地址段和 `flannel` 配置文件中指定不一致，需要修改一致；同时我们将 `flannel` 网络模式修改为 `host-gw`

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "172.16.0.0/16",
      "Backend": {
        "Type": "host-gw"
      }
    }
```

- `Network` 默认为：`10.244.0.0/16`    
- `Type` 默认为：`vxlan`

> 完整 flannel 配置： https://liwanggui.com/files/k8s/kube-flannel.yml

部署 `flannel` 网络插件

```bash
kubectl apply -f kube-flannel.yml
```

而后使用如下命令确认其输出结果中 Pod 的状态为 “Running”，类似如下所示

```bash
kubectl get pods -n kube-system -l app=flannel
NAME                    READY   STATUS    RESTARTS   AGE
kube-flannel-ds-bc88j   1/1     Running   0          51s
```

#### 验证 master 节点已经就绪

```bash
kubectl get nodes
NAME               STATUS   ROLES    AGE   VERSION
master1.host.com   Ready    master   23m   v1.18.1
```

## 向集群添加额外的控制平面节点

在添加额外主节点之前我们需要将集群证书上传到集群中以便向其它主节点共享证书并生成证书密钥，使用此密钥可以解密由 init 上载的证书。 使用如下命令命令完成。

```bash
kubeadm init phase upload-certs --upload-certs
I0309 07:16:31.594295   62834 version.go:252] remote version is much newer: v1.20.4; falling back to: stable-1.18
W0309 07:16:35.449971   62834 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
[upload-certs] Storing the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
[upload-certs] Using certificate key:
7c3c34ac69d980bdaf28eb42e38186c71245cef7c5926d0fb252b7200aad05bf
```

> 也可以直接拷贝 `/etc/kubernetes/pki` 至另一台主节点上的 `/etc/kubernetes` 目录下

集群添加额外的主节点，使用如下命令完成。

```bash
kubeadm join apiserver.host.com:6443 --token x3oo6y.ytmywnftdx6khuh5 \
    --discovery-token-ca-cert-hash sha256:7708b5166572b6f33094b27d3c457d080213ec3bd701161d4d648367c53f1013 \
    --control-plane --certificate-key 7c3c34ac69d980bdaf28eb42e38186c71245cef7c5926d0fb252b7200aad05bf
```

> 本次实验由于资源有限只部署一台主节点，实际生产环境中建议部署多台，避免单点故障。

## 添加节点到集群中

下面的两个步骤，需要分别在 `node1.host.com` 和 `node2.host.com` 上完成。

1、若未禁用 `Swap` 设备，编辑 `kubelet` 的配置文件 `/etc/default/kubelet`，设置其忽略 `Swap` 启用的状态错误，内容如下：  

```
KUBELET_EXTRA_ARGS="--fail-swap-on=false"
```

2、将节点加入 `master` 的集群中，要使用主节点初始化过程中记录的 `kubeadm join` 命令，并且在未禁用 `Swap` 设备的情况下，额外附加 “`--ignore-preflight-errors=Swap`” 选项；

```bash
kubeadm join apiserver.host.com:6443 --token x3oo6y.ytmywnftdx6khuh5 \
    --discovery-token-ca-cert-hash sha256:7708b5166572b6f33094b27d3c457d080213ec3bd701161d4d648367c53f1013
```

### 验证节点添加结果

在每个节点添加完成后，即可通过 kubectl 验正添加结果。下面的命令及其输出是在 node1 和 node2 均添加完成后运行的，其输出结果表明两个 Node 已经准备就绪。

```bash
kubectl get nodes
NAME               STATUS   ROLES    AGE   VERSION
master1.host.com   Ready    master   41m   v1.18.1
node1.host.com     Ready    <none>   51s   v1.18.1
node2.host.com     Ready    <none>   43s   v1.18.1
```

## 测试应用编排及服务访问

到此为止，一个 master，并附带有二个 node 的 kubernetes 集群基础设施已经部署完成，用户随后即可测试其核心功能。例如，下面的命令可将 demoapp 以 Pod 的形式编排运行于集群之上，并通过在集群外部进行访问：

```bash
kubectl create deployment demoapp --image=ikubernetes/demoapp:v1.0
kubectl scale deployment/demoapp --replicas=2
kubectl create service nodeport demoapp --tcp=80:80
```

而后，使用如下命令了解 Service 对象 demoapp 使用的 NodePort，以便于在集群外部进行访问

```
kubectl get svc -l app=demoapp
NAME      TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
demoapp   NodePort   10.10.149.76   <none>        80:32002/TCP   10s
```

> `demoapp` 是一个 `web` 应用，因此，用户可以于集群外部通过 `http://NodeIP:32002` 这个 URL 访问 `demoapp` 上的应用，例如于集群外通过浏览器访问 `http://10.7.50.17:32002`。

