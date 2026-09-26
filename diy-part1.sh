#!/bin/sh
# DIY part1: 在 feeds update/install 之前执行 (此处无需修改即可编出标准镜像)
# 如需引入额外 feed 或对源码打补丁, 可在此添加, 例如:
#   echo "src-git myfeed https://github.com/xxx/myfeed" >> feeds.conf.default
#   ./scripts/feeds update myfeed
echo "diy-part1: 使用仓库自带 feeds.conf.default, 无需额外处理"
