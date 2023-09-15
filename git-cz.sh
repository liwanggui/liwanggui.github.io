#!/bin/bash
#
#***************************************************************************
# Author: liwanggui
# Email: liwanggui@163.com
# Date: 2023-08-15
# FileName: git-cz.sh
# Description: init git-commit-style-guide
# Copyright (C): 2023 All rights reserved
#***************************************************************************
#

version="v18.17.1"
install_dir="/usr/local/node"

cd $(dirname $0)

install_git_cz() {
    echo "全局安装 commitizen conventional-changelog-cli"
    npm install -g commitizen conventional-changelog-cli

    echo "在项目根目录执行 npm install 安装 cz-customizable validate-commit-msg husky"
    npm install
}

if type -P npm >/dev/null ; then
    install_git_cz
else
    [ -f ${install_dir}/bin/npm ] && {
        echo "npm 不在 PATH 环境变量中，请配置后重试"
        echo "export PATH=${install_dir}/bin:\$PATH >> ~/.bashrc"
        echo "source ~/.bashrc"
        exit 1
    }
    # 安装 nodejs
    curl -s https://mirrors.aliyun.com/nodejs-release/${version}/node-${version}-linux-x64.tar.xz | sudo tar -xJ --strip 1 -C ${install_dir}
    export PATH=${install_dir}/bin:$PATH
    install_git_cz
fi
