#Requires -Version 7
<#
.SYNOPSIS
    把已安装的 dsh-billing-badge（英文原版）就地汉化，或还原成英文。

.DESCRIPTION
    本仓库是原版的简体中文分支，包名也改成了独立的 dsh-billing-badge-zh，
    所以正常情况下你直接装本仓库就是中文，**用不到这个脚本**：

        dsh plugin --profile web add github:moz-hao/dsh-billing-badge-zh

    它的用途只有一个：你已经在用 npm 上的英文原版 dsh-billing-badge（不想换来源、
    不想重装），只想把它就地把界面变中文。这时它对三个文件做与本仓库 lib/ 等价的
    字符串替换。

    目标目录默认 $env:USERPROFILE\.dsh\profiles\web\node_modules\dsh-billing-badge
    （注意是**原版包名**，不是本分支的 dsh-billing-badge-zh）：
      * 首次运行前把三个待改文件备份为 *.orig-zh
      * 每处替换都是「英文原文 -> 中文译文」的精确匹配；已汉化的文件跳过，
        因此重复运行安全（幂等），升级被覆盖后直接再跑一次即可
      * 只改文案与星期/倒计时格式，峰时判定与边界翻转逻辑一字未动
      * 改完自动 node --check；任一处语法错误就整批回滚
      * 若本仓库也在本机，会顺带和仓库里的 lib/ 做代码行比对，报告是否等价

    脚本能识别的英文原文对应上游 0.1.3。若上游改了文案，脚本会列出没命中的规则，
    这时请以仓库里的 lib/ 为准（它是本分支的事实来源），或按提示补规则。

.EXAMPLE
    pwsh -File scripts/localize-dsh-billing-badge-zh.ps1
    pwsh -File scripts/localize-dsh-billing-badge-zh.ps1 -Restore
    pwsh -File scripts/localize-dsh-billing-badge-zh.ps1 -PluginDirectory 'D:\somewhere\dsh-billing-badge'
#>
[CmdletBinding()]
param(
    [string]$PluginDirectory = (Join-Path $env:USERPROFILE '.dsh\profiles\web\node_modules\dsh-billing-badge'),
    [switch]$Restore
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $PluginDirectory)) {
    throw "找不到插件目录：$PluginDirectory（先跑 dsh plugin --profile web add dsh-billing-badge 装上英文原版）"
}

