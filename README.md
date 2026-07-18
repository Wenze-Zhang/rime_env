# rime_env — 个人 Rime 输入法配置（Ubuntu + fcitx5）

精简自 [Mintimate/oh-my-rime](https://github.com/Mintimate/oh-my-rime)（薄荷输入法），只保留一个输入方案：
**薄荷拼音-小鹤混输（`rime_mint_flypy`）** —— 全拼与小鹤双拼可同时使用。

主词库为[万象拼音词库](https://github.com/amzxyz/rime_wanxiang)基础版（上游机器人每月自动同步），
另含：英文词库、中英混输、颜文字（`VV`）、纠错词库、emoji、错音提示、
日期/农历/计算器等 lua 功能、拆字反查（`Uu`）、Unicode 输入（`Uc`）。
已裁剪：五笔反查（Uw）、笔画反查（Ui）及其词库。

## 目录结构（两层模型）

| 层 | 内容 | 更新方式 |
|---|---|---|
| 自动更新层 | `default.yaml`、`rime_mint.dict.yaml`、`melt_eng.*`、`radical_pinyin.*`、`symbols.yaml`、`rime.lua`、`lua/`、`opencc/`、`dicts/`（除 custom_simple） | `scripts/update-upstream.sh` 整文件覆盖 |
| 用户层 | `rime_mint_flypy.schema.yaml`（已裁剪，冻结）、`*.custom.yaml`、`dicts/custom_simple.dict.yaml`、`themes/`、`scripts/`、本 README | 只由自己修改，脚本永不触碰 |

机器本地数据（`build/`、`*.userdb/`、`user.yaml`、`installation.yaml`、`sync/`、`trash/`）已被 .gitignore 忽略。

## 常用操作

```bash
# 同步上游词库/lua/opencc（建议每 1~2 个月一次；上游改名会报错中止，按提示修清单）
bash scripts/update-upstream.sh

# 安装/重装主题软链，并把默认主题设为 catppuccin_mocha
bash scripts/install-themes.sh
```

改完任何配置后需**重新部署**：fcitx5 托盘图标右键 → 重新部署（或重启 fcitx5）。

## 个人定制入口

- 全局（候选词数、方案列表等）：`default.custom.yaml`
- 方案级（模糊音、开关默认值等）：`rime_mint_flypy.custom.yaml`
- 自定义词：`dicts/custom_simple.dict.yaml`（格式：`词语<Tab>拼音<Tab>权重`）

## 主题

vendor 于 `themes/`，经 `install-themes.sh` 软链到 `~/.local/share/fcitx5/themes/`：

- `catppuccin_mocha`（默认）— 来自 [catppuccin/fcitx5](https://github.com/catppuccin/fcitx5)（Mocha/Mauve）
- `nord-dark` — 来自 [tonyfettes/fcitx5-nord](https://github.com/tonyfettes/fcitx5-nord)

切换：`fcitx5-configtool` → 附加组件 → 经典用户界面 → 主题。

## 新机器部署

```bash
sudo apt install fcitx5 fcitx5-rime fcitx5-chinese-addons
git clone git@github.com:Wenze-Zhang/rime_env.git ~/.local/share/fcitx5/rime
bash ~/.local/share/fcitx5/rime/scripts/install-themes.sh
# 注销重登 → fcitx5 就绪
```

## 备忘

- 恢复纯全拼：从上游取回 `rime_mint.schema.yaml`，并在 `default.custom.yaml` 的
  `schema_list` 加 `- schema: rime_mint`，重新部署即可。
- 回滚本次重构前状态：`git checkout pre-restructure -- .` + 重新部署。
- 配置源自 oh-my-rime（GPL-3.0，见 LICENSE）；词库版权归各上游项目。
