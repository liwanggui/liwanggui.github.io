# 使用 cfssl 自签证书


## CFSSL 简介

`CFSSL` 是 `CloudFlare` 开源的一款 `PKI/TLS` 瑞士军刀工具。 
`CFSSL` 既是命令行工具，又是用于签名，验证和捆绑 TLS 证书的 HTTP API 服务器。 使用 `Go 1.12+` 语言编写。

- 官方源码仓库: [https://github.com/cloudflare/cfssl](https://github.com/cloudflare/cfssl)

## 安装 cfssl

```bash
wget https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssljson_1.5.0_linux_amd64 -O /usr/local/bin/cfssl-json
wget https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssl_1.5.0_linux_amd64 -O /usr/local/bin/cfssl
wget https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssl-certinfo_1.5.0_linux_amd64 -O /usr/local/bin/cfssl-certinfo
chmod +x /usr/local/bin/cfssl*
```

## 自签证书

### 签发 CA 证书

*生成 CA 证书签名请求文件 `ca-csr.json`*

```bash
mkdir certs
cd certs/
cat > ca-csr.json <<EOF
{
    "CN": "CA",
    "hosts": [
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "BeiJing",
            "O": "BJ",
            "ST": "BeiJing",
            "OU": "CA"
        }
    ],
    "ca": {
        "expiry": "175200h"
    }
}
EOF
```

> 证书签名请求文件可以使用 `cfssl print-defaults csr` 创建，然后在进行相应的修改

*生成 CA 证书*

```bash
cfssl gencert -initca ca-csr.json | cfssl-json -bare ca
```

### 签发域名证书

自签发一个域名证书，以 `host.com` 域名为例

*生成证书配置文件*

> 默认配置可以使用 `cfssl print-defaults config` 命令生成

```bash
cat > config.json <<EOF
{
    "signing": {
        "default": {
            "expiry": "87600h"
        },
        "profiles": {
            "www": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            }
        }
    }
}
EOF
```

*生成 `host.com` 域名证书签名请求文件 `host-csr.json`*

```bash
cat > host-csr.json <<EOF
{
    "CN": "host.com",
    "hosts": [
        "host.com",
        "*.host.com"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "BeiJing",
            "O": "BJ",
            "ST": "BeiJing",
            "OU": "HOST"
        }
    ]
}
EOF
```

*签发 host.com 域名证书*

```bash
cfssl gencert -ca ca.pem -ca-key ca-key.pem -config config.json -profile www host-csr.json | cfssl-json -bare host
```

*使用 `cfssl-certinfo` 命令查看证书信息*

```bash
root@10-7-79-148:~/certs# cfssl-certinfo -cert host.pem
{
  "subject": {
    "common_name": "host.com",
    "country": "CN",
    "organization": "BJ",
    "organizational_unit": "HOST",
    "locality": "BeiJing",
    "province": "BeiJing",
    "names": [
      "CN",
      "BeiJing",
      "BeiJing",
      "BJ",
      "HOST",
      "host.com"
    ]
  },
  "issuer": {
    "common_name": "CA",
    "country": "CN",
    "organization": "BJ",
    "organizational_unit": "CA",
    "locality": "BeiJing",
    "province": "BeiJing",
    "names": [
      "CN",
      "BeiJing",
      "BeiJing",
      "BJ",
      "CA",
      "CA"
    ]
  },
  "serial_number": "50106944723092673296745532281502755453871335123",
  "sans": [
    "host.com",
    "*.host.com"
  ],
  "not_before": "2021-04-22T13:28:00Z",
  "not_after": "2031-04-20T13:28:00Z",
  "sigalg": "SHA256WithRSA",
  "authority_key_id": "46:6C:D3:F9:1A:89:A0:B6:11:82:DA:E2:8B:8D:00:24:3E:8F:9E:3D",
  "subject_key_id": "6A:E8:F5:D9:E5:14:C0:2E:AE:53:DF:41:AF:9E:FF:A7:9B:D4:6A:80",
  "pem": "-----BEGIN CERTIFICATE-----\nMIID3jCCAsagAwIBAgIUCMbfhCW8BG+QACtbh8V8YVcoJtMwDQYJKoZIhvcNAQEL\nBQAwWDELMAkGA1UEBhMCQ04xEDAOBgNVBAgTB0JlaUppbmcxEDAOBgNVBAcTB0Jl\naUppbmcxCzAJBgNVBAoTAkJKMQswCQYDVQQLEwJDQTELMAkGA1UEAxMCQ0EwHhcN\nMjEwNDIyMTMyODAwWhcNMzEwNDIwMTMyODAwWjBgMQswCQYDVQQGEwJDTjEQMA4G\nA1UECBMHQmVpSmluZzEQMA4GA1UEBxMHQmVpSmluZzELMAkGA1UEChMCQkoxDTAL\nBgNVBAsTBEhPU1QxETAPBgNVBAMTCGhvc3QuY29tMIIBIjANBgkqhkiG9w0BAQEF\nAAOCAQ8AMIIBCgKCAQEA3ZfbPOW2hzTi3Ec/gpufnhaOkRiCZYIcGe5BJx+cip8c\nh553anDZts2i1ZTYMeTjwtgHbojHqgqGgcF3xsCHQidRwoOhp7UHRgwfAacfmv0U\nF5qmoPfNcbQzyZXhDJZAZqWLGqDBhCR/hVVugahXmZb8XzkpreTYTGHAiwAgUKXq\nDEtEDr0D6LRw27+dR/1bwFs0ad2aEeJxvdH5Y40hO796VoPbX6PCI/TPkMnUsdTF\nL51Ge+WEKk4TwEEghV1fl6+gGg3dmTcHpb8S5/zhe1bDI7Zs9/ErTAxd1HDdlPxt\n66HtiygfKEjy8qVtsCIz+hzCxn9bZsmwNRdvV0QitQIDAQABo4GXMIGUMA4GA1Ud\nDwEB/wQEAwIFoDATBgNVHSUEDDAKBggrBgEFBQcDATAMBgNVHRMBAf8EAjAAMB0G\nA1UdDgQWBBRq6PXZ5RTALq5T30Gvnv+nm9RqgDAfBgNVHSMEGDAWgBRGbNP5Gomg\nthGC2uKLjQAkPo+ePTAfBgNVHREEGDAWgghob3N0LmNvbYIKKi5ob3N0LmNvbTAN\nBgkqhkiG9w0BAQsFAAOCAQEAluByuUmRaPi1+SxjosQI8w6CvJC0N5XbAjsyXrDo\netwpKKty0745aKyCtkFu6KW7bQohoX4JBdSrqve9V1Psm7Iwh6P8LKBRckBn6lMq\ndavsgoGkyD/RwRMLUpi0TW8bvd0m+BOO2iHb+BSID7C+WPxflZb2Z8z1ljyzFaM6\nmfevfYMqUiiRP/ztHvrHcZnk9pQi3kserPJg5DIzNvsvMd1T8IwJg36iIt6j4pi1\nbtmXSWssMSR1vc7ZPWjS3Jc+2nDVjyPvARJsoAy6BBg07Pd41FhgKPgQE8il1oxc\n3ep1OXlIC5IjfoZWrp80kznOaj++cOzl1Mg3k+eVyKmx1w==\n-----END CERTIFICATE-----\n"
}
```
