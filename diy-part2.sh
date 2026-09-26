#!/bin/sh
# DIY part2: 在 make defconfig 之后执行。
# 可在此追加自定义配置或预置 files/ 覆盖。示例:
#   echo 'CONFIG_TARGET_HOSTNAME="FanchmWrt"' >> .config
#   make defconfig
#   mkdir -p files/etc && echo '自定义文件' > files/etc/xxx
echo "diy-part2: 保持默认配置 (如需定制请编辑本文件)"
