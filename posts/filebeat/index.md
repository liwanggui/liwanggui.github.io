# 使用 Filebeat 收集 nginx 日志


## 安装配置 filebeat

### 安装

```bash
root@ubuntu:/opt# wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.12.0-amd64.deb
root@ubuntu:/opt# dpkg -i filebeat-7.12.0-amd64.deb
```

### 配置

*filebeat.yml*

```bash
root@ubuntu:/etc/filebeat# cat filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /usr/local/nginx/logs/access.log
  json.keys_under_root: true
  json.overwrite_keys: true

#filebeat.config.modules:
#  path: ${path.config}/modules.d/*.yml
#  reload.enabled: true

setup.template.settings:
  index.number_of_shards: 3  # 配置索引分片数
#
#setup.kibana:
#
output.elasticsearch:
  hosts: ["192.168.16.102:9200","192.168.16.103:9200","192.168.16.104:9200"]
  # 配置索引名为 nginx-日期，用于区分应用
  index: "nginx-%{+YYYY-MM}"

setup.template.enable: true
setup.template.name: "nginx"
setup.template.pattern: "nginx-*"

setup.ilm.enabled: false
#setup.ilm.rollover_alias: "nginx"
#setup.ilm.pattern: "{now/d}-000001"

#
#processors:
#  - add_host_metadata:
#      when.not.contains.tags: forwarded
#  - add_cloud_metadata: ~
#  - add_docker_metadata: ~
#  - add_kubernetes_metadata: ~
```

## 配置 nginx 日志格式

```bash
root@nginx-1:~# cat /etc/nginx/log-json
    log_format  json  '{"remote_addr":"$remote_addr", "time_local": "$time_local", "domain":"$host", "request":"$request", '
                      '"status":"$status", "body_bytes_sent":"$body_bytes_sent", "method":"$request_method", '
                      '"http_referer":"$http_referer", "request_time":"$request_time", '
                      '"http_user_agent":"$http_user_agent", "http_x_forwarded_for":"$http_x_forwarded_for", '
                      '"upstream_addr":"$upstream_addr", "upstream_response_time":"$upstream_response_time"}';
# 在 nginx 配置文件中引入，并指定 access_log 使用 json 格式记录日志
root@nginx-1:~# vim /etc/nginx/nginx.conf
    include /etc/nginx/log-json;
    access_log /var/log/nginx/access.log json;
```
