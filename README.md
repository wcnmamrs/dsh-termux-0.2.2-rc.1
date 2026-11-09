# DSH Termux 自包含版 · 0.2.2-rc.1

> Unofficial, self-contained Termux/Android build of [DSH](https://github.com/deepseek-ai/dsh) `0.2.2-rc.1`.
> No symlinks, no external paths, arm64 only. Unpack and run.

基于 DeepSeek 官方 `@deepseek-ai/dsh@0.2.2-rc.1` 的 Termux 重打包版本，带 Android 适配补丁，**完全自包含**：所有依赖内联在包内，没有任何指向安装目录之外的软链，也没有硬编码路径。解压即可用，不需要 npm install。

---

## 特性

- **自包含**：0 个外部软链、0 处硬编码绝对路径，整棵树可放在任意目录
- **已打 Android 补丁**：文件锁、会话持久化硬链接、权限档 UI 等（见 [docs/PATCHES.md](docs/PATCHES.md)）
- **已裁剪**：724M → 549M（去掉 sourcemap、类型声明、各包 README、非 Android 预编译件）
- **离线可启动**：首次运行自动建 profile，不联网也能起 Web UI（装插件才需要网络）
- **无第三方插件**：干净官方默认 profile

## 环境要求

| 项 | 要求 |
|---|---|
| 系统 | Termux（F-Droid / GitHub 版均可） |
| 架构 | **aarch64 / arm64-v8a**（x86_64 模拟器不支持） |
| Node.js | **>= 24.9.0**（`pkg install nodejs`） |
| 磁盘 | 约 600 MB |
| 其他 | `curl`、`tar`、`zstd` |

原生模块（`require_builtin.node`、`koffi`、`node-pty`）只有 Android arm64 版本，这是架构限制。

## 安装

一条命令（自动下载 + 校验 + 安装）：

```sh
pkg install -y nodejs curl zstd
curl -fL -O https://github.com/wcnmamrs/dsh-termux-0.2.2-rc.1/releases/download/v0.2.2-rc.1/install.sh
sh install.sh
```

或者手动下载后安装：

```sh
curl -fL -O https://github.com/wcnmamrs/dsh-termux-0.2.2-rc.1/releases/download/v0.2.2-rc.1/dsh-portable.tar.zst
tar --zstd -xf dsh-portable.tar.zst
cd dsh-portable && sh install.sh
```

安装位置：`$PREFIX/lib/node_modules/dsh-portable`，并在 `$PREFIX/bin/dsh` 建立命令链接。

校验和（SHA-256）：

```
2e9613130bacfd14230c61d2bed9adc02be8d586dd85f851f2f7e20245d72168  dsh-portable.tar.zst
```

## 首次运行

```sh
dsh web
```

终端会打印形如 `http://127.0.0.1:3080/?token=...` 的地址，用手机浏览器打开，在设置里填入 DeepSeek API Key 即可。

也可以用环境变量（适合脚本 / 无 UI 场景）：

```sh
export DEEPSEEK_API_KEY=sk-xxxxxxxx
export DEEPSEEK_BASE_URL=https://api.deepseek.com   # 可选，自建网关时改这里
dsh web --port 3080 --no-open
```

配置与会话都保存在 `~/.dsh/` 下，升级或重装不影响。

## 常用命令

```sh
dsh --version                      # 0.2.2-rc.1
dsh web                            # 启动 Web UI（默认 3080）
dsh web --port 8080 --no-open      # 指定端口、不自动开浏览器
dsh web --host 127.0.0.1           # 绑定地址
dsh plugin --profile web add <包名> # 装插件（需要 pnpm）
```

装插件前需要：`pkg install -y pnpm`。

## 与官方 0.2.2-rc.1 的差异

| 方面 | 官方 | 本包 |
|---|---|---|
| 依赖形式 | 声明 90 个依赖，npm 安装 | 541 个依赖全量内联（`bundledDependencies`） |
| 包体 | 需联网安装 | 549M 离线可用 |
| Android 补丁 | 无 | 5 项（见 docs/PATCHES.md） |
| forge / liveshare / 推荐系统 | 有 | 未打包（移动端用不到） |
| 非 Android 预编译件 | 有 | 已剔除 |
| 第三方插件 | 无 | 无 |

核心功能（Agent、Web UI、ACP、Bash、文件工具、会话、子代理、目标、定时任务等）与官方一致。

## 卸载

```sh
rm -rf $PREFIX/lib/node_modules/dsh-portable
rm -f  $PREFIX/bin/dsh
rm -rf ~/.dsh        # 可选：连同配置和会话一起删除
```

## 许可

上游 DSH 为 MIT 许可，版权归 DeepSeek（`LICENSE`）。本仓库仅为 Termux/Android 适配的重打包，**非官方发布**，与 DeepSeek 无隶属关系。使用前请遵守上游许可与 DeepSeek 服务条款。
