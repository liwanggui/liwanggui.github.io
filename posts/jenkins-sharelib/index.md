# Jenkins 共享库应用


## 概述

共享库这并不是一个全新的概念，其实具有编程能力的同学应该清楚一些。例如在编程语言 `Python` 中，我们可以将 `Python` 代码写到一个文件中，当代码数量增加，我们可以将代码打包成模块然后再以 `import` 的方式使用此模块中的方法。

在 `Jenkins` 中使用 `Groovy` 语法，共享库中存储的每个文件都是一个 `Groovy` 的类，每个文件（类）中包含一个或多个方法。每个方法包含 `Groovy` 语句块。

> Jenkins 共享参考库: [https://github.com/liwanggui/jenkins-share-lib.git](https://github.com/liwanggui/jenkins-share-lib.git)

## 共享库内容

共享参考库文件结构如下

```bash
── vars
│   └── getIP.groovy
│   └── hello.groovy
├── src
│   └── org
│       └── devops
│           └── HTTP.groovy
├── Jenkinsfile
└── README.md
```

`src` 目录主要存放我们要编写的 `Groovy` 类，执行流水线时，此目录将添加到 `class_path` 中。 vars目录主要存放脚本文件，这些脚本文件在流水线中作为变量公开。 `resources` 目录允许从外部库中使用步骤来加载相关联的非 `Groovy` 文件。

## 创建共享库

文件 `src/org/devops/HTTP.groovy`, 在此我将这个文件定义为 HTTP 请求类，主要放一些 HTTP 请求方法。

```groovy
package org.devops

import groovy.json.JsonOutput

/**
* 发送 HTTP GET 请求
 * @param url 请求的网址
 * @return String
 */
def get(url){
    return new URL(url).text
}


/**
 * 发送 HTTP POST 请求
 * @param url 请求的网址
 * @param data 请求所需的参数，可选
 * @param is_json 请求参数类型是否为 json 格式
 * @return String
 */
def post(url, data = null, is_json = false) {
    def conn = new URL(url).openConnection()
    conn.setRequestMethod("POST")
    if (data) {
        if (is_json) {
            conn.setRequestProperty("Content-Type", "application/json")
            data = JsonOutput.toJson(data)
        }
        // 输出请求参数
        println(data)
        conn.doOutput = true
        def writer = new OutputStreamWriter(conn.outputStream)
        writer.write(data)
        writer.flush()
        writer.close()
    }
    def result = conn.content.text
    // 输出请求结果
    // result.each({ println it })
    return result
}
```

## 使用共享库

我们打开 Jenkins 管理页面，依次点击 `Manage Jenkins` -> `System Configuration` -> `Global Pipeline Libraries`

首先，我们为共享库设置一个名称 `jenkinslib`，注意这个名称后续在 `Jenkinsfile` 中引用。 再设置一个默认的版本，这里的版本是分支的名称。我默认配置的是 `main` (github 将 `master` 改为了 `main`) 版本。

好，到此共享库在 `Jenkins` 的配置就完成了，接下来测试在 `Jenkinsfile` 中引用。

在 `Jenkinsfile` 中使用 `@Library('jenkinslib') _` 来加载共享库，注意后面符号 `_` 用于加载。 类的实例化 `def http = new org.devops.HTTP()`, 使用类中的方法 `http.get("https://httpbin.org/ip")`。

```groovy
@Library('jenkinslib') _

import org.devops.HTTP

// 创建 HTTP 类实例
def http = new HTTP()

pipeline {
	agent any

	stages {
		stage("发送 POST 请求") {
			steps {
				println http.post("https://httpbin.org/post")
			}
		}

		stage("获取主机公网 IP") {
			steps {
				println getIP()
			}
		}
	}
}
```

> 接下来在你的 Jenkins 上面运行一下吧







