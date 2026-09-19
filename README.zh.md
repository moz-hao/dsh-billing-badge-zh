# dsh-billing-badge（简体中文分支）

[English](README.en.md) | [上游中文说明](README.upstream.zh.md) | 中文

[![test](https://github.com/moz-hao/dsh-billing-badge-zh/actions/workflows/test.yml/badge.svg)](https://github.com/moz-hao/dsh-billing-badge-zh/actions/workflows/test.yml)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

DeepSeek Harness 网页界面的**计费时段与账户余额**插件。它在输入框的统计行里、原生
**缓存命中** 读数之后加一枚小胶囊，点一下展开面板，把完整信息一次说清。

```
2288M tok · 缓存命中 99.8% · ● 谷时 · 36小时24分
```

> **这是社区原版 [devacc8/dsh-billing-badge](https://github.com/devacc8/dsh-billing-badge)
> 的简体中文分支**，不是原版仓库。功能、判定逻辑与安全边界都沿用原版，只把界面文案
> 与日期/倒计时格式改成中文（改动清单见下文）。

## 显示内容

| 位置 | 内容 |
|---|---|
| 胶囊 | 一个圆点（峰时琥珀色，谷时绿色）、当前时段，以及距离切换的倒计时 |
| 面板（点击展开） | 计费时段、下次切换时间与北京时间、当前北京时间、账户余额及其货币、账户确实拆分为两部分时的赠送与充值明细，以及一个 ⟳ 刷新按钮 |

计费时段采用官方公布的规则：**高峰为北京时间周一至周五 09:00-12:00 与 14:00-18:00**，
其余时间（含整个周六与周日）均为非高峰，价格为半价。

## 账户余额

三个数字来自官方 `GET /user/balance` 接口，含义各不相同：

```
total_balance = granted_balance + topped_up_balance
```

- `total_balance`，界面显示为 **账户余额**，是你可以动用的全部金额。
- `granted_balance`，界面显示为 **赠送额度**，是官方赠送的额度。接口只返回尚未过期的部分，过期的赠送额度会自动从这一行消失。
- `topped_up_balance`，界面显示为 **充值余额**，是你自己充值的金额。

只有在账户确实拆分为两部分时，面板才会列出赠送与充值。没有赠送额度时，充值额就等于全部余额，拆分只会重复上面那行账户余额，因此这种账户只显示一行；接口一旦报告赠送额度，**赠送额度** 就会出现。

`is_available` 是响应顶层的字段，只回答一个问题：余额是否足够调用接口。只有接口报告余额不足时，面板才会加一行 **余额不足** 警告，其余时候保持安静。

货币一律取自接口返回值，不做假设：返回 USD 的账户不会被标上人民币符号。

## 与原版的差异

本分支相对原版 `0.1.3`（upstream commit `8f218f3`）的改动，全部集中在展示层：

| 位置 | 原版 | 本分支 |
|---|---|---|
| 胶囊文案 | `Peak` / `Off-peak` | **峰时 / 谷时** |
| 倒计时 | `2h13m` / `45m` / `38s` | **2小时13分 / 45分 / 38秒** |
| 星期 | `Monday` … | **周一 … 周日** |
| 面板标题 | `Billing and balance` | **计费时段与余额** |
| 面板字段 | `Billing season` `Next switch` `Beijing time` `Account balance` `Granted` `Topped up` `API calls` | **计费时段 下次切换 北京时间 账户余额 赠送额度 充值余额 接口调用** |
| 状态值 | `Peak` `Off-peak (half price)` `insufficient balance` `no API key configured` `unavailable` | **峰时（标准价） 谷时（半价） 余额不足 未配置 API Key 暂不可用** |
| 悬停提示 | 英文整句 | **「谷时计费（半价），还剩 …。北京时间 周一 10:00。」** |
| 刷新按钮 | 文字 `Refresh` | **⟳**（`&#8635;`） |
| 原生统计行匹配 | `/cache hit/i` | **`/cache hit\|缓存命中/i`**（中文界面下也能认得那枚胶囊） |
| 宿主侧错误文案 | 英文 | **中文**（未配置 DEEPSEEK_API_KEY / 缺少插件请求头 / 已拒绝跨站请求 / 余额响应异常） |

**未改动**：峰时窗口判定、周末排除、边界翻转（周五 18:00 后直接指向周一 09:00）、
余额路由与两道安全闸（请求头 + 同源校验）、零落盘、只访问 `api.deepseek.com`。

> 说明：胶囊上的两个词刻意压到二字（`峰时`/`谷时`），因为它是原生统计行里的 flex 子元素，
> 英文 `Off-peak` 换成中文长词会挤压同行读数。若你更想要「高峰/空闲」，改
> `lib/season.js` 里 `describePhase` 的两处字符串即可。

## 安装

**方式一：直接从本分支仓库安装**

```sh
dsh plugin --profile web add github:<你的用户名>/dsh-billing-badge-zh
```

**方式二：从 npm 原版安装后打中文补丁**（适用于已经装了原版、不想换来源的情况）

```powershell
pwsh -File scripts/localize-dsh-billing-badge.ps1
# 还原成英文原版：
pwsh -File scripts/localize-dsh-billing-badge.ps1 -Restore
```

该脚本对 `~/.dsh/profiles/web/node_modules/dsh-billing-badge` 里的三个文件做精确字符串替换，
首次运行会留下 `*.orig-zh` 备份，重复运行安全（幂等），改完自动做语法检查，失败回滚。

装完（或打完补丁）**重启 `dsh web`** 再刷新页面。包内声明了 `dsh.bundle.patch`，宿主部分会自动写入 profile 的 bundle 列表。

兼容 DeepSeek Harness 0.1.5 与 0.1.6。0.1.5 把输入框统计渲染成一行带标记的元素，胶囊加入这一行；0.1.6 把这些读数移进输入框底栏变成一排胶囊按钮，胶囊会跟随缓存命中那枚加入同一行——本分支让这个匹配在中文界面下同样成立。

在本地开发本分支时，改为按路径安装检出目录：

```sh
dsh plugin --profile web add link:/absolute/path/to/dsh-billing-badge-zh
```

## 安全

余额的暴露面很小，插件就让它保持小：

- API key 只在宿主进程中通过 DSH credentials 接口读取（`ctx.credentials.resolve('DEEPSEEK_API_KEY')`，环境变量兜底），不会进入浏览器；
- 唯一的路由要求请求头 `x-dsh-billing-badge: 1` 并拒绝跨站 `Origin`，因此第三方页面无法访问它；
- 不写任何文件，除 `api.deepseek.com` 外不访问任何地址；
- 缺少 key、HTTP 错误或网络故障都会降级为面板可渲染的状态，不会抛异常。

## 与上游同步

本分支的 git 历史保留原版全部提交，汉化是**建立在其上的一次提交**，因此同步很直接：

```sh
git remote add upstream https://github.com/devacc8/dsh-billing-badge.git
git fetch upstream
git merge upstream/main        # 冲突只会落在汉化改过的那些文案行上
node scripts/inline-season.mjs # 如果 season.js 被上游改过，重新内联
npm test                       # 上游文案若变了，测试里的中文断言会提醒你
```

## 开发

时段逻辑放在 `lib/season.js`，是一个普通 ESM 模块，可以直接测试。浏览器端包无法导入同目录文件（加载器只解析平台种子、已物化的包和已注册的工厂，用子路径 require 自身会抛 "missed the module table"），因此 `scripts/inline-season.mjs` 把该模块去掉 `export ` 后复制进 `lib/client.js` 的两个标记之间，`test/client-sync.test.mjs` 在副本漂移时失败。

```sh
npm test          # 39 项测试：时段规则、倒计时不变量、宿主路由、浏览器端包（断言已改为中文）
npm run sync      # 把 season.js 重新内联进浏览器端包
npm run check     # 校验内联是否同步，并对两半做语法检查
```

倒计时用的是不变量测试而不是固定样本：九天之内每 13 分钟取一个时刻，报告的目标必须在未来、必须改变时段，并且时段不能在它之前改变。

## 目录结构

```
lib/season.js    时段规则、倒计时与格式化（唯一事实来源，有测试）
lib/index.js     宿主部分：余额路由
lib/client.js    浏览器部分：胶囊与面板，season.js 已内联
cordis.patch.yml 把宿主部分挂载进 profile
scripts/         内联脚本 + node_modules 汉化补丁（PowerShell）
test/            时段、内联同步、宿主与浏览器端包的测试
README.en.md     上游英文说明（原文保留）
README.upstream.zh.md 上游中文说明（原文保留）
```

GitHub Actions 在 Node 20 与 22 上运行 `npm test` 与 `npm run check`。

## 版权与署名

本项目沿用上游的 MIT 许可证（`LICENSE` 全文未改动，只增补了一行署名）：

```
Copyright (c) 2026 Alex Vega                          # 原版作者，保留
Copyright (c) 2026 Shuang Sun — changes in the Simplified Chinese fork
```

- 原版：[devacc8/dsh-billing-badge](https://github.com/devacc8/dsh-billing-badge)（作者 devacc8 / Alex Vega）；
- 简体中文分支的改动部分：[moz-hao](https://github.com/moz-hao) 维护。

MIT 允许自由使用、修改与再分发（含商用），条件是保留许可证全文与上述版权声明。
