# nginx - 常用指令语法


## 域名重定向

当用户访问 `http://liwanggui.com` 时 url 重定向至 `https://liwanggui.com`， 实现 http -> https 重定向，实现方式有两种： 

1. 通过 `rewrite` 模块的 `permanent` 参数实现永久重定向的 `http` 状态 `301`
2. 通过 `return` 指令实现 `（推荐）`

*rewrite 实现*

```bash
server {
    listen 80;
    server_name liwanggui.com;
    access_log off;
    rewrite ^/(.*)$ https://$host/$1 permanent;
    # 匹配以斜杠开头之后的所有字符 $1 表示小括号内匹配的字符  permanent 表示永久301跳转
}
```

*return 实现: 推荐做法*

```bash
server {
    listen 80;
    server_name liwanggui.com;
    access_log off;
    return 301 https://$host$request_uri;
}
```

- `$host`: 表示 HTTP 请求头中的 Host 值
- `$request_uri`: 表示 HTTP 请求 uri

## 多域名跳转应用实例

使用 `nginx` 做反向代理，当用户访问 `www.liwanggui.com` 时就代理到 `192.168.1.100:8080` 的 `web` 目录下，
当用户访问 `http://www.liwanggui.com/admin` 时就代理到 `192.168.1.100:8080` 的 `admin` 目录下，
当用户访问 `wap.liwanggui.com` 时就代理到 `192.168.1.100:8080` 的 `wap` 目录下

```bash
server_name www.liwanggui.com;
location / {
    proxy_pass http://192.168.1.100:8080/web/;
}

location /admin {
    proxy_pass http://192.168.1.100:8080/admin;
}

server_name wap.liwanggui.com;
location / {
    proxy_pass http://192.168.1.100:8080/wap/;
}
```

> 注意：在 `proxy_pass` 配置两个代理目录 `web` 和 `wap` 后面必须加一个斜杠，否则 `nginx` 会报错，仔细看上面代理配置中两种写法的区别就明白了

## nginx 常用指令

`nginx` 的 URL 重写模块是用得比较多的模块之一，常用的 URL 重写模块命令有 `if` 、`rewrite`、 `set`、 `break`

### if 命令

- 语法： `if (condition) {....}`
- 默认值： `none`
- 使用字段: `server` 、`location`

默认情况下，`if` 命令默认值为空，可在 nginx 配置文件的 `server`、`location` 部分使用，另外，`if` 命令可以在在判断语句中指定正则或匹配条件等，相关匹配条件如下：

> `if` 与小括号之间有一个空格

**正则表达式匹配**

- `~`   表示区分大小写匹配
- `~*`  表示不区分大小写匹配
- `!~`  表示区分大小写`不匹配`，
- `!~*` 表示不区分大小写`不匹配`

**文件及目录匹配**

- `-f` 和 `!-f` 用来判断是否存在文件
- `-d` 和 `!-d` 用来判断是否存在目录
- `-e` 和 `!-e` 用来判断是否存在文件和目录
- `-x` 和 `!-x` 用来判断文件是否可执行

`nginx` 配置文件中有很多内置变量，这些变量经常和if命令一起使用。常见的内置变量有如下几种:

- `$args`, 此变量与请求行中的参数相等
- `$document_root`， 此变量等同于当前请求的 root 命令指定的值
- `$uri`, 此变量等同于当前 `request` 中的 `uri`
- `$document_uri`， 此变量与 `$uri` 含义一样
- `$host`， 此变量与请求头部中的 "Host" 行指定的值一致

- `$limit_rate`, 此变量用来设置限制连接的速率
- `$request_method`, 此变量等同于 `request` 的 `method`，通常是'GET','POST'
- `$remote_addr`, 此变量表示客户端的IP地址
- `$remote_port`, 此变量表示客户端端口
- `$remote_user`, 此变量等同于用户名，由 `ngx_http_auth_basic_module` 认证
- `$request_filename`, 此变量表示当前请求的文件的路径名，由 root 或 alias 与 URI request 组合而成
- `$request_uri`, 此变量表示含有参数的完整的初始 URI
- `$query_string`, 此变量与$args含义一致
- `$server_name`, 此变量表示请求到达的服务器名
- `$server_port`, 此变量表示请示到达的服务器端口

**例：uri为：http://localhost:88/test1/test2/test.php**

各变量值如下：

```
$host： localhost
$server_port：  88
$request_uri：  http://localhost:88/test1/test2/test.php
$document_uri： /test1/test2/test.php
$document_root：    /var/www/html
$request_filename： /var/www/html/test1/test2/test.php
```

配置实例

```
server {
    listen  80;
    server_name www.liwanggui.com;
    access_log  logs/host.access.log main;
    index index.html index.htm;

    root /var/www/html;

    location ~*\.(gif|jpg|jpeg|png|bmp|swf|htm|html|css|js)$ {
        root /usr/local/nginx/www/img;
        if (!-f $request_filename){
            root /var/www/html/img;
        }
        if (!-f $request_filename){
            root /apps/images;
        }
    }

    location ~*\.(jsp)${
        root /webdata/webapp/www/ROOT;
        if (!-f $request_filename){
            root /usr/local/nginx/www/jsp;
        }
        proxy_pass http://127.0.0.1:8888;
    }
}
```

