# 操作指南

## 项目架构

本项目基于 GitHub Actions 编译 iStoreOS 固件，采用**分层覆盖**配置方案：

```
上游 koolcenter config.buildinfo  (完整配置, ~878行)
        ↓
+ config_data-6.x.txt             (差异覆盖, 只写变更)
        ↓
  合并去重 → armv8/.config
        ↓
  make defconfig (最后一行生效)
        ↓
   最终编译配置
```

## 一、同步上游

### 自动同步

`Sync Files` 工作流每天 `23:55` (北京时间) 自动执行：
1. 从 koolcenter 下载上游 `config.buildinfo` 和 `feeds.conf`
2. 将 `configfiles/config_data-6.x.txt` 追加到 `.config` 末尾
3. 去重后提交到 main 分支

> OpenWrt 的 `make defconfig` 以 `.config` 文件中**最后一行**为准，所以 `config_data-6.x.txt` 中的配置会覆盖上游的相同项。

### 手动同步

进入 Actions → `Sync Files` → **Run workflow** → 选择分支 → 运行。

## 二、如何自定义软件包

### 2.1 删除上游自带的包

**原理**：在 `configfiles/config_data-6.x.txt` 中将对应配置项设为 `=n`，因为该文件会追加到上游 `.config` 末尾，OpenWrt `make defconfig` 以最后一行为准，从而实现覆盖。

**操作步骤**：

**第 1 步：查找上游包名**

方法一：查看上游同步生成的 `armv8/.config` 文件，搜索你要删的包关键词。
```bash
grep 'ddns' armv8/.config
```

方法二：直接访问上游 koolcenter 查看完整配置：
```
https://fw0.koolcenter.com/iStoreOS/easepi-r1/config.buildinfo
```

**第 2 步：写入删除配置**

在 `configfiles/config_data-6.x.txt` 中添加 `=n`：

```
# ===== 删除的包 =====
# 删除 ddns 相关
CONFIG_PACKAGE_ddns-scripts=n
CONFIG_PACKAGE_ddns-scripts-cloudflare=n
CONFIG_PACKAGE_ddns-scripts-dnspod=n
CONFIG_PACKAGE_ddns-scripts-services=n
CONFIG_PACKAGE_ddns-scripts_aliyun=n
CONFIG_PACKAGE_luci-app-ddns=n
CONFIG_PACKAGE_luci-i18n-ddns-zh-cn=n

# 删除 ddnsto 相关
CONFIG_PACKAGE_ddnsto=n
CONFIG_PACKAGE_luci-app-ddnsto=n
CONFIG_PACKAGE_luci-i18n-ddnsto-zh-cn=n
```

> **注意**：一个功能通常有多个相关包（主包、luci界面、中文翻译、依赖库等），建议全部设为 `=n`，避免残留。

### 2.2 添加自定义软件包

添加第三方包需要**两步**：

**第 1 步：克隆插件仓库到 `diy-part2-6.x.sh`**

在 `diy-part2-6.x.sh` 末尾添加 clone 语句：

```bash
# 集成homeproxy（通过 small 源自动获取，无需手动 clone）
# src-git small https://github.com/kenzok8/small
```

> `--depth=1` 表示只拉最新的一个 commit，加快克隆速度。

**第 2 步：在 `config_data-6.x.txt` 中启用**

```
CONFIG_PACKAGE_luci-app-homeproxy=y
CONFIG_PACKAGE_sing-box=y
CONFIG_PACKAGE_ucode-mod-digest=y
```

> 如果该包有依赖（如 luci 界面、i18n 翻译），也需要一并启用。具体包名可查阅插件仓库的 README 或 Makefile。

### 2.3 替换包（删除旧包 + 添加新包）

以替换 ddns 为例：

```
# config_data-6.x.txt

# 删除旧 ddns
CONFIG_PACKAGE_ddns-scripts=n
CONFIG_PACKAGE_ddns-scripts_aliyun=n
CONFIG_PACKAGE_luci-app-ddns=n
CONFIG_PACKAGE_luci-i18n-ddns-zh-cn=n

# 添加新 homeproxy
CONFIG_PACKAGE_luci-app-homeproxy=y
CONFIG_PACKAGE_sing-box=y
CONFIG_PACKAGE_ucode-mod-digest=y
```

```bash
# diy-part1-6.x.sh (通过 kenzo 源自动获取，无需手动 clone)
# src-git kenzo https://github.com/kenzok8/openwrt-packages
```

### 2.4 批量删除同类包

如果要批量删除同一类的包（比如所有 WiFi 驱动），可以用 grep 从上游 `.config` 中提取所有相关包名：

