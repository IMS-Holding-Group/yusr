#Requires -Version 5.1
<#
.SYNOPSIS
  بناء نسخة Flutter Web جاهزة للنشر على Render (أو أي استضافة ثابتة).

.DESCRIPTION
  - يتحقق من Flutter و Python
  - يثبّت التبعيات
  - يبني الويب بـ API_BASE_URL متوافق مع خادم Flask
  - ينسخ المخرجات إلى deploy/dist/web
  - يولّد ملفات إعداد Render

.EXAMPLE
  .\scripts\build-flutter-web.ps1

.EXAMPLE
  .\scripts\build-flutter-web.ps1 -ApiBaseUrl "https://yusr-api.onrender.com" -OpenOutput

.PARAMETER ApiBaseUrl
  عنوان خادم Flask (بدون شرطة نهائية).

.PARAMETER OutputDir
  مجلد مخرجات البناء النهائي.

.PARAMETER SkipPubGet
  تخطي flutter pub get.

.PARAMETER SkipBackendCheck
  تخطي فحص صحة الخادم.

.PARAMETER OpenOutput
  فتح مجلد المخرجات بعد النجاح.
#>
[CmdletBinding()]
param(
    [string] $ApiBaseUrl = "http://127.0.0.1:5000",
    [string] $OutputDir = "",
    [switch] $SkipPubGet,
    [switch] $SkipBackendCheck,
    [switch] $OpenOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─── مسارات المشروع ───
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$FlutterDir = Join-Path $RepoRoot "flutter_app"
$BackendDir = Join-Path $RepoRoot "backend"
$DeployDir = Join-Path $RepoRoot "deploy"
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $DeployDir "dist\web"
}

