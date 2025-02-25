#!/bin/bash
#
#***************************************************************************
# Author: liwanggui
# Email: liwanggui@163.com
# Date: 2023-09-15
# FileName: hugo.sh
# Description: install hugo extended cli (linux and macOS)
# Copyright (C): 2023 All rights reserved
#***************************************************************************
#

PLATFORM=$(uname -s)
INSTALL_DIR="/usr/local/bin"
# 如有指定版本，就安装指定版本的 hugo
HUGO_VERSION=${HUGO_VERSION:-"v0.124.0"}
HUGO_REPO_NAME="gohugoio/hugo"
GITHUB_PROXY="${GITHUB_PROXY:-https://gh.wglee.org/}"
LATEST_API_URL="https://api.github.com/repos/${HUGO_REPO_NAME}/releases/latest"

get_latest_version() {
    if [[ -n $HUGO_VERSION ]]; then
        echo $HUGO_VERSION
    else
        curl -s ${LATEST_API_URL} | grep tag_name | awk -F'"' '{print $(NF-1)}'
    fi
}

install_hugo() {
    local latest_version
    local download_url
    local github_api_url="https://api.github.com/repos/${HUGO_REPO_NAME}/releases/tags"

    if [[ -f ${INSTALL_DIR}/hugo ]]; then
        echo "hugo already exists"
        exit 0
    fi

    latest_version=$(get_latest_version)

    case ${PLATFORM} in 
        [Dd]arwin)
            download_url=$(curl -sfL ${github_api_url}/${latest_version} | grep browser_download_url | grep -i extended | grep -i ${PLATFORM} | awk -F'"' '{print $(NF-1)}')
            ;;
        [Ll]inux)
            download_url=$(curl -sfL ${github_api_url}/${latest_version} | grep browser_download_url | grep -i extended | grep -i ${PLATFORM}  | grep '64bit.tar.gz' | awk -F'"' '{print $(NF-1)}')
            ;;
    esac
    
    if [[ -z "${download_url}" ]]; then
        echo "获取下载地址失败！请打开此链接获取下载地址 https://github.com/gohugoio/hugo/releases/${latest_version}"
        read -p "请输入你获取的下载地址: " download_url
    fi

    echo "install hugo"
    echo "download url: ${download_url}"

    if curl -q -fL ${GITHUB_PROXY}${download_url} | sudo tar xz -C ${INSTALL_DIR} hugo; then
        [ -x ${INSTALL_DIR}/hugo ] || sudo chmod +x ${INSTALL_DIR}/hugo
        echo "installation complete"
        exit 0
    else
        echo "installation failure"
        exit 1
    fi
}

install_hugo
