# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.3-zh.7] - 2026-11-08

### Fixed

- **新会话首页（hero）整枚胶囊缺席。** harness 0.2.2 只在「已有会话」时渲染
  `conversation.composer.dock`（`variant === 'composer'` 且已有输入器与会话 id），全新会话页里
  这个 slot 根本不存在，而本插件把组件注册在它上面——组件不渲染、`statsRow()` 也没有挂载点，
  于是宿主端一切正常、页面上什么都看不到（连样式都没注入）。
  现在 `statsRow()` 在 dock 缺席时回退到输入框卡片右侧控制行
  （`conversation.input.right`，模型选择旁），并把该 slot 注册为第二个宿主。
- 座次状态提到模块作用域并计数占位者：两个宿主同时挂载时**只保留一枚**胶囊；会话开始后胶囊
  自动从控制行迁回原生统计行（缓存命中读数之后），既不会重复也不会因 React 重建而丢失。
- `__internal` 追加 `ensureSeated` / `releaseSeat`，让上面这条「跟随 + 不重复」能被单测直接驱动。

### Changed

- 回归测试：新增「hero 回退到控制行」「dock 尚无读数时仍留在 dock」「跟随迁移且不重复」
  等 4 项断言，`node --test` 43 项全绿；改测试先红（旧 bundle 5 项失败）后绿，避免只测新代码。

## [0.1.3-zh.6] - 2026-11-08

### Changed

- **余额优先读已登录的 DeepSeek 账号。** 桌面版 0.2.x 一般只登录账号、不带 API key，
  原先的 key-only 路径会一直报「未配置」。现在先走 `deepseekAccount` seam
  （`getState()` → `getBalance()`），密钥仍在宿主进程内，浏览器只拿到数字；
  账号不可用时才回落到 `DEEPSEEK_API_KEY` 与 `api.deepseek.com/user/balance`。
- 未登录文案改为「未登录 DeepSeek 账号」；账号侧没有 `is_available` 字段，余额为 0 即视为不可用。

### Fixed

- 胶囊字体不再继承底栏正文字号，固定 `font-size: 12px; line-height: 18px`，与「缓存命中」那枚
  原生胶囊同号（此前会大一号）；间距同步收成 `gap: 5px; padding: 1px 7px`。
- 0.2.x 的 dock 不再保证有「缓存命中」胶囊（它改为承载 `activity` / `usage` 环境条目），
  匹配不到时胶囊直接加入 dock 本身，而不是悄悄消失。

## [0.1.3-zh.4] - 2026-10-02

### Fixed

- **面板底色改为实色、完全不透明**（桌面版尤其明显）：上游只画了一层主题菜单色，而 harness 主题把它
  定义为**带 alpha 的颜色**——深色主题 `#43454a73`（45%）、浅色主题 `#f8f9fa94`（58%），macOS 覆写是
  `rgba(…, .94)`。于是面板后面的输入框文字（模型名、统计读数）会透出来。
  中途试过「用主题变量叠加出不透明」（`background: var(--dsw-specific-menu),
  var(--dsw-alias-bg-base)`），实机上面板反而变成**全透明**——该写法在桌面宿主上没能落地生效，
  因此最终改为**不经过任何变量解析的实色**：
  - 深色主题 `#2A2B2E` = 45% 的 `#43454A` 叠在页面底色 `#151517` 上的合成结果；
  - 浅色主题（`@media (prefers-color-scheme: light)`）`#FBFBFC` = 58% 的 `#F8F9FA` 叠在 `#FFFFFF` 上。

  也就是「本应有的菜单色 + 完全不透明」，且不依赖任何主题变量的解析。
- 回归测试同步重写：`test/client.test.mjs` 现在断言**赢得层叠的那条 background 声明必须是实色、
  alpha = 1、且不含 `var(`**，同时浅色主题覆写也必须不透明（40 项测试全绿）。

## [0.1.3-zh.3] - 2026-09-19

### Fixed

- 浏览器半的模块 id 与包名对齐：`lib/client.js` 现在以 **`dsh-billing-badge-zh`** 调用
  `__ModuleLoader__.load`。0.1.3-zh.2 改了包名却仍沿用上游的 `dsh-billing-badge`，而宿主的客户端
  模块图是以 `package.json` 的 `name` 作为 row id 的，浏览器拿到
  `/plugins/??…,dsh-billing-badge-zh/client.js,…` 这个 combo 后找不到同名注册，于是整屏报
  `Failed to load plugins — failed to import loader entry … (dsh-billing-badge-zh): client-modules:
  bundle … loaded without registering "dsh-billing-badge-zh" via __ModuleLoader__.load`，网页打不开。
  宿主路由 `/plugins/billing-badge/balance` 与 `cordis.patch.yml` 里的 loader entry `id`
  （`billing-badge`）**未改动**，两个包名仍然只需替换依赖即可。
  > 注意：因为两个包的 loader entry `id` 都是 `billing-badge`、宿主路由也都注册
  > `/plugins/billing-badge/balance`，**同一 profile 里同时安装本分支与英文原版依旧会冲突**；
  > 0.1.3-zh.2 里“可以并存”的说法只对包名成立。
- `test/client.test.mjs` 改为直接用 `package.json` 的 `name` 断言注册 id：以后包名与模块 id 再
  分叉，测试会当场失败，而不是等到浏览器里整屏报错。