$ApiBaseUrl = $ApiBaseUrl.Trim().TrimEnd("/")
if ($ApiBaseUrl -notmatch '^https?://') {
    throw "ApiBaseUrl يجب أن يبدأ بـ http:// أو https:// (القيمة: $ApiBaseUrl)"
}

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-CommandExists([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-Flutter {
    param([string[]]$Args)
    Push-Location $FlutterDir
    try {
        & flutter @Args
        if ($LASTEXITCODE -ne 0) { throw "فشل الأمر: flutter $($Args -join ' ')" }
    } finally {
        Pop-Location
    }
}

Write-Host @"

╔══════════════════════════════════════════════════╗
║   يُسر — بناء Flutter Web للنشر على Render     ║
╚══════════════════════════════════════════════════╝
"@ -ForegroundColor Yellow

Write-Step "التحقق من الأدوات"
if (-not (Test-CommandExists "flutter")) {
    throw "Flutter غير مثبت أو غير موجود في PATH. ثبّته من: https://docs.flutter.dev/get-started/install"
}
if (-not (Test-Path $FlutterDir)) {
    throw "مجلد التطبيق غير موجود: $FlutterDir"
}

$flutterVersion = (flutter --version 2>&1 | Select-Object -First 1)
Write-Host "  Flutter: $flutterVersion" -ForegroundColor Gray

Write-Step "تفعيل دعم الويب"
Invoke-Flutter @("config", "--enable-web")

Write-Step "تنظيف بناء سابق"
Invoke-Flutter @("clean")

if (-not $SkipPubGet) {
    Write-Step "تثبيت حزم Dart (pub get)"
    Invoke-Flutter @("pub", "get")
}

Write-Step "فحص التحليل السريع"
Invoke-Flutter @("analyze", "--no-fatal-infos")

if (-not $SkipBackendCheck) {
    Write-Step "فحص خادم Flask (اختياري)"
    if (Test-CommandExists "python") {
        $healthUrl = "$ApiBaseUrl/health"
        try {
            $resp = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 8
            if ($resp.StatusCode -eq 200) {
                Write-Host "  الخادم يعمل: $healthUrl" -ForegroundColor Green
            }
        } catch {
            Write-Host "  تحذير: تعذّر الاتصال بـ $healthUrl" -ForegroundColor Yellow
            Write-Host "  شغّل الخادم: cd backend; python app.py" -ForegroundColor Yellow
            Write-Host "  أو استخدم -SkipBackendCheck لتجاوز الفحص." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Python غير موجود — تخطي فحص الخادم." -ForegroundColor Yellow
    }
}

Write-Step "بناء Flutter Web (Release)"
Write-Host "  API_BASE_URL = $ApiBaseUrl" -ForegroundColor Gray

Invoke-Flutter @(
    "build", "web",
    "--release",
    "--base-href", "/",
    "--dart-define=API_BASE_URL=$ApiBaseUrl"
)

$buildWeb = Join-Path $FlutterDir "build\web"
if (-not (Test-Path (Join-Path $buildWeb "index.html"))) {
    throw "لم يُنشأ build/web — تحقق من أخطاء البناء أعلاه."
}

Write-Step "نسخ الملفات إلى $OutputDir"
if (Test-Path $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Copy-Item -Path (Join-Path $buildWeb "*") -Destination $OutputDir -Recurse -Force

# SPA rewrite لاستضافة Render Static (إن استُخدمت بدل Docker)
$redirectsPath = Join-Path $OutputDir "_redirects"
@(
    "/*    /index.html   200"
) | Set-Content -Path $redirectsPath -Encoding UTF8

Write-Step "توليد ملفات الإعداد"
$envRenderPath = Join-Path $DeployDir "render.env.generated"
@"
# مُولَّد تلقائياً — $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# انسخ القيم إلى لوحة Render → Environment

# yusr-api
DATABASE_PATH=/var/data/yusr.db
CORS_ORIGINS=https://YOUR-YUSR-WEB.onrender.com
FLASK_DEBUG=false

# yusr-web (Docker build arg أو متغير بيئة)
API_BASE_URL=$ApiBaseUrl
"@ | Set-Content -Path $envRenderPath -Encoding UTF8

$metaPath = Join-Path $OutputDir "yusr-build-info.json"
@{
    builtAt    = (Get-Date).ToString("o")
    apiBaseUrl = $ApiBaseUrl
    flutterDir = $FlutterDir
    outputDir  = $OutputDir
} | ConvertTo-Json | Set-Content -Path $metaPath -Encoding UTF8

# تحديث وصف index.html
$indexPath = Join-Path $OutputDir "index.html"
if (Test-Path $indexPath) {
    $html = Get-Content $indexPath -Raw -Encoding UTF8
    $html = $html -replace '<meta name="description" content="[^"]*">', '<meta name="description" content="يُسر — منصة تسوق صوتية لذوي الإعاقة البصرية والحركية">'
    $html = $html -replace '<title>[^<]*</title>', '<title>يُسر</title>'
    $html = $html -replace '<meta name="apple-mobile-web-app-title" content="[^"]*">', '<meta name="apple-mobile-web-app-title" content="يُسر">'
    Set-Content -Path $indexPath -Value $html -Encoding UTF8 -NoNewline
}

Write-Host ""
Write-Host "تم البناء بنجاح." -ForegroundColor Green
Write-Host "  المخرجات: $OutputDir" -ForegroundColor Green
Write-Host "  إعداد Render: $envRenderPath" -ForegroundColor Green
Write-Host ""
Write-Host "النشر على Render (بدون Docker):" -ForegroundColor Cyan
Write-Host "  1) git add deploy/dist/web && git commit && git push" -ForegroundColor Gray
Write-Host "  2) Render → Blueprint من render.yaml (Static + Python)" -ForegroundColor Gray
Write-Host "  3) عيّن CORS_ORIGINS في yusr-api = رابط yusr-web" -ForegroundColor Gray
Write-Host ""
Write-Host "تشغيل محلي للمعاينة:" -ForegroundColor Cyan
Write-Host "  cd backend; python app.py" -ForegroundColor Gray
Write-Host "  npx --yes serve `"$OutputDir`"" -ForegroundColor Gray

if ($OpenOutput) {
    Start-Process explorer.exe $OutputDir
}
