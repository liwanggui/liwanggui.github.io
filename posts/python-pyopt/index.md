# PyOTP 实现双重或多因素身份验证


> Github 官方仓库: [https://github.com/pyauth/pyotp](https://github.com/pyauth/pyotp)

## 生成密钥

PyOTP 提供了一个帮助函数来生成一个16个字符的 base32 密钥，与Google Authenticator和其他OTP应用程序兼容：

```python
import pyotp
secret = pyotp.random_base32()
```

某些应用程序希望将密钥格式化为十六进制编码字符串：

```python
pyotp.random_hex()  # returns a 32-character hex-encoded secret
```

## 基于时间的 OTP

```python
import pyotp

totp = pyotp.TOTP('base32secret3232')
totp.now() # => '492039'

# OTP verified for current time
totp.verify('492039') # => True
time.sleep(30)
totp.verify('492039') # => False
```

> 客户端可以使用 google 验证器，也可以使用洋葱身份验证器
