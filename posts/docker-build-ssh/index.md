# docker - 创建 SSH 镜像


## CentOS

*CentOS SSH 镜像 Dockerfile*

```
FROM centos:centos7

LABEL maintainer="liwanggui"

RUN curl -o /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-reg.repo \
    && yum install -y openssh-server \
    && yum install -y inetutils-ping iproute net-tools \
    && yum clean all \
    && echo '123456' | passwd --stdin root \
    && ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key \
    && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key \
    && ssh-keygen -t dsa -f /etc/ssh/ssh_host_ed25519_key \
    && ssh-keygen -t dsa -f  /etc/ssh/ssh_host_ecdsa_key \
    && mkdir -m 0700 /root/.ssh

# 添加公钥，需要提前准备好 authorized_keys 文件
COPY authorized_keys /root/.ssh

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
```


## Ubuntu

*Ubuntu SSH 镜像 Dockerfile*

```
FROM ubuntu:20.04

LABEL maintainer="liwanggui"

RUN sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list \
    && sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list \
    && apt update \
    && DEBIAN_FRONTEND=noninteractive apt install -y openssh-server \
    && apt install -y inetutils-ping iproute2 net-tools vim \
    && apt clean \
    && mkdir /var/run/sshd \
    && sed -i -E 's/^(#)?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && echo "root:123456" | chpasswd \
    && mkdir -m 0700 /root/.ssh

COPY authorized_keys /root/.ssh

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
```
