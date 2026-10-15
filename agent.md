# Agent 项目说明文档

> 本文件供 AI Agent 在参与本项目开发时快速了解项目背景、技术架构和开发规范。

## 1. 项目概述

**插件名称**：`_LFG_In_Chat`（显示名称：聊天关注词过滤 / LFGC Chat Filter）

**适用环境**：
- 游戏：魔兽世界 3.3.5a (WLK)
- 服务器：Warmane 私服
- 接口版本：30300

**功能定位**：一个聊天频道过滤插件，用于在"综合"(global)频道和"大喊"(yell)频道中，仅显示包含自定义关注词的发言，并按阵营过滤对立阵营的大喊消息。

**核心功能**：
1. 综合频道（CHAT_MSG_CHANNEL）：仅显示包含关注词的发言
2. 大喊频道（CHAT_MSG_YELL）：仅显示同阵营且包含关注词的发言（通过语言判定阵营）
3. 关注词自定义管理（新增/删除）
4. 关注词绿色高亮显示（可切换为直接过滤模式）
5. 插件全局启用/禁用开关
6. 配置按角色保存（SavedVariablesPerCharacter）
7. 斜杠命令 `/lfgc` 打开设置界面
8. 集成至暴雪界面选项面板

## 2. 目录结构

```
LFG_In_Chat_For_Warmane_3.3.5/          # 项目根目录（Git 仓库）
├── _LFG_In_Chat/                       # 插件文件夹（部署到 AddOns 时使用）
│   ├── _LFG_In_Chat.lua                # 主逻辑文件（事件处理、过滤逻辑、UI 交互）
│   ├── _LFG_In_Chat.toc                # 插件元数据文件（描述、版本、依赖等）
│   ├── _LFG_In_Chat.xml                # UI 配置文件（设置界面 XML 定义）
│   └── README.txt                      # 插件内中文说明
├── README.md                           # 项目级中文说明文档
├── LICENSE                             # GPL v3 许可证
└── .gitignore                          # Git 忽略规则
```

## 3. 技术栈

- **语言**：Lua（魔兽世界客户端扩展语言）
- **UI 框架**：暴雪原生 XML UI + Lua 逻辑
- **存档机制**：`SavedVariablesPerCharacter`（变量名：`LFG_DB_ROLE`）
- **过滤机制**：`ChatFrame_AddMessageEventFilter` 注册聊天事件过滤器
- **聊天事件**：`CHAT_MSG_CHANNEL`（综合频道）、`CHAT_MSG_YELL`（大喊频道）
- **阵营判定**：`GetDefaultLanguage("player")` 获取玩家语言，与消息语言对比判定阵营

## 4. 核心代码架构

### 4.1 数据层（LFG_DB_ROLE）

按角色保存的配置数据库，字段如下：

| 字段 | 类型 | 说明 |
|------|------|------|
| `enabled` | boolean | 插件功能总开关 |
| `filterWords` | table | 关注词列表（字符串数组） |
| `highlightEnabled` | boolean | 高亮模式开关（true=高亮显示，false=直接过滤） |

默认值定义在 `_LFG_In_Chat.lua` 第 6-10 行的 `defaultConfig` 中。

### 4.2 过滤逻辑层

- `GetMatchedFilterWords(msg)`：遍历关注词列表，不区分大小写匹配消息内容，返回匹配到的词列表
- `IsFilterWordsEmpty()`：检查关注词列表是否为空
- `HighlightFilterWords(msg, matchedWords)`：将消息中的匹配词替换为绿色高亮格式（`|cff00ff00<text>|r`）
- `ChatFilterChannel(...)`：综合频道过滤器，匹配关注词则显示，否则过滤
- `ChatFilterYell(...)`：大喊频道过滤器，先判定阵营（语言不同则过滤），再匹配关注词
- `RegisterChatFilters()`：注册 `CHAT_MSG_CHANNEL` 和 `CHAT_MSG_YELL` 的事件过滤器

**过滤返回值约定**（`ChatFrame_AddMessageEventFilter` 标准）：
- `true`：过滤该消息（不显示）
- `false, msg, author, language, ...`：修改后显示

### 4.3 UI 层

