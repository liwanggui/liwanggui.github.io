---
title: 关于
comment: false
draft: false
---

> “浅行” 取自 陆游 《冬夜读书示子聿》 的最后一句。 自知学问尚浅，唯有不断前行，不断学习以充实已身。

---

**冬夜读书示子聿  -宋.陆游**

古人学问无遗力，少壮工夫老始成。<br/>
纸上得来终觉浅，绝知此事要躬行。

---

**人生三句箴言**

- 有勇气去改变可以改变的事情
- 有胸怀去接纳不可以改变的事情
- 用智慧去分辨两者的不同

---

{{< admonition type=tip title="每日一言" open=true >}}
<span id="todayisword">正在加载今日之言....</span>
{{< /admonition >}}

<script>
var ajax = new XMLHttpRequest();
ajax.open("GET", "https://v1.hitokoto.cn/?c=a&c=f&c=j&c=e&encode=text", true);
ajax.send(null);
ajax.onreadystatechange = function () {
    if (ajax.readyState === 4){
        if (ajax.status === 200) {
            var jinri = document.getElementById("todayisword");
            jinri.textContent = ajax.responseText;
        }
    }
}
</script>

<!-- {{< music netease song 1842025914 >}} 莫文蔚 - 这世界那么多人-->