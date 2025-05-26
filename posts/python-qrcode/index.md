# Python 批量生成二维码


## 创建虚拟环境

```bash
python3 -m venv pyenv
source pyenv/bin/activate
```

## 安装依赖库

```bash
pip install Image
pip install qrcode
```

## 编写代码

```python
import qrcode

def createQR(name, url):
    img = qrcode.make(url)
    name = name + '.png'
    with open(name, 'wb') as f:
        img.save(f)
    print("create QR code: ", name)


def main(filename):
    with open(filename) as f:
        for line in f:
            name, url = line.split(',')
            createQR(name, url)

if __name__ == '__main__':
    main('test.txt')
```

## 准备数据文件

程序从文本文件中读取数据，以行为单位，根据每行数据内容生成二维码
格式: 生成二维码文件名,网址

> 使用逗号为分隔符

*示例 test.txt*

```
baidu,https://www.baidu.com
tencent,https://www.qq.com
```

## 执行

```bash
$ python qr.py
create QR code:  baidu.png
create QR code:  tencent.png
```
