# 使用 Python 求解鸡兔同笼


使用 "穷举法" 求解鸡兔同笼，Python 代码实现如下

```python
def chicken_and_rabbit(head: int, foot: int) -> list: 
    if foot % 2 != 0:
        raise ValueError("参数 foot 必须为偶数")
    result = []
    rabbit, chicken = 0, 0
    while rabbit < head:
        rabbit += 1
        chicken = head - rabbit
        # print(f"chicken: {chicken}, rabbit: {rabbit}", rabbit * 4 + chicken * 2)
        if rabbit * 4 + chicken * 2 == foot:
            result.append({"chicken": chicken, "rabbit": rabbit})
    return result


def main(head: int, foot: int):
    results = chicken_and_rabbit(head, foot)
    if not results:
        print("无解")
    else:
        for res in results:
            print(res)

if __name__ == "__main__":
    main(30, 88)
```

