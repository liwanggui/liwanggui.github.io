#!/bin/bash
#
#***************************************************************************
# Author: liwanggui
# Email: liwanggui@163.com
# Date: 2023-09-15
# FileName: hugo.sh
# Description: install hugo extended cli
# Copyright (C): 2023 All rights reserved
#***************************************************************************
#

version="v0.101.0"
platform=$(uname -s)

github_proxy="https://gh.wglee.org/"
github_api_url="https://api.github.com/repos/gohugoio/hugo/releases/tags/${version}"
download_url=$(curl -sfL ${github_api_url} | grep browser_download_url | grep -i 'extended' | grep -i ${platform}  | grep '64bit.tar.gz' | awk -F'"' '{print $(NF-1)}')

install_dir=/usr/local/bin

[ -f ${install_dir}/hugo ] || {
    echo "install hugo"
    if [[ -z "$download_url" ]]; then
        echo "download url: http://dl.wglee.cn/linux/init/hugo"
        sudo curl -so ${install_dir}/hugo  http://dl.wglee.cn/linux/init/hugo
    else
        echo "download url: ${download_url}"
        curl -sfL ${github_proxy}${download_url} | sudo tar xz -C ${install_dir} hugo
    fi

    [ $? -eq 0 ] || {
        echo "installation failure"
        exit 1
    }

    [ -x ${install_dir}/hugo ] || sudo chmod +x ${install_dir}/hugo
    echo "installation complete"
    exit 0
}

echo "hugo already exists"
