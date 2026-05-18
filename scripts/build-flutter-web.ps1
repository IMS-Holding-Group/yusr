#Requires -Version 5.1
<#
.SYNOPSIS
  Build Flutter Web for Render Static Site (no Docker).

.EXAMPLE
  .\scripts\build-flutter-web.ps1

.EXAMPLE
  .\scripts\build-flutter-web.ps1 -ApiBaseUrl "https://yusr-1l5c.onrender.com" -OpenOutput
#>
[CmdletBinding()]
param(
    [string] $ApiBaseUrl = "https://yusr-1l5c.onrender.com",
    [string] $OutputDir = "",
    [switch] $SkipPubGet,
    [switch] $SkipBackendCheck,
    [switch] $OpenOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$FlutterDir = Join-Path $RepoRoot "flutter_app"
$DeployDir = Join-Path $RepoRoot "deploy"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $DeployDir "dist\web"
}

$ApiBaseUrl = $ApiBaseUrl.Trim().TrimEnd("/")
if ($ApiBaseUrl -notmatch '^https?://') {
    throw "ApiBaseUrl must start with http:// or https:// (got: $ApiBaseUrl)"
}

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-CommandExists([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-Flutter {
    param([string[]]$FlutterArgs)
    Push-Location $FlutterDir
    try {
        & flutter @FlutterArgs
        if ($LASTEXITCODE -ne 0) {
            throw "flutter failed: flutter $($FlutterArgs -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "=== Yusr - Flutter Web build for Render ===" -ForegroundColor Yellow
Write-Host ""

Write-Step "Check tools"
if (-not (Test-CommandExists "flutter")) {
    throw "Flutter not found in PATH. Install: https://docs.flutter.dev/get-started/install"
}
if (-not (Test-Path $FlutterDir)) {
    throw "flutter_app folder not found: $FlutterDir"
}

$flutterVersion = (flutter --version 2>&1 | Select-Object -First 1)
Write-Host "  $flutterVersion" -ForegroundColor Gray

Write-Step "Enable web"
Invoke-Flutter @("config", "--enable-web")

Write-Step "Clean previous build"
Invoke-Flutter @("clean")

if (-not $SkipPubGet) {
    Write-Step "pub get"
    Invoke-Flutter @("pub", "get")
}

Write-Step "Analyze (non-blocking)"
$prevEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
Push-Location $FlutterDir
flutter analyze --no-fatal-infos *> $null
$analyzeExit = $LASTEXITCODE
Pop-Location
$ErrorActionPreference = $prevEap
if ($analyzeExit -ne 0) {
    Write-Host "  Analyze reported issues (continuing build)." -ForegroundColor Yellow
}

if (-not $SkipBackendCheck) {
    Write-Step "Backend health check"
    if (Test-CommandExists "python") {
        $healthUrl = "$ApiBaseUrl/health"
        try {
            $resp = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 12
            if ($resp.StatusCode -eq 200) {
                Write-Host "  OK: $healthUrl" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  WARN: cannot reach $healthUrl" -ForegroundColor Yellow
            Write-Host "  Use -SkipBackendCheck to skip this check." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  Python not found, skipping health check." -ForegroundColor Yellow
    }
}

Write-Step "Build web (release)"
Write-Host "  API_BASE_URL = $ApiBaseUrl" -ForegroundColor Gray

Invoke-Flutter @(
    "build", "web",
    "--release",
    "--base-href", "/",
    "--dart-define=API_BASE_URL=$ApiBaseUrl"
)

$buildWeb = Join-Path $FlutterDir "build\web"
$indexInBuild = Join-Path $buildWeb "index.html"
if (-not (Test-Path $indexInBuild)) {
    throw "build/web/index.html missing. See errors above."
}

$BackendWebDir = Join-Path $RepoRoot "backend\static\web"

Write-Step "Copy to $OutputDir"
if (Test-Path $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Copy-Item -Path (Join-Path $buildWeb "*") -Destination $OutputDir -Recurse -Force

Write-Step "Copy to backend/static/web (Flask serves app on same URL)"
if (Test-Path $BackendWebDir) {
    Remove-Item -Recurse -Force $BackendWebDir
}
New-Item -ItemType Directory -Path $BackendWebDir -Force | Out-Null
Copy-Item -Path (Join-Path $buildWeb "*") -Destination $BackendWebDir -Recurse -Force

$redirectsPath = Join-Path $OutputDir "_redirects"
Set-Content -Path $redirectsPath -Value "/*    /index.html   200" -Encoding ASCII

Write-Step "Write config files"
$envRenderPath = Join-Path $DeployDir "render.env.generated"
$envLines = @(
    "# Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "# Copy to Render dashboard -> Environment",
    "",
    "# yusr-api",
    "DATABASE_PATH=data/yusr.db",
    "CORS_ORIGINS=https://yusr-1l5c.onrender.com",
    "FLASK_DEBUG=false",
    "",
    "# build dart-define",
    "API_BASE_URL=$ApiBaseUrl"
)
Set-Content -Path $envRenderPath -Value $envLines -Encoding ASCII

$metaPath = Join-Path $OutputDir "yusr-build-info.json"
$meta = @{
    builtAt    = (Get-Date).ToString("o")
    apiBaseUrl = $ApiBaseUrl
    flutterDir = $FlutterDir
    outputDir  = $OutputDir
}
$meta | ConvertTo-Json | Set-Content -Path $metaPath -Encoding ASCII

Write-Host ""
Write-Host "BUILD OK" -ForegroundColor Green
Write-Host "  Output:     $OutputDir" -ForegroundColor Green
Write-Host "  Render env: $envRenderPath" -ForegroundColor Green
Write-Host ""
Write-Host "Deploy on Render:" -ForegroundColor Cyan
Write-Host "  1) git add backend/static/web deploy/dist/web" -ForegroundColor Gray
Write-Host "  2) git add backend/app.py" -ForegroundColor Gray
Write-Host "  3) git commit -m build web" -ForegroundColor Gray
Write-Host "  4) git push  (open https://yusr-1l5c.onrender.com)" -ForegroundColor Gray
Write-Host "  5) Render env: DATABASE_PATH=data/yusr.db" -ForegroundColor Gray
Write-Host ""
Write-Host "Preview locally:" -ForegroundColor Cyan
Write-Host "  npx --yes serve `"$OutputDir`"" -ForegroundColor Gray

if ($OpenOutput) {
    Start-Process explorer.exe $OutputDir
}
