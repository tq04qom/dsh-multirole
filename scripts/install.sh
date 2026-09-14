#!/usr/bin/env bash
# dsh-multirole preset 安装脚本（Git Bash）
# DSH preset 发现机制 = 「创作即复制」：复制到 user 根 <dshHome>/.agent-presets/ 即被扫描。
#
# 用法：
#   bash scripts/install.sh                # 正式安装：G1 机判（version 不得带 -dev/-rc 后缀）+ 覆盖前自动备份 + 生成 .installed-version
#   bash scripts/install.sh --force       # 已存在时强制覆盖
#   bash scripts/install.sh --target dev   # 装入开发沙箱 multirole-dev：无闸口、无备份、无需 --force，preset name 改写为「多角色协作模式（开发版）」
# 幂等性：脚本可重复执行。prod 走「先备份后覆盖」，备份最多保留 3 份；dev 为沙箱幂等覆盖。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$PROJECT_ROOT/dsh-multirole/agent-presets/multirole"
PKG_JSON="$PROJECT_ROOT/dsh-multirole/package.json"
DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"
DST="$DSH_HOME_DIR/.agent-presets/multirole"
DST_DEV="$DSH_HOME_DIR/.agent-presets/multirole-dev"
BACKUP_ROOT="$DSH_HOME_DIR/backups/multirole"
KEEP_BACKUPS=3

# ---------- 参数解析 ----------
TARGET="prod"
FORCE=0
PENDING=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --target) PENDING=1 ;;
    dev|prod)
      if [ "$PENDING" -eq 1 ]; then
        TARGET="$arg"
        PENDING=0
      else
        echo "FATAL: '$arg' 必须跟在 --target 之后（用法：install.sh [--force] [--target dev|prod]）" >&2
        exit 1
      fi
      ;;
    *)
      echo "FATAL: 未知参数: $arg（用法：install.sh [--force] [--target dev|prod]）" >&2
      exit 1
      ;;
  esac
done
if [ "$PENDING" -eq 1 ]; then
  echo "FATAL: --target 缺少目标值（dev|prod）" >&2
  exit 1
fi

if [[ ! -f "$SRC/preset.yml" ]]; then
  echo "FATAL: 源目录缺少 preset.yml：$SRC" >&2
  exit 1
fi

# ---------- --target dev：开发沙箱安装（无闸口、无备份、无需 --force） ----------
if [ "$TARGET" = "dev" ]; then
  mkdir -p "$(dirname "$DST_DEV")"
  if [[ -e "$DST_DEV" ]]; then
    rm -rf "$DST_DEV"
  fi
  cp -r "$SRC" "$DST_DEV"
  # 改写 preset name 为开发版（铁律：开发版永不作为正式入口）
  sed -i '0,/^name:/s//name: 多角色协作模式（开发版）/' "$DST_DEV/preset.yml"
  echo "已安装开发沙箱 preset：$DST_DEV（name=多角色协作模式（开发版））"
  echo "提醒：开发版仅作沙箱入口，永不作为正式入口（正式入口 = multirole，须过三闸口）。"
  exit 0
fi

# ================= 正式安装（prod） =================

# ---------- G1 机判：version 后缀合规（带 -dev/-rc 即 FATAL 退出） ----------
VERSION="$(sed -n 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PKG_JSON" | head -n1)"
if [ -z "$VERSION" ]; then
  echo "FATAL: 无法从 $PKG_JSON 读取 version 字段" >&2
  exit 1
fi
case "$VERSION" in
  *-dev|*-rc)
    echo "FATAL [G1]: version=$VERSION 带 -dev/-rc 后缀，不得发布。请升版为无后缀正式版本后再安装。" >&2
    exit 1
    ;;
esac
echo "G1 通过：version=$VERSION"
# 注：闸口 1 的另两项（版本大于部署位 .installed-version、S1/S2 冒烟通过）为总控/人在裁决包中的核对项，
# install.sh 仅承担 -dev/-rc 后缀机判。

if [[ -e "$DST" && "$FORCE" -eq 0 ]]; then
  echo "已存在：$DST（用 --force 覆盖）" >&2
  exit 1
fi

# ---------- 自动备份：rm -rf 前将部署位整体复制到 $BACKUP_ROOT，保留最近 $KEEP_BACKUPS 份 ----------
if [[ -d "$DST" ]]; then
  OLD_VERSION="unknown"
  if [[ -f "$DST/.installed-version" ]]; then
    V_LINE="$(grep '^version=' "$DST/.installed-version" | head -n1 || true)"
    V_VAL="${V_LINE#version=}"
    if [[ -n "$V_VAL" ]]; then
      OLD_VERSION="$V_VAL"
    fi
  fi
  TS="$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_ROOT"
  cp -r "$DST" "$BACKUP_ROOT/${OLD_VERSION}-${TS}"
  echo "已备份：$BACKUP_ROOT/${OLD_VERSION}-${TS}"
  # 修剪旧备份：按目录 mtime 保留最近 $KEEP_BACKUPS 份（依赖 GNU find -printf，Git Bash 自带）
  find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' \
    | sort -rn | tail -n +"$((KEEP_BACKUPS + 1))" | cut -d' ' -f2- | while IFS= read -r old; do
      if [[ -n "$old" ]]; then
        echo "清理旧备份：$old"
        rm -rf "$old"
      fi
    done
fi

# ---------- 覆盖安装 ----------
mkdir -p "$(dirname "$DST")"
rm -rf "$DST"
cp -r "$SRC" "$DST"

# ---------- 生成 .installed-version（三行：version / installed_at / source） ----------
{
  echo "version=$VERSION"
  echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "source=$PROJECT_ROOT"
} > "$DST/.installed-version"

echo "已安装 preset：$DST（version=$VERSION）"
echo "下一步：重启 DSH → 新建会话选「多角色协作模式」→ Web 设置 → 插件 → Subagent Model Selection 勾选顾问/执行者可用模型。"
