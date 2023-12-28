---
title: "Bash 基础"
date: 2021-06-13T18:05:23+08:00
draft: false
categories: 
- bash
tags:
- bash
---

## 变量

Bash 变量为弱类型事先不用指定值的类型，Bash 变量默认为全局变量，可以使用 `local` 关键字定义局部变量

```bash
# 默认为全局变量
s='this is a test'

# 函数中使用 local 关键字定义局部变量
a() {
    local s='s in function a'
    echo $s
}

# 打印变量长度
echo ${#s}
echo $s
```

> 注意: local 关键字只能在函数中使用

## 逻辑运算符

- `!` : 逻辑非; 表达式为 true 则返回 false，否则返回 true; 
    - 例: `[ ! false ]` 返回 `true`
- `&&`: 逻辑与; 两个表达式都为 true 才返回 true; 等价于 (`-a`) 表示; 
    - 例: `[ $a -lt 20 -a $b -gt 100 ]` 返回 `true`
- `||`: 逻辑或; 有一个表达式为 true 则返回 true; 等价于 (`-o`) 表示; 
    - 例: `[ $a -lt 20 -o $b -gt 100 ]` 返回 `false`

*示例*

```bash
which iftop && echo "iftop exist"
which iftop || echo "iftop does not exist"
```

## 比较运算符

### 1.数字比较

* `-gt`: 大于
* `-lt`: 小于
* `-ge`: 大于或等于
* `-le`: 小于或等于
* `-ne`: 不等于
* `-eq`: 等于

### 2.字符比较

- [[ `$str1` = `$str2` ]]: 判断两个字符串是否相等 （等号前后有空格）
- [[ `$str1` == `$str2` ]]: 判断两个字符串是否相等，也可以是数字
- [[ `$str1` != `$str2` ]]: 判断两个字符串是否不相等 

*检查字符串的字母排序情况，具体如下：*

- [[ `$str1` > `$str2` ]]: 如果 str1 的字母排序比 str2 大，则返回 true
- [[ `$str1` < `$str2` ]]: 如果 str1 的字母排序比 str2 小，则返回 true

### 3.变量检测

- `[[ -z $str1 ]]`: 如果字符串长度为 0，则为 true
- `[[ -n $str1 ]]`: 如果字符串长度不为 0，则为 true
- `[[ $str1 ]]`: 检测字符串是否为空，不为空返回 true

### 4.文件系统选项

- `[ -f $var ]`: 判断是否为文件
- `[ -x $var ]`: 判断文件是否有可执行权限
- `[ -d $var ]`: 判断是否为一个目录
- `[ -e $var ]`: 判断文件是否存在
- `[ -c $var ]`: 判断文件是字符设备 （不知有啥用途）
- `[ -b $var ]`: 判断是否为设备文件
- `[ -w $var ]`: 判断文件是否有可写权限”w“
- `[ -r $var ]`: 判断文件是否有可读权限”r"
- `[ -L $var ]`: 判断是否为符号链接

## 数组

Bash Shell 只支持一维数组（不支持多维数组），初始化时不需要定义数组大小（与 PHP 类似）。

与大部分编程语言类似，数组元素的下标由 0 开始。

Shell 数组用括号来表示，元素用"空格"符号分割开

```bash
arr=("first" "second" "third")

# 修改数组值
arr[0]='No.1'

# 增加值
arr[3]='fourth'

# 获取数组所有值
echo ${arr[@]}
echo ${arr[*]}

# 获取数组长度
echo ${#arr[@]}

# 打印所有下标(索引)，从 0 开始
echo ${!arr[@]}

# for 遍历数组，这个方法有时达不到理想效果, 参考 for 循环的坑
for a in ${arr[@]}; do
    echo $a
done

# for 通过下标遍历数组, 推荐使用这个方式
for i in ${!arr[@]}; do
    echo ${arr[$i]}
done
```

*关联数组，可以理解为 python 的字典*

```bash
declare -A arrary

array["name"]="xiaoming"
array["age"]=29

for k in ${!array[@]}; do
    echo "$k => ${array[$k]}"
done
```

> 注意: 如果 key 字符串中含有空白符，for 循环时需要设定 IFS 才能正常遍历数组

**for 循环遍历数组的坑--由 IFS 引起**

```bash
#!/bin/bash
string=(
"this is first line"
"this is second line"
"this is third line"
)

for line in ${string[@]}; do
    echo $line
    sleep 0.5
done
```

> 注意: 由于 for 循环是通过空白符(空格，换行，tab)截断数据进行循环的，所以数组中的字符串含有空白符会被截断处理。

## 条件判断语句

### 1. 使用 `test` 和 `[ ]` 进行条件判断

`test` 与 `[ ]` 是对等的功能一致。

**test**

```bash
[root@localhost ~]# test -f /etc/passwd && echo yes
yes
[root@localhost ~]# test -d /etc/ && echo yes
yes
```

**将test 替换为 [ ]**

```bash
[root@localhost ~]# [ -f /etc/passwd ] && echo yes
yes
[root@localhost ~]# [ -d /etc ] && echo yes
yes
```

> *Tips:* `[]` 与其中的命令两边必须得空格隔开才行，否则会报错

