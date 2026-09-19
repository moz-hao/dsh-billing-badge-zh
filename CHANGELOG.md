# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

- 包名由上游的 `dsh-billing-badge` 改为独立的 **`dsh-billing-badge-zh`**，因此本分支与英文原版
  可以并存安装，也不会占用上游在 npm 上的包名。`cordis.patch.yml` 里的 loader entry `id` 仍为
  `billing-badge`（它同时是宿主路由 `/plugins/billing-badge/balance` 的前缀，浏览器端也硬编码了
  这个路径），这样两个包互为可直接替换的 drop-in。
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
