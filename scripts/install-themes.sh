#!/usr/bin/env bash
# symlink repo themes into the fcitx5 theme directory
# usage bash scripts/install-themes.sh
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
# Theme is for light mode DarkTheme for dark mode when UseDarkTheme is true
# write defaults only when keys are missing keep existing choices
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