**XML 定义**（`_LFG_In_Chat.xml`）：
- `ChatFilterConfigFrame`：主配置框架（450×580，可拖动）
- `ChatFilterConfigFrameEnableCheckbox`：启用功能复选框
- `ChatFilterConfigFrameHighlightCheckbox`：高亮模式复选框
- `ChatFilterConfigFrameInputBox`：关注词输入框（最多 50 字符）
- `ChatFilterConfigFrameAddButton`：添加按钮
- `ChatFilterConfigFrameScrollFrame`：关注词列表滚动区域
- `ChatFilterConfigFrameCloseButton`：关闭按钮
- `ChatFilterConfigFrameFactionFrameFactionText`：当前阵营语言显示
- `ChatFilterConfigFrameInfoFrameInfoText`：关注规则说明文本

**Lua 交互逻辑**（`_LFG_In_Chat.lua`）：
- `InitializeUI()`：初始化所有 UI 元素的脚本回调
- `UpdateFilterWordList()`：刷新关注词列表（动态创建/隐藏列表项按钮）
- `ShowOptions()`：显示/隐藏设置界面
- `SetupBlizzardOptions()`：注册到暴雪界面选项面板

### 4.4 事件处理

主事件帧 `LFGCFrame` 注册的事件：
- `ADDON_LOADED`：插件加载时初始化数据库、注册过滤器、初始化 UI
- `PLAYER_ENTERING_WORLD`：玩家进入世界时更新阵营语言
- `ZONE_CHANGED_NEW_AREA`：区域变更（达拉然区域检测已注释禁用）

**注意**：达拉然区域限制功能已注释掉，当前版本在所有区域生效。

## 5. 命令与接口

| 命令/入口 | 说明 |
|-----------|------|
| `/lfgc` | 斜杠命令，打开/关闭设置界面 |
| 界面选项 → `_LFGC - 关注词白名单` | 暴雪游戏菜单中打开设置界面 |

## 6. 开发规范与注意事项

### 6.1 代码风格
- 变量和函数命名：驼峰式（camelCase），如 `filterWords`、`updatePlayerLanguage`
- 局部变量优先使用 `local`，避免污染全局命名空间
- 注释使用中文，与现有风格一致
- 文件头部不强制要求特定格式

### 6.2 存档兼容
- 新增配置字段时，必须在 `ADDON_LOADED` 事件处理中增加兼容逻辑（如 `if LFG_DB_ROLE.highlightEnabled == nil then`）
- 修改 `LFG_DB_ROLE` 结构时，需确保旧存档不会报错

### 6.3 UI 开发注意
- XML 中的 `$parent` 引用基于父 Frame 的命名，修改 UI 时需注意引用关系
- 关注词列表按钮通过 `CreateFrame` 动态创建，存储在 `listButtons` 全局表中
- 高亮颜色使用 `|cff00ff00`（绿色）和 `|cffff0000`（红色，用于删除提示）
- 系统提示统一格式：`|cff00ff00[聊天关注]|r 消息内容`

### 6.4 过滤逻辑注意
- 消息匹配使用 `string.find(lowerMsg, lowerWord, 1, true)`（纯字符串匹配，非模式匹配）
- 高亮替换时对特殊字符进行转义（`%$%()%%.%[]%*%+%-%?`）
- 阵营判定依赖 `GetDefaultLanguage("player")` 返回值，与消息的 `language` 参数对比

### 6.5 已知限制
- 达拉然区域检测代码已注释，当前在所有区域生效
- 仅处理 `CHAT_MSG_CHANNEL` 和 `CHAT_MSG_YELL` 两个事件
- 关注词列表通过滚动框架展示，无分页（数据量大时可能影响性能）

## 7. 版本与发布信息

- **当前版本**：v1.0.0（2025-01-29）
- **作者**：Bowen
- **仓库地址**：https://github.com/abcdefe/LFG_In_Chat_For_Warmane_3.3.5
- **许可证**：GNU GPL v3
- **分类**：Chat（聊天类插件）
- **本地化**：zhCN（简体中文）

## 8. 修改检查清单

在提交任何修改前，请确认：

- [ ] 新增配置字段已添加存档兼容逻辑
- [ ] `.toc` 文件版本号和接口版本已更新（如适用）
- [ ] `README.md` 和 `README.txt` 已同步更新（如功能变更）
- [ ] 聊天提示消息格式统一（`[聊天关注]` 前缀）
- [ ] UI 框架命名和引用关系未破坏
- [ ] 过滤逻辑的返回值符合 `ChatFrame_AddMessageEventFilter` 约定
- [ ] 无语法错误（注意 Lua 中 `end`、`then`、`do` 的配对）
