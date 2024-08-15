# Python 调用企业微信发送消息


## 企业微信 API

通过 python 调用企业微信的 api 接口来发送消息，可用于监控告警。使用 `requests` 模块。

```python
#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# pip install requests
#

import os
import time
import redis
import requests

class WXWork(object):
    def __init__(self, corpid, secret, agentid):
        self.token_file = '/tmp/temp_wechat'
        self.url = "https://qyapi.weixin.qq.com/cgi-bin"
        self.corpid = corpid
        self.corpsecret = secret
        self.agentid = agentid

    def _get_token(self):
        # 获取 token 并缓存
        response = requests.get(url=self.url + '/gettoken',
                                params=dict(corpid=self.corpid, corpsecret=self.corpsecret))
        return response.json()

    def get_token(self):
        if os.path.isfile(self.token_file):
            with open(self.token_file) as f:
                token_info = f.read()
            if len(token_info.split()) == 2:
                expire, token = token_info.split()
                if float(expire) > time.time():
                    return token
        d = self._get_token()
        try:
            if d['errcode'] == 0:
                with open(self.token_file, 'w') as f:
                    f.write("%s %s" % (time.time() + d['expires_in'], d['access_token']))
                return d['access_token']
        except Exception as e:
            return False

    def send(self, msg):
        token = self.get_token()
        if token:
            url = self.url + '/message/send?access_token=%s' % token
            data = dict(
                toparty="1",
                msgtype="text",
                agentid=self.agentid,
                text=dict(content=msg),
                safe=0
            )
            response = requests.post(url=url, json=data)
            d = response.json()
            if d["errcode"] != 0:
                return 'Send message failed.'
        else:
            return 'Get token failed.'


if __name__ == '__main__':
    # 企业ID
    corpid = "xxxxxx"
    # 应用的凭证密钥
    secret = "xxxxxxxxxxxxxxxxxx"
    # 企业应用的id，整型。可在应用的设置页面查看
    agentid = 1000002
    # 发送的消息
    msg = "这是只个无聊的消息。"
    wechat = WXWork(corpid, secret, agentid)
    wechat.send(msg)
```

