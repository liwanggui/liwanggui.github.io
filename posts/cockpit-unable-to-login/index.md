# 新版本浏览器导致 Cockpit 无法登录的问题


使用 `Chrome` 和 `Edge` 浏览器登录 `Cockpit` 时，提示 “此浏览器过旧” 的错误，如图

{{< image src="/images/d20a646f-aea0-4e77-a421-4c8f70845921.png" caption="这个浏览器太老，无法运行 Web 控制台（缺少 `selector(:is():where())`）" >}}

**解决方法**

如果使用的操作系统没有提供 `Cockpit` 更新包，可以使用以下方法修复这个错误

```bash
sed -i 's/is():where()/is(*):where(*)/' /usr/share/cockpit/static/login.js
```

其实这个代码原理就是把文档 login.js 中的 “`is():where()`” 替换为 "`is(*):where(*)`"

官方博客链接地址:  https://cockpit-project.org/blog/login-issues.html

