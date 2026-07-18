#!/usr/bin/env bash
# 从上游 Mintimate/oh-my-rime 拉取「自动更新层」文件（词库/lua/opencc 等）。
# 用法：bash scripts/update-upstream.sh   （建议每 1~2 个月手动执行一次）
#
# 设计约定：
#   - 只覆盖下方 FILES/DIRS 清单内的文件（自动更新层）；
#   - 方案文件 rime_mint_flypy.schema.yaml 已裁剪并冻结在用户层，不在清单内；
#   - custom 文件、themes/、scripts/、README 等用户层内容永不触碰；
#   - 若上游改名导致清单中的路径不存在，脚本会列出缺失项并中止（不做部分覆盖），
#     届时请人工对照上游仓库修订此清单。
#
# 恢复纯全拼的方法（备忘）：从上游取回 rime_mint.schema.yaml 放入仓库根目录，
# 并在 default.custom.yaml 的 schema_list 中加一行 `- schema: rime_mint`。
set -euo pipefail

UPSTREAM_TARBALL="https://github.com/Mintimate/oh-my-rime/archive/refs/heads/main.tar.gz"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 自动更新层：单个文件
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

# 自动更新层：整个目录（先删后拷，跟随上游增删文件）
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
