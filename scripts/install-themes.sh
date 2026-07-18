#!/usr/bin/env bash
# 将仓库内 themes/ 下的主题软链到 fcitx5 主题目录，并把默认主题设为 catppuccin_mocha。
# 用法：bash scripts/install-themes.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_DST="$HOME/.local/share/fcitx5/themes"
CLASSICUI_CONF="$HOME/.config/fcitx5/conf/classicui.conf"
DEFAULT_THEME="catppuccin_mocha"

mkdir -p "$THEME_DST"
for src in "$REPO_DIR"/themes/*/; do
  name="$(basename "$src")"
  ln -sfnT "$src" "$THEME_DST/$name"
  echo "已链接主题：$name"
done

mkdir -p "$(dirname "$CLASSICUI_CONF")"
# Theme 用于浅色模式，DarkTheme 用于深色模式（UseDarkTheme=True 时生效）。
# 仅在配置中不存在对应键时写入默认值；已有选择（含手动切换过的主题）一律保留。
for key in Theme DarkTheme; do
  if [[ ! -f "$CLASSICUI_CONF" ]] || ! grep -q "^$key=" "$CLASSICUI_CONF"; then
    printf '%s=%s\n' "$key" "$DEFAULT_THEME" >>"$CLASSICUI_CONF"
    echo "首次安装：$key 设为 $DEFAULT_THEME"
  fi
done
echo "当前生效主题：$(grep -E '^(Theme|DarkTheme)=' "$CLASSICUI_CONF" | tr '\n' ' ')（切换见 README）"

if command -v fcitx5-remote >/dev/null 2>&1; then
  fcitx5-remote -r || true
  echo "已通知 fcitx5 重载配置"
fi
