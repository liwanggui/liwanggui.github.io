#!/bin/bash
#
#***************************************************************************
# Author: liwanggui
# Email: liwanggui@163.com
# Date: 2023-08-15
# FileName: git-cz.sh
# Description: 初始化 git-commit-style-guide
# Copyright (C): 2023 All rights reserved
#***************************************************************************
#

command -v npm >/dev/null || {
    echo "nodejs 没有安装或者没加入 PATH 环境变量中"
    exit 1
}

cd $(dirname $0)

echo "全局安装 commitizen conventional-changelog-cli"

npm install -g commitizen conventional-changelog-cli

echo "在项目根目录执行 npm install 安装 cz-customizable validate-commit-msg husky"

npm install