# FanchmWrt 多版本云端编译套件 (x86 / ARM · 旁路 / 路由)

基于 **FanchmWrt `fanchmwrt-25.12.4`**（固件版本 1.0.4，OpenWrt 25.12 基础、内核 6.12）的云端编译配置。
一次 `workflow_dispatch` 通过 GitHub Actions 矩阵同时产出 **4 个固件版本**，均自带：

- **iStore 应用商店**（来自 `linkease/istore` feed，功能可用）
- **容器**：Docker（dockerman + dockerd + docker CLI）+ LXC（luci-app-lxc + lxc + lxc-auto）
- **根分区扩展至 5G**（`CONFIG_TARGET_ROOTFS_PARTSIZE=5120`）
- **全套 FanchmWrt 特色功能包**（`luci-app-fwx-*` 系列）
- **中文 LuCI + SSL**，并附 virtio 驱动（虚拟机友好，物理机无副作用）

## 产物矩阵

| 版本 (artifact 名前缀) | 架构 | 网络模式 | 默认 IP | DHCP | 典型用途 |
|---|---|---|---|---|---|
| `x86-64-bypass` | x86_64 | 旁路 | `192.168.2.8` | 关闭 | 旁挂防火墙 / 透明审计 |
| `x86-64-router` | x86_64 | 路由 | `192.168.3.1` | 开启(100–249) | 主路由 / 网关 |
| `armv8-bypass`  | armsr/armv8 (Arm SystemReady EFI) | 旁路 | `192.168.2.8` | 关闭 | ARM 虚拟机旁挂 / UEFI ARM 板 |
| `armv8-router`  | armsr/armv8 (Arm SystemReady EFI) | 路由 | `192.168.3.1` | 开启(100–249) | ARM 虚拟机主路由 |

> **关于"实体机安装"与"虚拟机"**：对 EFI 目标（x86_64 与 armsr/armv8）而言，同一份 `*-combined-efi.img.gz` 既能 `dd` 写入物理磁盘（UEFI 启动）当实体机用，也能作为 VirtIO/EFI 磁盘挂到虚拟机里跑。因此上面 4 个版本即同时满足"实体机安装"与"虚拟机"两种部署形态——无需为同一架构/模式重复构建。
> 若你有**特定 ARM 单板**（Raspberry Pi 4、Rockchip 等），那属于不同 target，需要单独加一个矩阵项，告诉我板型即可。

## 仓库文件说明

| 文件 | 作用 |
|---|---|
| `.github/workflows/build-openwrt.yml` | 矩阵工作流：克隆源码 → 装 feeds → 按 target 生成 `.config` → 注入 netmode → 编译 → 分版本上传 Artifact |
| `gen-config.sh` | 按 `x86_64` / `armv8` 生成基础 `.config`（含 5G 分区、EFI/镜像格式），再追加 `features.cfg` |
| `features.cfg` | 统一功能包（LuCI 中文、virtio、FanchmWrt 全家桶、iStore、Docker、LXC） |
| `feeds.conf` | FanchmWrt 原 feeds + **iStore feed**（在 `feeds update` 前注入源码树） |
| `netmode/bypass/etc/uci-defaults/99-netmode` | 旁路模式默认网络（IP 192.168.2.8、关 DHCP、网关指向上游 192.168.2.1） |
| `netmode/router/etc/uci-defaults/99-netmode` | 路由模式默认网络（IP 192.168.3.1、开 DHCP、WAN 走默认客户端+NAT） |
| `diy-part1.sh` / `diy-part2.sh` | 自定义扩展位（默认空，可加补丁/预置文件） |
| `run_build.py` | 一键编排：建仓库 → 上传套件 → 触发矩阵工作流 → 轮询状态 |

## 一键部署步骤（GitHub Actions 云端编译）

1. 新建一个 **GitHub 公开仓库**（本套件已发布在 `1074655144/fanchmwrt-armsr-build`），或 fork 后使用。
2. 进仓库 **Actions** → 选 **Build FanchmWrt (x86/ARM · bypass/router)** → **Run workflow**。
   - 也可在本机执行：`python3 run_build.py --token <你的PAT>`（需 `repo` + `workflow` 权限）。
3. 矩阵会并行产出 4 个构建任务，预计 **2–4 小时**完成（含 iStore/Docker/LXC，偏重）。
4. 在运行页 **Artifacts** 下载对应版本（保留 14 天），文件名形如 `FanchmWrt-x86-64-router-<commit>.zip`。

## 部署示例

### 虚拟机（QEMU/KVM / Proxmox / VMware / Hyper-V）
解压后把 `openwrt-*-generic-ext4-combined-efi.img.gz` 解压得到 `.img`，作为 **VirtIO / EFI 磁盘**挂载，固件选 **UEFI (OVMF)** 启动。
- x86_64 额外提供 `.vmdk` / `.qcow2` / `.vdi` 格式，可直接喂给 VMware / KVM / VirtualBox。

### 实体机（x86 小主机 / ARM 服务器板）
把 `*-combined-efi.img` 用 `dd` 写入目标磁盘（或 balenaEtcher 烧录到 U 盘/SSD），从 UEFI 启动即可。

### 旁路模式接线
旁路设备接在主路由同网段（如 `192.168.2.0/24`），管理地址 `192.168.2.8`，自身网关指向上游主路由 `192.168.2.1`，不抢占 DHCP。

### 路由模式接线
WAN 口接外网（DHCP 自动获取），LAN 口下发 `192.168.3.0/24`，内网网关 `192.168.3.1`，防火墙默认 NAT。

## 修改默认 IP / 网关

- 旁路网关不是 `192.168.2.1`：改 `netmode/bypass/etc/uci-defaults/99-netmode` 里的 `set network.lan.gateway='192.168.2.1'` 与 `dns` 两行。
- 路由 LAN 段不是 `192.168.3.0/24`：改 `netmode/router/.../99-netmode` 的 `ipaddr` 与 `dhcp.lan.start/limit`。
- 改完重新 Run workflow 即可（改动会随仓库文件被重新拉取）。

## 常见问题

- **iStore 编译失败（UI 下载/兼容）**：iStore 编译时会从网络拉取预构建前端，依赖 LuCI 兼容层（`luci-compat` 已勾选）。若个别版本变红，先单独重跑该矩阵项；仍不行可改用固定兼容的 istore commit（见 `feeds.conf` 注释处改 `^<commit>`）。
- **磁盘/时间**：已开启 `CONFIG_AUTOREMOVE` 并在 Runner 上释放冗余空间；完整构建（含容器/iStore）较吃资源，正常可在 6 小时额度内完成，但建议一次不要并发太多构建。
- **产物保留**：Actions Artifact 默认保留 14 天，请及时下载。
