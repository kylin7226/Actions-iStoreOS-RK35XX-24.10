#!/bin/bash
#===============================================
# Description: DIY script
# File name: diy-script.sh
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#===============================================

# 添加 kenzo 和 small 源(kenzok8 推荐方式)
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default

# 指定 sing-box 版本为 v1.13.3
SING_BOX_VERSION="1.13.3"
SING_BOX_HASH="bf8933cd43e2797afcffb47528282e1c1aee078bf5eeda888d80a151fef726e1"
SING_BOX_PKG_PATH="feeds/small/sing-box"

if [ -d "$SING_BOX_PKG_PATH" ]; then
    # 修改 Makefile 中的版本号和 hash 值
    sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=${SING_BOX_VERSION}/" $SING_BOX_PKG_PATH/Makefile
    sed -i "s/PKG_HASH:=.*/PKG_HASH:=${SING_BOX_HASH}/" $SING_BOX_PKG_PATH/Makefile
    echo "sing-box 版本已指定为: v${SING_BOX_VERSION}"
else
    echo "警告: 未找到 sing-box 包路径，跳过版本指定"
fi

# 修复系统kernel内核md5校验码不正确的问题
# https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/24.10.2/targets/rockchip/armv8/kmods/
# https://mirrors.ustc.edu.cn/openwrt/releases/24.10.2/targets/rockchip/armv8/kmods/
# https://downloads.openwrt.org/releases/24.10.2/targets/rockchip/armv8/kmods/
# https://archive.openwrt.org/releases/24.10.2/targets/rockchip/armv8/kmods/
# https://mirrors.cqupt.edu.cn/openwrt/releases/24.10.2/targets/rockchip/armv8/kmods/
Releases_version=$(cat include/version.mk | sed -n 's|.*releases/\([0-9]\+\.[0-9]\+\.[0-9]\+\).*|\1|p')
url_value=$(wget -qO- "https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/${Releases_version}/targets/rockchip/armv8/kmods/")
hash_value=$(echo "$url_value" | sed -n 's/.*6\.6\.93-1-\([0-9a-f]\{32\}\)\/.*/\1/p' | head -1)
hash_value=${hash_value:-$(echo "$url_value" | sed -n 's/.*\([0-9a-f]\{32\}\)\/.*/\1/p' | head -1)}
if [ -n "$hash_value" ] && [[ "$hash_value" =~ ^[0-9a-f]{32}$ ]]; then
    echo "$hash_value" > .vermagic
    echo "kernel内核md5校验码：$hash_value"
fi

# 修改版本为编译日期，数字类型。
date_version=$(date +"%Y%m%d%H")
echo $date_version > version

# 为iStoreOS固件版本加上编译作者
author="kylin7226"
sed -i "s/DISTRIB_DESCRIPTION.*/DISTRIB_DESCRIPTION='%D %V ${date_version} by ${author}'/g" package/base-files/files/etc/openwrt_release
sed -i "s/OPENWRT_RELEASE.*/OPENWRT_RELEASE=\"%D %V ${date_version} by ${author}\"/g" package/base-files/files/usr/lib/os-release
