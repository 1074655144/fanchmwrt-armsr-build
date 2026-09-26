#!/bin/sh
# 按目标平台生成 OpenWrt 基础 .config, 再追加统一功能包 (features.cfg)
# 用法: ./gen-config.sh <x86_64|armv8> <features.cfg 绝对路径>
set -e
TARGET="$1"
FEAT="$2"

if [ -z "$TARGET" ] || [ -z "$FEAT" ]; then
  echo "用法: $0 <x86_64|armv8> <features.cfg>" >&2
  exit 1
fi

cd openwrt

case "$TARGET" in
  x86_64)
    cat > .config <<'EOF'
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_x86_64_DEVICE_generic=y
CONFIG_TARGET_ROOTFS_PARTSIZE=5120
CONFIG_EFI_IMAGES=y
CONFIG_TARGET_IMAGES_GZIP=y
CONFIG_VMDK_IMAGES=y
CONFIG_QCOW2_IMAGES=y
CONFIG_VDI_IMAGES=y
CONFIG_TARGET_ROOTFS_EXT4FS=y
CONFIG_TARGET_EXT4FS_JOURNAL=y
CONFIG_TARGET_ROOTFS_SQUASHFS=y
EOF
    ;;
  armv8)
    cat > .config <<'EOF'
CONFIG_TARGET_armsr=y
CONFIG_TARGET_armsr_armv8=y
CONFIG_TARGET_armsr_armv8_DEVICE_generic=y
CONFIG_TARGET_ROOTFS_PARTSIZE=5120
CONFIG_EFI_IMAGES=y
CONFIG_TARGET_IMAGES_GZIP=y
CONFIG_VMDK_IMAGES=y
CONFIG_QCOW2_IMAGES=y
EOF
    ;;
  *)
    echo "未知目标平台: $TARGET" >&2
    exit 1
    ;;
esac

make defconfig
cat "$FEAT" >> .config
make defconfig
echo ">>> 已生成 .config (target=$TARGET)"
