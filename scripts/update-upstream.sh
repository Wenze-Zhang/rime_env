#!/usr/bin/env bash
# pull auto layer files dicts lua opencc from upstream oh-my-rime
# usage bash scripts/update-upstream.sh recommended every one or two months
#
# rules
#   only paths listed in FILES and DIRS below are overwritten
#   schema file rime_mint_flypy.schema.yaml is trimmed and frozen in user layer
#   custom files themes scripts and README are never touched
#   missing upstream paths abort the run with a list so update the manifest manually
#
# to restore plain full pinyin fetch rime_mint.schema.yaml from upstream
# and add schema rime_mint to schema_list in default.custom.yaml
set -euo pipefail

UPSTREAM_TARBALL="https://github.com/Mintimate/oh-my-rime/archive/refs/heads/main.tar.gz"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# auto layer single files
FILES=(
  default.yaml
  rime_mint.dict.yaml
  melt_eng.schema.yaml
  melt_eng.dict.yaml
  radical_pinyin.schema.yaml
  radical_pinyin.dict.yaml
  symbols.yaml
  rime.lua
  LICENSE
  dicts/rime_mint.chars.dict.yaml
  dicts/rime_mint.base.dict.yaml
  dicts/rime_mint.correlation.dict.yaml
  dicts/rime_mint.compatible.dict.yaml
  dicts/rime_mint.ext.dict.yaml
  dicts/rime_ice.others.dict.yaml
  dicts/rime_ice.cn_en_flypy.txt
  dicts/rime_ice.en.dict.yaml
  dicts/rime_ice.en_ext.dict.yaml
  dicts/other_kaomoji.dict.yaml
)

# auto layer whole directories removed then copied to follow upstream changes
DIRS=(
  lua
  opencc
)

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> 下载上游 main 分支……"
curl -fsSL "$UPSTREAM_TARBALL" -o "$WORK/omr.tar.gz"
mkdir -p "$WORK/omr"
tar -xzf "$WORK/omr.tar.gz" -C "$WORK/omr" --strip-components=1

echo "==> 校验清单……"
missing=()
for f in "${FILES[@]}"; do
  [[ -f "$WORK/omr/$f" ]] || missing+=("$f")
done
for d in "${DIRS[@]}"; do
  [[ -d "$WORK/omr/$d" ]] || missing+=("$d/")
done
if ((${#missing[@]})); then
  echo "!! 上游已不存在以下路径（可能改名/重构），已中止，未做任何修改：" >&2
  printf '   - %s\n' "${missing[@]}" >&2
  echo "   请对照 https://github.com/Mintimate/oh-my-rime 修订本脚本的清单。" >&2
  exit 1
fi

echo "==> 覆盖自动更新层文件……"
for f in "${FILES[@]}"; do
  install -D -m 644 "$WORK/omr/$f" "$REPO_DIR/$f"
done
for d in "${DIRS[@]}"; do
  rm -rf "${REPO_DIR:?}/$d"
  cp -r "$WORK/omr/$d" "$REPO_DIR/$d"
done

echo "==> 完成。变更概览："
git -C "$REPO_DIR" status --short
cat <<'EOF'

后续步骤：
  1. git diff 过目一下变更；
  2. 重新部署 rime（fcitx5 托盘图标右键 → 重新部署，或重启 fcitx5）；
  3. 确认输入正常后提交：git add -A && git commit -m "chore: sync upstream dicts"
EOF
