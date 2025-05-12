# Groovy 发送 HTTP 请求


## GET 请求

使用 Groovy 发送 GET 请求非常简单，一行代码搞定

```groovy
def res1 = new URL('https://httpbin.org/ip').text
// or 
def res2 = 'https://httpbin.org/ip'.toURL().text
```

## POST 请求

使用标准库 URL 类，发送 POST 请求

```groovy
import groovy.json.JsonOutput
import groovy.json.JsonSlurper

/**
 * 发送 HTTP POST 请求
 * @param url 请求的网址
 * @param data 请求所需的参数，可选
 * @param is_json 请求参数类型是否为 json 格式
 * @return Map
 */
def http_post(url, data = null, is_json = false) {
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
    def json = new JsonSlurper()
    json.parseText(conn.content.text)
}

http_post('https://httpbin.org/post', '{"name": "John", "age": 34}', true)
```