这段代码主要完成对 `www.liwanggui.com` 这个域名的资源访问配置， `www.liwanggui.com` 这个域名的根目录为 `/var/www/html`, 
而静态资源分别位于 `/usr/local/nginx/www/img`, `/var/www/html/img`, `/apps/images` 三个目录下，
请求静态资源的方式依次在三个目录中找，如果第一个目录找不到，就找第二目录，以此类推，如果都找不到，将提示404错误；

动态资源分别位于 `/webdata/webapp/www/ROOT`,`/usr/local/nginx/www/jsp`, 
两个目录下，如果客户端请求的的资源是以 `.jsp` 结尾的，那么将依次在这两个动态程序目录下查找资源。
而于没有在这两个目录中定义的资源，将全部从根目录 `/var/www/html` 进行查找。

### rewrite 命令

`nginx` 通过 `ngx_http_rewrite_module` 模块支持URL重写和if条件判断，但要使用 `rewrite` 功能，需要 `pcre` 支持，应在编译 `nginx` 时指定 `pcre` 源码目录. `rewrite` 的使用语法如下：

- 语法： `rewrite regex flag`
- 默认值： `none`
- 使用字段： `server` `location` `if`

在默认情况下，`rewrite` 命令默认值为空，可以 `nginx` 配置文件的 `server`,`location`,`if` 部分使用，`rewrite` 命令的最后一项参数为 `flag` 标记,其支持的 `flag` 标记主要有以下几种：

- `last`, 相当于 `apache` 里的 `L` 标记，表示完成 `rewrite` 之后搜索相应的 `uri` 或 `location`
- `break`, 表示终止匹配，不再匹配后面的规则
- `redirect`, 将返回 `302` 临时重定向，在浏览器地址会显示跳转后的 `URL` 地址。
- `permanent`, 将返回 `301` 永久重定向，在浏览器地址会显示跳转后的 `URL` 地址。

> last 一般写在 server 和 if 中，而 break 一般使用在 location 中
> last 不终止重写后的 url 匹配，即新的 url 会再从 server 走一遍匹配流程，而 break 终止重写后的匹配
> break 和 last 都能组织继续执行后面的 rewrite 指令

其中 last 和 break 用来实现 URL 重写，浏览器地址不变。下面是一个示例配置：

```bash
location ~ ^/best/ {
    rewrite ^/best/(.*)$ /best/$1 break;
    proxy_pass http://www.liwanggui.com;
}
```

> 这个例子使用了 break 标记，可实现将请求为 http://www.lwg.com/best/webinfo.html 的页面重定向到 http://www.liwanggui.com/best/webinfo.html 页面而不引起浏览器地址栏中 URL 的变化。
> 这个功能在新旧网站交替的时候非常有用（最好实践下，感觉有问题）

### set 命令

通过 `set` 命令可以设置一个变量并为其赋值，其值可以是文本、变量或他们的组合。也可以使用set定义一个新的变量，但是不能使用 set 设置 $http_xxx 头部变量

set 的使用方法如下：

- 语法： `set variable value`
- 默认值： `none`
- 使用字段： `server` `location` `if`

在默认情况下，set 命令默认值为空，可以 nginx 配置文件的 server location if 部分使用，下面是一个示例配置

```
location / {
    proxy_pass http://127.0.0.1:8080/;
    set $query $query_string;
    rewrite /dede /wordpress?$query?;
}
```

> 在这个例子中，要实现将请求 `http://www.liwanggui.com/dede/wp?p=160` 的页面，重写到地址 `http://www.liwanggui.com/wordpress/?p=160`, 也就是重写带参数的 URL. 这里涉及 `$query_string` 变量，这个变量相当于请求行中的参数，也就是`？` 后面的内容。也可以用 $args 代替 `$query_string` 变量

### break 命令

`break` 的用法在前面的介绍中其实已经出现过，它表示完成当前设置的规则后，不再匹配后面的重写规则。 break的使用语法如下：

- 语法： `break`
- 默认值： `none`
- 使用字段： `server` `lcoation` `if`

在默认情况下，`break` 命令的值为空，可以 `nginx` 配置文件的 `server` `lcoation` `if` 部分使用，下面是一个示例配置

```
server {
    listen 80;
    server_name www.lwg.com www.liwanggui.com;
    if ($host != 'www.wb.com'){
        rewrite ^/(.*)$ http://www.lwg.com/error.txt break;
        rewrite ^/(.*)$ http://www.lwg.com/$1 permanent;
    }
}
```

> 这个例子定义了两个域名 `www.lwg.com` 和 `www.liwanggui.com`, 当通过域名 `www.liwanggui.com` 访问网站时，会将请求重定向到 `http://www.lwg.com/error.txt` 页面，由于设置了 `break` 命令，因此下面的 `rewrite` 规则不再执行，直接退出。

