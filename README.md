# dsh-multirole

Multi-role collaboration plugin for [DSH (DeepSeek Harness)](https://github.com/deepseek-ai/deepseek-harness).

DSH 多角色协作模式插件。

---

## 简介 / Overview

**中文**：四层角色架构（人/顾问/总控/执行者）+ 任务单制度 + 写入域互斥 + 授权模式 + 裁决日志，让大模型协作开发可控、可复用。

**English**: Four-layer role architecture (Human/Advisor/Orchestrator/Executor) with task manifests, write-set isolation, authorization modes, and audit logging — making LLM team development controllable and reusable.

---

## 核心机制 / Core Mechanisms

| 机制 | 中文 | English |
|---|---|---|
| 角色架构 | 人（总裁决）/ 顾问（总设计）/ 总控（调度验收）/ 执行者（批量执行） | Human (arbiter) / Advisor (designer) / Orchestrator (dispatch & verify) / Executor (batch) |
| 任务单制度 | 一切派发落盘为自包含任务单，跨会话唯一事实源 | Every dispatch lands as a self-contained task file — single source of truth |
| 写入域互斥 | 并行任务写入域两两不相交 | Parallel tasks have pairwise disjoint write domains |
| 授权模式 | 标准模式（报人签字）/ 全授权模式（授权书 + 顾问裁决 + 预算闸口） | Standard (human signs) / Full delegation (charter + advisor arbitration + budget breaker) |
| 验收闭环 | 总控亲验 + 裁决包报人，人只做一分钟判断 | Orchestrator verifies + decision package to human — one minute per decision |
| 发布闸口 | 版本合规 + CHANGELOG + 人点头 | Version compliance + CHANGELOG + human approval |

---

## 安装 / Install

```bash
git clone https://github.com/tq04qom/dsh-multirole.git
cd dsh-multirole
bash scripts/install.sh
```

装完重启 DSH，新建会话时 preset 选择器选「多角色协作模式」。

After install, restart DSH and select "多角色协作模式" from the preset picker when creating a new session.

### 沙箱安装（开发验证）/ Sandbox Install

```bash
bash scripts/install.sh --target dev
```

装入 `multirole-dev`，preset name 显示为「多角色协作模式（开发版）」，无闸口、不覆盖正式版。

---

## 快速上手 / Quick Start

新建 DSH 会话，选「多角色协作模式」preset，然后粘贴以下话术：

Create a new DSH session, select the "多角色协作模式" preset, then paste:

```
你是本项目的总控。项目根：<换成你的项目绝对路径>。
开工动作：
1. 用 skill 工具加载 orchestration，通读流转协议。
2. 在项目根创建 任务单\ 和 logs\ 目录。
3. 把 <dshHome>\.agent-presets\multirole\skills\orchestration\ 下的
   任务单模板.md、授权书模板.md、裁决日志模板.md 复制到 任务单\ 目录备用。
4. pwd 自证工作目录，ls 自证全部落位。
完成后报告目录结构，然后停等我的第一个目标。
授权模式：标准（一切方向性决策与验收终审报我）。
```

更多话术见 `dsh-multirole/agent-presets/multirole/skills/orchestration/开工话术库.md`。

---

## 版本 / Version

当前版本：`0.1.6`（见 `dsh-multirole/package.json`）

版本规范：`MAJOR.MINOR.PATCH[-dev]`，权威源 = `package.json` 的 `version` 字段。

---

## 目录结构 / Structure

```
dsh-multirole/
├── agent-presets/multirole/
│   ├── preset.yml              # preset 声明
│   ├── agent.cordis.yml        # 工具组合 + 角色 persona + 模型路由
│   └── skills/orchestration/   # 流转协议 + 模板（7 件）
│       ├── SKILL.md            #   宪法（协议本体）
│       ├── 任务单模板.md
│       ├── 授权书模板.md
│       ├── 裁决日志模板.md
│       ├── 验收清单.md
│       ├── 裁决包模板.md
│       └── 开工话术库.md
├── package.json                # 版本权威源
├── cordis.patch.yml            # bundle 注册层
└── scripts/
    └── install.sh              # 安装/发布/回滚脚本
```

---

## 协议要点 / Protocol Highlights

- **第 0 条铁律**：人只干人必须干的事，其他一切都由机完成
- **第 1 条铁律**：召集顾问时必须保证信息充分（列出所有关键输入文件路径）
- **任务单自包含**：跨会话失忆时任务单是唯一事实源
- **并行铁律**：写入域两两不相交
- **验收必须亲验**：禁止凭执行者自述通过

---

## License

MIT
