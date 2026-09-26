# FanchmWrt · armsr/armv8 (ARM 虚拟机) 云端编译套件

基于 **FanchmWrt `fanchmwrt-25.12.4`** 分支（固件版本 **1.0.4**，OpenWrt 25.12 基础，内核 6.12），
编译出可在 **QEMU/KVM、Proxmox(ARM)、VMware Fusion(ARM)、Hyper-V(ARM)** 等虚拟机直接启动的
**Arm SystemReady EFI 磁盘镜像**。

> 本套件不依赖本机 Linux 环境，全部编译在 GitHub Actions 云端完成（约 1.5–3 小时，消耗你的 Actions 额度）。

---

## 文件说明

| 文件 | 作用 |
|------|------|
| `.github/workflows/build-openwrt.yml` | GitHub Actions 工作流：克隆源码 → 注入自定义 feeds → 装 feeds → 加载 `.config` → 编译 → 上传产物 |
| `feeds.conf` | 自定义 feeds 配置：在 FanchmWrt 原 feeds 基础上追加 `linkease/istore`（提供 iStore 应用商店） |
| `.config` | 编译目标配置：armsr/armv8 generic + EFI 镜像 + virtio 驱动 + LuCI + 全部 FanchmWrt 特色功能包 + **iStore / Docker / LXC / 5G 根分区** |
| `diy-part1.sh` / `diy-part2.sh` | 自定义扩展位（默认空，可按需添加补丁/预置文件） |
| `files/etc/uci-defaults/99-fanchmwrt-bypass` | **旁路模式默认网络配置**：首次启动写入 LAN 静态 IP `192.168.2.8`、关闭 LAN 侧 DHCP |

---

## 本次构建包含的特色能力

- **iStore 应用商店**：通过 `linkease/istore` feed 集成 `luci-app-store`，开机即可在 LuCI 里访问应用商店安装软件。
- **容器 - Docker**：`luci-app-dockerman` + `dockerd` + `docker`，ARM64 原生容器运行时。
- **容器 - LXC**：`luci-app-lxc` + `lxc` + `lxc-auto`，轻量级系统容器。
- **根分区 5G**：`CONFIG_TARGET_ROOTFS_PARTSIZE=5120`，镜像可用空间扩展到约 5GB（原默认 1GB）。
- **FanchmWrt 全家桶**：全部 `luci-app-fwx-*` 功能包（应用中心、应用过滤、仪表盘、流量统计、审计、用户管理等）。
- **旁路模式**：LAN 静态 IP `192.168.2.8`、关闭 LAN DHCP、网关指向上游 `192.168.2.1`。

> 注意：iStore 在编译时会从网络拉取预编译的前端 UI，需保证 GitHub Actions Runner 可访问外网（默认即可）。

---

## 一键部署步骤

1. **新建一个 GitHub 仓库**（建议公开仓库，公开仓库 Actions 免费额度更充足），例如 `fanchmwrt-armsr-build`。
2. 把本目录里的 **全部文件**（含 `.github/` 与 `files/` 整个目录）上传到仓库根目录。
3. 进入仓库 **Actions** 标签页 → 找到工作流 **Build FanchmWrt armsr/armv8 VM** → 点 **Run workflow**。
4. 等待编译完成（可在日志里看进度；失败时工作流会重试 `make -j1 V=s` 并打印详细错误）。
5. 完成后在 **Artifacts** 里下载 `FanchmWrt-armsr-armv8-<commit>` 压缩包。

---

## 编译产物（解压后）

目录 `bin/targets/armsr/armv8/` 内包含：

- `openwrt-armsr-armv8-generic-ext4-combined-efi.img.gz` ← **推荐**：可写 ext4 镜像，适合作为虚拟机系统盘
- `openwrt-armsr-armv8-generic-squashfs-combined-efi.img.gz` ← 只读 squashfs 镜像（适合升级/恢复）
- `openwrt-armsr-armv8-generic-combined-efi.vmdk` ← VMware 可直接使用
- `openwrt-armsr-armv8-generic-rootfs.tar.gz` ← 仅根文件系统，供自定义打包

解压：`gzip -d openwrt-armsr-armv8-generic-ext4-combined-efi.img.gz`

---

## 在虚拟机里启动

### QEMU/KVM (aarch64, UEFI/OVMF)
```bash
# 先解压得到 .img
qemu-system-aarch64 \
  -machine virt,virtualization=on,gic-version=3 \
  -cpu cortex-a72 -smp 4 -m 2048 \
  -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
  -drive file=openwrt-armsr-armv8-generic-ext4-combined-efi.img,if=virtio,format=raw \
  -device virtio-net-pci,netdev=net0 -netdev user,id=net0,hostfwd=tcp::8080-:80 \
  -nographic
```
启动后 Web 管理界面：`http://192.168.2.8/`（本构建已设为**旁路模式**，管理 IP 固定为 `192.168.2.8`）。

### Proxmox VE (ARM) / VMware Fusion (Apple Silicon)
新建「ARM 64 位」虚拟机，固件选 **UEFI (OVMF)**，把解压后的 `.img` 作为 **VirtIO 磁盘**挂载即可直接启动。

---

## 旁路模式（默认已启用）

本镜像默认以 **旁路模式**（旁挂防火墙 / 旁路网关）部署，适用于你已有一台主路由（如 iKuai、OpenWrt 主路由等）、希望把 FanchmWrt 作为二级过滤/管控设备接入的场景。

- 设备管理 IP：**`192.168.2.8`**（属于 `192.168.2.0/24` 网段；若与主路由不同网段，改 `files/etc/uci-defaults/99-fanchmwrt-bypass` 里的 `ipaddr`）
- 上游网关 / DNS：**`192.168.2.1`**（假设主路由是 `.1`；不是则改同文件里的 `gateway` / `dns`）
- LAN 侧 DHCP 服务：**已关闭**，避免与主路由抢地址

**典型接法**：把 FanchmWrt 虚拟机的网卡桥接到主路由的 LAN 网段（拿到 `192.168.2.8`）；需要走 FanchmWrt 过滤的内网终端，把网关/DNS 手动指向 `192.168.2.8` 即可，其余终端仍走主路由，互不影响。

> 若你想要「主路由模式」（FanchmWrt 直接做主网关），删除 `files/etc/uci-defaults/99-fanchmwrt-bypass` 后重新编译即可（或首次启动后在 Luci 里改回并删除该 uci-defaults 文件）。

---

## 常见问题

- **想改包/加功能**：编辑 `.config`（在对应 `CONFIG_PACKAGE_xxx=y` 行增删），或在 `diy-part2.sh` 里追加 `echo 'CONFIG_...=y' >> .config && make defconfig`。
- **想换分支/仓库**：改 `build-openwrt.yml` 顶部的 `REPO_URL` / `REPO_BRANCH` 环境变量（或手动触发时填 input）。
- **编译失败**：查看 Actions 日志末尾的 `make -j1 V=s` 详细输出，通常是某个包依赖缺失；把对应 `CONFIG_PACKAGE_*` 注释掉重试。
- **磁盘/时间**：云端构建已开启 `CONFIG_AUTOREMOVE` 与释放 Runner 冗余空间；本构建含 Docker/LXC/iStore，通常约 **2–4 小时**，仍远在 GitHub Actions 6 小时单任务额度内。
