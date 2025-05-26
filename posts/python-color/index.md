# Python 终端颜色输出


## 实现过程

终端的字符颜色是用转义序列控制的，是文本模式下的系统显示功能，和具体的语言无关。
转义序列是以 `ESC` 开头,即用 `\033` 来完成（ `ESC` 的 `ASCII` 码用十进制表示是 `27`，用八进制表示就是 `033`）。
 
## 书写格式

开头部分：`\033[显示方式;前景色;背景色m + 结尾部分：\033[0m`

*解释：*

开头部分的三个参数：显示方式，前景色，背景色是可选参数，可以只写其中的某一个；
由于表示三个参数不同含义的数值都是唯一的没有重复的，所以三个参数的书写先后顺序没有固定要求，系统都能识别；
建议按照默认的格式规范书写。

对于结尾部分，其实也可以省略，但是为了书写规范，建议 \033[***开头，\033[0m结尾。
 
数值表示的参数含义：

```
显示方式: 0（默认）、1（高亮）、22（非粗体）、4（下划线）、24（非下划线）、 5（闪烁）、25（非闪烁）、7（反显）、27（非反显）
前景色:   30（黑色）、31（红色）、32（绿色）、 33（黄色）、34（蓝色）、35（洋 红）、36（青色）、37（白色）
背景色:   40（黑色）、41（红色）、42（绿色）、 43（黄色）、44（蓝色）、45（洋 红）、46（青色）、47（白色）
```

## 代码示例

*第一个参数，改变显示方式*

```python
print("显示方式：")  
print("\033[0;37;40m\tHello World\033[0m")  
print("\033[1;37;40m\tHello World\033[0m")  
print("\033[22;37;40m\tHello World\033[0m")  
print("\033[4;37;40m\tHello World\033[0m")  
print("\033[24;37;40m\tHello World\033[0m")  
print("\033[5;37;40m\tHello World\033[0m")  
print("\033[25;37;40m\tHello World\033[0m")  
print("\033[7;37;40m\tHello World\033[0m")  
print("\033[27;37;40m\tHello World\033[0m")
```

*第二个参数，改变字体颜色*

```python
print("前景色：")  
print("\033[0;30;40m\tHello World\033[0m")  
print("\033[0;31;40m\tHello World\033[0m")  
print("\033[0;32;40m\tHello World\033[0m")  
print("\033[0;33;40m\tHello World\033[0m")  
print("\033[0;34;40m\tHello World\033[0m")  
print("\033[0;35;40m\tHello World\033[0m")  
print("\033[0;36;40m\tHello World\033[0m")  
print("\033[0;37;40m\tHello World\033[0m")
```

*第三个参数，改变背景颜色*

```python
print("背景色：")  
print("\033[0;37;40m\tHello World\033[0m")
print("\033[0;37;41m\tHello World\033[0m")
print("\033[0;37;42m\tHello World\033[0m")
print("\033[0;37;43m\tHello World\033[0m")
print("\033[0;37;44m\tHello World\033[0m")
print("\033[0;37;45m\tHello World\033[0m")
print("\033[0;37;46m\tHello World\033[0m")
print("\033[0;37;47m\tHello World\033[0m")
```

> 源文档: [https://www.cnblogs.com/zhuminghui/p/9457185.html](https://www.cnblogs.com/zhuminghui/p/9457185.html)

