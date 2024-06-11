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

version="v0.127.0"
platform=$(uname -s)

github_proxy="https://gh.wglee.org/"
github_api_url="https://api.github.com/repos/gohugoio/hugo/releases/tags/${version}"
download_url=$(curl -sfL ${github_api_url} | grep browser_download_url | grep -i 'extended' | grep -i ${platform}  | grep '64bit.tar.gz' | awk -F'"' '{print $(NF-1)}')

install_dir=/usr/local/bin

[ -f ${install_dir}/hugo ] || {
    echo "install hugo"
    echo "download url: ${download_url}"
    curl -q -fL ${github_proxy}${download_url} | sudo tar xz -C ${install_dir} hugo

    [ $? -eq 0 ] || {
        echo "installation failure"
        exit 1
    }

    [ -x ${install_dir}/hugo ] || sudo chmod +x ${install_dir}/hugo
    echo "installation complete"
    exit 0
}

echo "hugo already exists"
