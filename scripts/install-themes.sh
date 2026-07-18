#!/usr/bin/env bash
# 将仓库内 themes/ 下的主题软链到 fcitx5 主题目录，并把默认主题设为 catppuccin-mocha。
# 用法：bash scripts/install-themes.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_DST="$HOME/.local/share/fcitx5/themes"
CLASSICUI_CONF="$HOME/.config/fcitx5/conf/classicui.conf"
DEFAULT_THEME="catppuccin-mocha"

mkdir -p "$THEME_DST"
for src in "$REPO_DIR"/themes/*/; do
  name="$(basename "$src")"
  ln -sfnT "$src" "$THEME_DST/$name"
  echo "已链接主题：$name"
done

mkdir -p "$(dirname "$CLASSICUI_CONF")"
# Theme 用于浅色模式，DarkTheme 用于深色模式（UseDarkTheme=True 时生效），两者都指向默认主题
for key in Theme DarkTheme; do
  if [[ -f "$CLASSICUI_CONF" ]] && grep -q "^$key=" "$CLASSICUI_CONF"; then
    sed -i "s/^$key=.*/$key=$DEFAULT_THEME/" "$CLASSICUI_CONF"
  else
    printf '%s=%s\n' "$key" "$DEFAULT_THEME" >>"$CLASSICUI_CONF"
  fi
done
echo "默认主题已设为：$DEFAULT_THEME（可在 fcitx5-configtool → 附加组件 → 经典用户界面 中切换）"

if command -v fcitx5-remote >/dev/null 2>&1; then
  fcitx5-remote -r || true
  echo "已通知 fcitx5 重载配置"
fi
