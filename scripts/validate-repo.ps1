$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$readmePath = Join-Path $root 'README.md'
$artifactPath = Join-Path $root 'CLASH_PRECHECK.md'
$problems = [System.Collections.Generic.List[string]]::new()

foreach ($file in @($readmePath, $artifactPath)) {
    if (-not (Test-Path -LiteralPath $file)) { throw "缺少必需文件：$file" }
}

$readme = Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8

$firstLine = ($readme -split "`r?`n")[0]
if ($firstLine -ne '# 机场推荐 2026：Clash 用户先做订阅兼容检查') { $problems.Add('README H1 与立项卡定义不一致。') }
if ([regex]::Matches($readme, '机场推荐').Count -lt 4) { $problems.Add('README 没有形成清晰的“机场推荐”主关键词口径。') }
if ($readme -notmatch [regex]::Escape('](CLASH_PRECHECK.md)')) { $problems.Add('README 没有链接独有实用文件。') }

$brandNames = @('sogo云', '宇宙云', '可信云')
foreach ($brandName in $brandNames) {
    if ($readme -notmatch [regex]::Escape($brandName)) { $problems.Add("README 缺少推荐品牌：$brandName。") }
}

$restrictedBrands = @('sogo云', '宇宙云', '可信云')
foreach ($brandName in $restrictedBrands) {
    $restrictionPattern = '(?m)^.*' + [regex]::Escape($brandName) + '.*暂不提供第三方订阅'
    if ($readme -notmatch $restrictionPattern) { $problems.Add("$brandName 缺少第三方订阅限制。") }
}

$warnedBrands = @('可信云')
foreach ($brandName in $warnedBrands) {
    if ($readme -notmatch '可达性存在波动') { $problems.Add("$brandName 缺少购买前可达性警告。") }
}

$urls = @([regex]::Matches($readme, 'https?://[^)\s]+') | ForEach-Object { $_.Value } | Sort-Object -Unique)
if ($urls.Count -ne 13) { $problems.Add("README 应有 13 个独立外部导流链接，当前为 $($urls.Count) 个。") }
foreach ($url in $urls) {
    $uri = [Uri]$url
    if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'clashvpnss.com') {
        $problems.Add("发现非目标域名或非 HTTPS 外链：$url")
        continue
    }
    foreach ($required in @('utm_source=github', 'utm_medium=referral', 'utm_campaign=jichang-tuijian-clashvpnss')) {
        if ($uri.Query -notlike "*$required*") { $problems.Add("目标站链接缺少 $required：$url") }
    }
}

if ($problems.Count -gt 0) {
    Write-Host '未通过发布检查：' -ForegroundColor Red
    $problems | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    exit 1
}

Write-Host "通过：独立主题、实用文件、3 个品牌和 $($urls.Count) 个不同 UTM 导流链接均符合发布口径。" -ForegroundColor Green