```bash
[root@localhost ~]# [-d /etc ] && echo yes
-bash: [-d: command not found
```

> 以上就是没有用空格隔开导致的错误

### 2. if 语句，条件判断

在其他编程语言中，`if`语句后面的对象是一个值为`TRUE`或`FALSE`的等式。`bash shell`脚本中的`if`语句不是这样的。
`bash shell`中的`if`语句运行在`if`行定义的命令。如果命令的退出状态是`0`（成功执行命令），将执行`then`后面的所有命令。
如果命令的退出状态是`0`以外的其他值，那么`then`后面的命令将不会执行，`bash shell`会移动到脚本的下一条命令。

**单分支**

```bash
if [[ $? -eq 0 ]]; then
    echo "successfully"
else
    echo "failed"
fi
```

**多分支**

```bash
read -p "please input a number:" num
if [[ $num -le 10 ]]; then
    echo "num 小于等于 10"
elif [[ $num -le 20 ]]; then # elif 可以有多个
    echo "num 小于等于 20
fi
```

**扩展：可以直接通过命令执行状态进行判断**

示例：服务监控脚本（pptpd 服务器监控）

```bash
#!/bin/bash
TIME=5
while :; do
    if netstat -anptl | grep -q "pptpd" # -q 不显示任何内容，此处只是判断不需要显示
    then
            echo "$(date +%Y-%m-%d' '%H:%M:%S) pptpd is runing..." > /tmp/pptpd.log
    else
            /etc/init.d/pptpd restart-kill
            /etc/init.d/pptpd start
    fi
    sleep $TIME
done
```

### 3. case 语句

上面提到的『 if .... then .... fi 』对于变量的判断是以『比对』的方式来分辨的， 如果符合状态就进行某些行为，并且透过较多层次 (就是 elif ...) 的方式来进行多个变量的程序码编写。 好，那么万一我有多个既定的变量内容，我所需要的变量就是 "hello" 及空字串两个， 那么我只要针对这两个变量来配置状况就好了，对吧？那么可以使用什么方式来设计呢？呵呵～就用 case ... in .... esac 吧～，他的语法如下：

```bash
case $变量名 in 
   "第一个变量值") # 每个变量内容建议用双引号括起来，关键字则为小括号
       echo 'first'
       ;; # 每项最后用两个分号表示结束。
   "第二个变量值")
       echo 'second"
       ;;
   *) # 最一个变量用星号来表示所有其他值
    echo "default"
    ;;
esac
```

**示例**

```bash
#!/bin/bash
clear
cat << EOF
        Sys Admin Menu
    1. Display disk space
    2. Display memory usage
    0. Exit menu
EOF
read -n 1 -p "Enter option:" option

case $option in 
    1)
        df -hT
        ;;
    2)
        free -m
        ;;
    0)
        exit 0
        ;;
    *)
       echo "Warning: wrong choice, please re-select."
esac
```

## 循环语句
 
### 1. `for` 循环
 
```bash
# 1. 循环一个列表
for shname in $(ls *.sh)
do
   name=$(echo "$shname" | awk -F. '{print $1}')
   echo $name
done

# 2. 指定循环次数 （有点像C语法，但记得双括号）
for (( i=0;i<10;i++)) {
   echo $i
}

# 3. 等价于2
for i in $(seq 1 10)
do
    echo $i
done
```
 
### 2. `while` 循环
 
`while` 循环，只有结果为真时（在linux退出状态为0）才会执行，直接结果为假时才终止循环。为真时执行，用true作为循环条件可以无限循环。

**简单语法演示**

```bash
while :
do
   date +%F
   sleep 2
done
```

> 注意: 在linux中`:`表示真，可以替代`true`,以上示例是个死循环，需要添加终止条件。

**示例 1**

```bash
min=1
max=100
while [ $min -le $max ]
do
    echo $min
    min=`expr $min + 1`
done 
```

**示例 2 双括号形式，内部结构有点像C的语法，注意赋值：i=$(($i+1))**

```bash
i=1
while(($i<100))
do
    if(($i%4==0))
    then
        echo $i
    fi
    i=$(($i+1))
done
```
 
### 3. `until` 循环
 
直到给定的结果为真时，停止循环。刚好与`while`循环相反。（貌似不常用）
 
```bash
x=0
until [ $x -eq 9 ];
do
    let x++;
    echo $x;
done
```
 
### 4. 生成连续的数字，字母列表（序列）
 
```bash
# 打印1到100的数字
echo {1..100}
seq 100
 
# 打印小写所有字母
echo {a..z}
 
# 打印大写所有字母
echo {A..Z}
```

### 5. 循环控制语句

- `break` 命令不执行当前循环体内break下面的语句从当前循环退出.
- `continue` 命令是程序在本循体内忽略下面的语句,从循环头开始执行

## 函数

*定义函数*

```bash
function f1() {
    echo 'this is f1'
}

function f2 {
    echo 'this is f2'
}

f3() {
    echo 'this is f3'
}
```

*函数的调用与传值*

```bash
hello() {
    echo "hello ${1}!"
}

# 调用函数并传传递参数
hello $1
```