# 已安装目录不能是本仓库自己：那说明用户在拿脚本改仓库，而仓库本来就已经是中文
$repoLib = Join-Path $PSScriptRoot '..\lib'
$isRepoItself = (Test-Path -LiteralPath $repoLib) -and
    ((Resolve-Path -LiteralPath $PluginDirectory).Path -eq (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path)
if ($isRepoItself) { throw '这是本仓库自己，不需要汉化；直接 npm test 即可。' }

$targets = @('lib/client.js', 'lib/season.js', 'lib/index.js') |
    ForEach-Object { Join-Path $PluginDirectory $_ }

# 英文原文 -> 中文译文。每条都必须精确命中才替换。
$rules = [ordered]@{
    # ---- 计费时段标签 ----
    "const label = peak ? 'Peak' : 'Off-peak';" =
        "const label = peak ? '峰时' : '谷时';"
    "const compact = peak ? 'Peak' : 'Off-peak';" =
        "const compact = peak ? '峰时' : '谷时';"
    "const nextLabel = peak ? 'Off-peak' : 'Peak';" =
        "const nextLabel = peak ? '谷时' : '峰时';"

    # ---- 提示气泡 ----
    '? `Peak billing until ${countdown} from now (${nextLabel} after that). Beijing time ${weekday} ${clock}.`' =
        '? `峰时计费（标准价），${countdown}后转入${nextLabel}。北京时间 ${weekday} ${clock}。`'
    ': `Off-peak billing, half price, for another ${countdown}. Beijing time ${weekday} ${clock}.`,' =
        ': `谷时计费（半价），还剩 ${countdown}。北京时间 ${weekday} ${clock}。`,'

    # ---- 星期与倒计时 ----
    "['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']" =
        "['周日', '周一', '周二', '周三', '周四', '周五', '周六']"
    'if (hours > 0) return `${hours}h${String(minutes).padStart(2, ''0'')}m`;' =
        'if (hours > 0) return `${hours}小时${minutes}分`;'
    'if (minutes > 0) return `${minutes}m`;' =
        'if (minutes > 0) return `${minutes}分`;'
    'return `${seconds}s`;' =
        'return `${seconds}秒`;'

    # ---- 面板字段 ----
    '["Billing season", phase.peak ? "Peak" : "Off-peak (half price)"],' =
        '["计费时段", phase.peak ? "峰时（标准价）" : "谷时（半价）"],'
    '["Next switch", phase.countdown === "" ? "--" : `in ${phase.countdown}` + (flip === null ? "" : `, ${beijingClock(flip).weekday} ${beijingClock(flip).clock} Beijing`)],' =
        '["下次切换", phase.countdown === "" ? "--" : `${phase.countdown}后` + (flip === null ? "" : `，${beijingClock(flip).weekday} ${beijingClock(flip).clock}（北京时间）`)],'
    '["Beijing time", `${phase.beijing.weekday} ${phase.beijing.clock}`],' =
        '["北京时间", `${phase.beijing.weekday} ${phase.beijing.clock}`],'
    '["Account balance", formatMoney(balance.total, balance.currency)' =
        '["账户余额", formatMoney(balance.total, balance.currency)'
    'rows.push(["Granted", formatMoney(balance.granted, balance.currency)]);' =
        'rows.push(["赠送额度", formatMoney(balance.granted, balance.currency)]);'
    'rows.push(["Topped up", formatMoney(balance.toppedUp, balance.currency)]);' =
        'rows.push(["充值余额", formatMoney(balance.toppedUp, balance.currency)]);'
    '["API calls", "insufficient balance", "warn"]' =
        '["接口调用", "余额不足", "warn"]'
    '["Account balance", "no API key configured"]' =
        '["账户余额", "未配置 API Key"]'
    '["Account balance", "unavailable"]' =
        '["账户余额", "暂不可用"]'

    # ---- 面板外壳 ----
    'panel.setAttribute("aria-label", "Billing and balance");' =
        'panel.setAttribute("aria-label", "计费时段与余额");'
    '<span class="dsh-billing-title">Billing and balance</span>' =
        '<span class="dsh-billing-title">计费时段与余额</span>'
    '<button class="dsh-billing-refresh" type="button">Refresh</button>' =
        '<button class="dsh-billing-refresh" type="button">&#8635;</button>'

    # ---- 原生统计行匹配：中文界面下缓存命中胶囊也要认得 ----
    '/cache hit/i.test(' =
        '/cache hit|缓存命中/i.test('

    # ---- 宿主侧错误文案 ----
    "error: 'the balance response carried no balance_infos entry'" =
        "error: '余额响应中没有 balance_infos 条目'"
    "error: 'DEEPSEEK_API_KEY is not configured'" =
        "error: '未配置 DEEPSEEK_API_KEY'"
    "error: 'missing plugin header'" =
        "error: '缺少插件请求头'"
    "error: 'cross-origin request rejected'" =
        "error: '已拒绝跨站请求'"
}

function Write-TextNoBom {
    param([string]$Path, [string]$Text)
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

if ($Restore) {
    $restored = 0
    foreach ($file in $targets) {
        $backup = "$file.orig-zh"
        if (Test-Path -LiteralPath $backup) {
            Copy-Item -LiteralPath $backup -Destination $file -Force
            Write-Host "还原 $file"
            $restored++
        }
    }
    if ($restored -eq 0) { Write-Warning '没有找到 *.orig-zh 备份，未做任何改动。' }
    else { Write-Host "完成：还原 $restored 个文件。重启 dsh web 后生效。" }
    return
}

$changed = [System.Collections.Generic.List[string]]::new()
$ruleHits = @{}
foreach ($key in $rules.Keys) { $ruleHits[$key] = 0 }

foreach ($file in $targets) {
    if (-not (Test-Path -LiteralPath $file)) { throw "缺少文件：$file" }
    $backup = "$file.orig-zh"
    if (-not (Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $file -Destination $backup -Force
        Write-Host "备份 $file -> $([System.IO.Path]::GetFileName($backup))"
    }

    $text = [System.IO.File]::ReadAllText($file, [System.Text.UTF8Encoding]::new($false))
    $original = $text
    foreach ($pair in $rules.GetEnumerator()) {
        if ($text.Contains($pair.Key)) {
            $text = $text.Replace($pair.Key, $pair.Value)
            $ruleHits[$pair.Key] = $ruleHits[$pair.Key] + 1
        }
    }
    if ($text -ne $original) {
        Write-TextNoBom -Path $file -Text $text
        $changed.Add([System.IO.Path]::GetFileName($file))
    }
}

# 语法自检：任一处失败就回滚本次全部改动
$bad = @()
foreach ($file in $targets) {
    & node --check $file 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { $bad += $file }
}
if ($bad.Count -gt 0) {
    foreach ($file in $targets) {
        $backup = "$file.orig-zh"
        if (Test-Path -LiteralPath $backup) { Copy-Item -LiteralPath $backup -Destination $file -Force }
    }
    throw "语法检查失败，已回滚：$($bad -join ', ')"
}

Write-Host ''
if ($changed.Count -gt 0) {
    Write-Host ("已汉化文件：{0}" -f (($changed | Select-Object -Unique) -join ', '))
} else {
    Write-Host '目标文件已是中文（或无需改动），未写入任何内容。'
}

$skipped = @($ruleHits.GetEnumerator() | Where-Object { $_.Value -eq 0 } | ForEach-Object { $_.Key })
if ($skipped.Count -gt 0) {
    Write-Warning ("有 {0} 条规则一次都没命中（上游文案可能已变，或目标已经汉化）：" -f $skipped.Count)
    $skipped | ForEach-Object { Write-Warning $_ }
}

# 与本仓库 lib/ 做“代码行”等价性比对：忽略注释与空行
if (Test-Path -LiteralPath $repoLib) {
    $codeOf = {
        param($path)
        @([System.IO.File]::ReadAllLines($path) | Where-Object {
            $t = $_.Trim()
            $t -ne '' -and -not ($t.StartsWith('*') -or $t.StartsWith('/**') -or $t.StartsWith('//'))
        })
    }
    Write-Host ''
    Write-Host '与本仓库 lib/ 的代码行比对：'
    foreach ($rel in 'lib/client.js', 'lib/season.js', 'lib/index.js') {
        $installed = Join-Path $PluginDirectory $rel
        $repo = Join-Path $repoLib (Split-Path $rel -Leaf)
        if (-not (Test-Path -LiteralPath $repo)) { continue }
        $a = & $codeOf $installed
        $b = & $codeOf $repo
        $same = ($a.Count -eq $b.Count) -and (($a -join "`n") -eq ($b -join "`n"))
        Write-Host ("  {0,-12} {1}" -f (Split-Path $rel -Leaf), $(if ($same) { '一致' } else { '不一致（以仓库 lib/ 为准）' }))
    }
}

Write-Host ''
Write-Host '语法检查通过。重启 dsh web（或让插件热挂载）后刷新页面即可看到中文界面。'
