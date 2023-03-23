#!/bin/bash
# 更新站点到 github
# 对应域名  liwanggui.com

set -x

LANG=c
RELEASE_DIR="dist"
BASE_DIR=$(dirname $(readlink -f $0))

buildToGithub() {
    cd $BASE_DIR
    if [ ! -d $RELEASE_DIR ]; then
        git clone git@github.com:liwanggui/liwanggui.github.io.git $RELEASE_DIR
    fi

    cd $RELEASE_DIR && \
        git fetch --all && \
        git reset --hard origin/master && \
        cd ..

    hugo -d $RELEASE_DIR && \
        cd $RELEASE_DIR && \
        git add . && \
        git commit -m "feat: add/update document at $(date)" && \
        git push origin master
}

buildToAliyun() {
    cd $BASE_DIR
    hugo
    ossutil sync public/ oss://liwanggui/ -f --delete
}

buildToAliyun
buildToGithub
