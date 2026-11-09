#!/data/data/com.termux/files/usr/bin/sh
# DSH Termux 自包含版 · 在线安装脚本
# 用法: sh install.sh
set -e

REPO="wcnmamrs/dsh-termux-0.2.2-rc.1"
TAG="${DSH_TAG:-v0.2.2-rc.1}"
ASSET="dsh-portable.tar.zst"
SHA256="2e9613130bacfd14230c61d2bed9adc02be8d586dd85f851f2f7e20245d72168"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
WORK="${TMPDIR:-$HOME/tmp}/dsh-install.$$"

say() { printf '%s\n' "$*"; }
die() { printf '错误: %s\n' "$*" >&2; exit 1; }

# ---- 环境检查 ----
[ -d "$PREFIX" ] || die "未找到 \$PREFIX ($PREFIX)，这不是 Termux 环境？"
case "$(uname -m)" in
  aarch64|arm64|armv8*) ;;
  *) die "需要 aarch64 架构，当前 $(uname -m)。原生模块只有 arm64 版本。" ;;
esac
command -v node >/dev/null 2>&1 || die "未安装 Node.js，请先执行: pkg install nodejs"
NODE_MAJOR=$(node -p "process.versions.node.split('.')[0]")
NODE_MINOR=$(node -p "process.versions.node.split('.')[1]")
if [ "$NODE_MAJOR" -lt 24 ] || { [ "$NODE_MAJOR" -eq 24 ] && [ "$NODE_MINOR" -lt 9 ]; }; then
  die "需要 Node.js >= 24.9.0，当前 $(node -v)"
fi

if ! command -v zstd >/dev/null 2>&1; then
  say "未找到 zstd，正在安装..."
  pkg install -y zstd >/dev/null 2>&1 || die "zstd 安装失败，请手动执行: pkg install zstd"
fi

# ---- 下载 ----
URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT INT TERM

say "下载 $URL"
if command -v curl >/dev/null 2>&1; then
  curl -fL --retry 3 -o "$WORK/$ASSET" "$URL" || die "下载失败"
else
  wget -O "$WORK/$ASSET" "$URL" || die "下载失败"
fi

say "校验 SHA-256 ..."
ACTUAL=$(sha256sum "$WORK/$ASSET" | cut -d' ' -f1)
[ "$ACTUAL" = "$SHA256" ] || die "校验失败（期望 $SHA256，实际 $ACTUAL）"

# ---- 解包安装 ----
say "解包 ..."
tar --zstd -xf "$WORK/$ASSET" -C "$WORK" || die "解包失败"
[ -d "$WORK/dsh-portable" ] || die "压缩包结构异常"
sh "$WORK/dsh-portable/install.sh"

say ""
say "安装完成。启动: dsh web"
say "首次运行会创建 ~/.dsh 配置目录。"