## [0.1.3-zh.2] - 2026-09-19

### Changed

- 包名由上游的 `dsh-billing-badge` 改为独立的 **`dsh-billing-badge-zh`**，因此不会占用上游在 npm
  上的包名（“可与原版并存安装”已在 0.1.3-zh.3 更正）。`cordis.patch.yml` 里的 loader entry
  `id` 仍为 `billing-badge`（它同时是宿主路由 `/plugins/billing-badge/balance` 的前缀，浏览器端
  也硬编码了这个路径），这样两个包互为可直接替换的 drop-in。
- 署名从 `LICENSE` 移到独立的 **`NOTICE`**：`LICENSE` 恢复为上游原文（逐字节一致），
  版权声明（Alex Vega + Shuang Sun）写在 `NOTICE` 里，提交时一并纳入 `package.json` 的 `files`。
- 补丁脚本改名为 `scripts/localize-dsh-billing-badge-zh.ps1`（它汉化的仍是**原版包名**的安装目录）。

## [0.1.3-zh.1] - 2026-09-19

简体中文分支（fork）。基线为上游 `0.1.3`（commit `8f218f3`），以下改动全部集中在展示层。

### Changed

- 界面文案汉化：胶囊 `Peak`/`Off-peak` → **峰时/谷时**，面板标题与字段（计费时段、下次切换、
  北京时间、账户余额、赠送额度、充值余额、接口调用）、状态值、悬停提示、宿主侧错误文案全部改为简体中文。
- 倒计时格式改为中文单位（`2h13m` → `2小时13分`、`45m` → `45分`、`38s` → `38秒`）；星期改为
  `周一`…`周日`。
- 刷新按钮由文字 `Refresh` 改为 **⟳**（`&#8635;`），位置与尺寸不变。
- 原生统计行的缓存命中胶囊改为双语匹配（`/cache hit|缓存命中/i`），中文界面下胶囊同样能挂到统计行。
- 测试断言同步改为中文，29 → 39 项全部通过（`npm test`）。

### Unchanged

- 峰时窗口判定、周末排除、边界翻转逻辑；余额路由与请求头/同源两道安全闸；零落盘；仅访问
  `api.deepseek.com`。

## [0.1.3] - 2026-09-18

### Changed

- The panel names the granted and topped-up parts only when the account is actually
  split. With no grant the topped-up amount is the whole balance, so both rows repeated
  the account balance line above them. Such an account now shows one row, and **Granted**
  appears as soon as the endpoint reports one.

## [0.1.2] - 2026-09-18

### Fixed

- The chip follows the statistics reading into the composer dock on DeepSeek Harness
  0.1.6, where the labelled statistics row was replaced by a row of pill buttons and the
  old anchor no longer existed. Both shapes are supported: the labelled row stays first
  in the resolution order, the dock row is the fallback.
- The panel no longer closes on every scroll or resize. The composer scrolls on its own
  while a turn renders, so a click could be dismissed a moment after it opened. The panel
  now follows the chip and closes only once the chip itself is out of sight.

### Added

- `README.zh.md`, a full Chinese README. The catalog card renders a per-language README
  and its language sniff classified the mixed-language file as Chinese only, which the
  card then printed. The main README is English again, with a language link.
- `screenshots.json`, the catalog convention for author-curated card screenshots, with
  the panel and the pill in its row. Both the catalog detail page and the market's
  storefront read it from this repository, so a screenshot no longer waits on a
  maintainer.

### Removed

- The panel note saying that prices are published in CNY per million tokens while the
  balance keeps the currency the API reports. The plugin shows no prices, so the sentence
  explained nothing, and on an account reporting USD it read as if the account's own
  numbers were CNY. The empty note no longer reserves its spacing.

## [0.1.1] - 2026-09-13

### Changed

- The install section now leads with the npm package,
  `dsh plugin --profile web add dsh-billing-badge`, with the repository install kept
  as the alternative. The package page renders this file, so the published copy and
  the repository now say the same thing.
- Added the npm version badge to the README.

## [0.1.0] - 2026-09-13

First public release.

### Added

- A pill in the composer statistics row, appended after the native cache-hit reading.
  It shows a season dot (amber for peak, green for off-peak), the season name, and the
  countdown to the next flip.
- A panel on click, styled with the native dialog tokens: billing season, next switch
  with the Beijing wall clock, current Beijing time, account balance with its currency,
  the granted and topped-up split, a warning row when the API reports the balance as
  insufficient for calls, and a refresh button.
- A read-only host route, `GET /plugins/billing-badge/balance`, which resolves the API
  key through the DSH credentials seam, caches a reading for 60 seconds, and dedupes
  concurrent reads. It requires the `x-dsh-billing-badge: 1` header and rejects a
  cross-origin `Origin`.
- The season rule as a tested module: peak is Beijing time, Monday to Friday,
  09:00-12:00 and 14:00-18:00, everything else including the whole weekend is off-peak
  at half price. The next switch is computed by comparing each candidate boundary with
  the instant before it, so only a real state flip counts.
- 30 tests covering the season rule, a countdown invariant across nine days, bundle
  and source sync, the host route and its guards, and the panel rows.

### Fixed

- `is_available` is a top-level field of the balance response, a sibling of
  `balance_infos`, not a member of the entry. Reading it from the entry made the flag
  false for every account. The regression test pins the documented location.

MIT.