```bash
# 查找所有 WiFi 相关的包
grep -E 'mt76|rtl|rtw|iwlwifi|brcm|hostapd|wpa' armv8/.config | grep '=y'
```

然后将输出结果中的 `=y` 改为 `=n`，粘贴到 `config_data-6.x.txt` 中。

### 2.5 验证配置是否生效

同步完成后，检查 `armv8/.config` 中每个包名是否只有一行且值为你设置的值：

```bash
grep 'ddns' armv8/.config
```

应该只看到 `=n` 或 `=y`，不应出现重复行。如果同一个包出现多次，最后一行的值才是最终生效的值（当前 sync-files 已做去重处理）。

### 现有自定义包

| 包 | 来源 | 说明 |
|---|---|---|
| `luci-theme-argon` | kenzok8/openwrt-packages | Argon 主题 |
| `luci-app-argon-config` | kenzok8/openwrt-packages | Argon 主题配置（含中文） |
| `luci-theme-glass` | kenzok8/openwrt-packages | Glass 透明主题 |
| `luci-theme-design` | kenzok8/openwrt-packages | Design 主题 |
| `luci-app-design-config` | kenzok8/openwrt-packages | Design 主题配置（含中文） |
| `luci-app-homeproxy` | kenzok8/small | HomeProxy代理平台 |
| `luci-app-eqosplus` | sirpdboy/luci-app-eqosplus | 定时限速插件 |
| `default-settings` | xiaomeng9597/istoreos-settings | iStoreOS 设置 |

## 三、目标设备管理

### 当前目标设备

仅保留 `cyber_cyber3588-aib` 一个设备。

### 上游新增设备时

当上游 istoreos 新增设备时，sync-files 会自动把它加入 `.config`。需要在 `config_data-6.x.txt` 中排除：

```
# 排除新设备
CONFIG_TARGET_DEVICE_rockchip_armv8_DEVICE_xxx=n
```

### 如何找到设备名

查看上游仓库 `target/linux/rockchip/image/legacy.mk` 中的 `define Device/xxx` 名称，或查看上游 `config.buildinfo` 中 `CONFIG_TARGET_DEVICE_*` 的值。

## 四、编译固件

### 手动触发

编译已改为**手动触发**，不再定时自动编译：

1. 进入仓库 → **Actions** → **Build iStore OS 6.x**
2. 点击 **Run workflow** → 选择分支 → **Run workflow**

### SSH 调试

触发编译时可勾选 `SSH connection to Actions`，编译过程中会通过 SSH 连接远程调试（需要配置 `TELEGRAM_CHAT_ID` 和 `TELEGRAM_BOT_TOKEN` secrets）。

### 修改编译源码分支

编辑 `.github/workflows/build-istoreos-6.x.yml` 中的 `REPO_BRANCH`：

```yaml
REPO_BRANCH:
  - istoreos-24.10    # 当前使用的分支
```

## 五、配置文件说明

| 文件 | 用途 |
|---|---|
| `configfiles/config_data-6.x.txt` | 差异覆盖配置（增删软件包） |
| `armv8/.config` | 完整编译配置（由 sync-files 自动合并生成） |
| `armv8/feeds.conf` | 软件源配置（由 sync-files 自动同步） |
| `diy-part1-6.x.sh` | 编译前预处理（内核 MD5 校验码） |
| `diy-part2-6.x.sh` | 编译前自定义（端口、插件克隆、IP 修改） |

## 六、已修改的内容汇总

| 项目 | 变更 |
|---|---|
| 目标设备 | 仅 `cyber_cyber3588-aib`，其他全部禁用 |
| WiFi 相关 | 所有驱动（mt76/rtw/rtl/iwlwifi/brcmfmac）、固件、工具全部禁用 |
| DDNS | 删除上游 ddns-scripts/ddnsto |
| OAF/Appfilter | 已禁用 |
| 默认 IP | 192.168.199.1（原 192.168.100.1） |
| uhttpd 端口 | :64880 / :64443（原 :80 / :443） |
| 编译触发 | 手动触发（已移除定时任务） |
| Release 清理 | 已移除自动删除旧固件和工作流记录 |
| NPU | 上游已处理好，无需手动干预 |

## 七、常见问题

**Q: 同步后 armv8/.config 被覆盖了怎么办？**

A: `.config` 是由 sync-files 自动生成的，不要直接修改。所有自定义写入 `configfiles/config_data-6.x.txt`。

**Q: 如何确认我的配置是否生效？**

A: 编译日志中执行 `make defconfig` 时会展开配置。可以在 Actions 运行日志中查看。

**Q: 上游内核更新导致 .vermagic 校验失败？**

A: `diy-part1-6.x.sh` 会自动从 ustc 镜像站获取新内核的 MD5 校验码。
