# Android / Termux 适配补丁说明

本包在官方 `@deepseek-ai/dsh@0.2.2-rc.1` 基础上做了 5 处修改，全部位于包内 `node_modules` 或 `lib`，不改变任何业务逻辑，只为让它在 Android（bionic libc、无 flock、无硬链接权限）上能跑。

## 1. 文件锁：Android 直接跳过

`node_modules/@deepseek-ai/node-addon-system/lib/flock.js`

```diff
 export async function tryLockExclusive(fd) {
+    if (process.platform === 'android') return;
     const errno = await new Promise((resolve) => {
```

原因：Android 上 `flock(2)` 不可用/被 SELinux 拒绝，原生绑定会抛错导致进程启动失败。单用户单实例场景下跳过无副作用。

## 2. 会话持久化：硬链接改为复制/改名

`node_modules/@deepseek-ai/dsh-session-persistence-jsonl/lib/index.js`
`node_modules/@deepseek-ai/dsh-session-persistence-jsonl/lib/worker.cjs`

```diff
-    await internals.fs.link(staged, currentPath);
+    await internals.fs.copyFile(staged, currentPath, 1);
```

并新增 `linkOrCopyAndroid()`：先尝试 `copyFile(..., COPYFILE_EXCL)`，遇到 `EACCES/EPERM/EOPNOTSUPP/ENOSYS/EXDEV` 时退化为同目录 `rename()`（原子），同时保留 `EEXIST` 语义。

原因：Android 的 `/data` 分区（F2FS + SELinux）上 `link(2)` 返回 `EACCES`，导致会话写入失败。

## 3. 权限档 UI：隐藏 workspace-write

`node_modules/@deepseek-ai/dsh-client-ui-permission-presets/lib/client.js`

删除 `PRESET_LABEL_KEYS` 与 `permissionGlyphs` 中 `["workspace-write", …]` 两处条目。

原因：该档位依赖 workspace 沙箱能力，在 Termux 下不可用，隐藏以避免用户误选。

## 4. profile 模板导入修正

`lib/profile-boot-C14i-8IN.js`（以及 `lib/plugin-BiveYA7h.js`）

```diff
-import { PROFILE_TEMPLATES } from '@deepseek-ai/dsh-app-boot';
+import { PROFILE_TEMPLATES } from '@deepseek-ai/dsh-official-bundles';
```

原因：`dsh-app-boot` 实际并不导出 `PROFILE_TEMPLATES`，官方同样从 `dsh-official-bundles` 导入，属于修 bug。

## 5. 原生模块本地编译

`node_modules/node-addon-require-builtin/build/Release/require_builtin.node`
`node_modules/node-addon-require-builtin/build/napi/napi-v9-android-arm64/`

原因：npm 上该包只有 darwin/linux/win32 预编译件，Android 需自行编译（arm64）。

---

## 除补丁外的自包含化处理

- 原构建中有 3 个软链指向 `~/.dsh/profiles/web/node_modules/`（`dsh-bash-local`、`dsh-llm-deepseek`、`dsh-session-query`），已替换为实体副本，共 612K。
- 删除 sourcemap（4479 个，55M）、`.d.ts`（12870 个，84M）、各包 README（11M）、node-pty 的 darwin/win32/linux 预编译件与 conpty（25M）。
- 全树复查：0 个指向安装目录外的软链，0 处硬编码 `/data/data/com.termux` 路径。

## 已知限制

- 仅 arm64；x86_64 模拟器无法运行原生模块。
- 终端（node-pty）仅保留 android-arm64 预编译件，未在低版本 Android 上验证。
- 未包含 forge / liveshare / 推荐系统 / Office 文档（libreoffice-kit）等移动端用不到的组件。
