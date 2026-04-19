# Somax Ship Automation Script
# Usage: ./scripts/ship.ps1 -Version "2.0.0+3" [-Channel "stable"|"preview"]

param (
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [ValidateSet("stable", "preview")]
    [string]$Channel = "stable"
)

$ErrorActionPreference = "Stop"

function Get-FlutterCommand {
    $localPropertiesPath = "android/local.properties"
    if (Test-Path $localPropertiesPath) {
        $flutterSdkLine = Get-Content $localPropertiesPath | Where-Object { $_ -like "flutter.sdk=*" } | Select-Object -First 1
        if ($flutterSdkLine) {
            $flutterSdk = ($flutterSdkLine -split "=", 2)[1].Replace("\\", "\")
            $flutterBat = Join-Path $flutterSdk "bin\flutter.bat"
            if (Test-Path $flutterBat) {
                return $flutterBat
            }
        }
    }

    return "flutter"
}

function Get-ReleaseSql {
    param (
        [string]$ReleaseVersion,
        [string]$ApkSha256,
        [string]$ReleaseChannel,
        [string]$UpdateUrl
    )

@"
UPDATE app_version_config
SET latest_version = '$ReleaseVersion',
    update_url = '$UpdateUrl',
    apk_sha256 = '$ApkSha256',
    whats_new = '["Melhorias de performance", "Correções de estabilidade"]',
    channel = '$ReleaseChannel',
    updated_at = NOW()
WHERE channel = '$ReleaseChannel';
"@
}

Write-Host "[SHIP] Iniciando Somax Ship via Surge.sh para a versao: $Version ($Channel)" -ForegroundColor Cyan

$flutterCommand = Get-FlutterCommand
$apkPath = "build/app/outputs/flutter-apk/app-release.apk"
$publicApkFileName = if ($Channel -eq "preview") { "somax-preview.apk" } else { "somax.apk" }
$publicApkPath = "public/$publicApkFileName"
$publicApkUrl = "https://somax-app.surge.sh/$publicApkFileName"
$releaseMetadataDir = "build/release_metadata"

# 1. Atualizar pubspec.yaml
Write-Host "[1/5] Atualizando pubspec.yaml..." -ForegroundColor Yellow
$pubspecPath = "pubspec.yaml"
if (Test-Path $pubspecPath) {
    $content = Get-Content $pubspecPath -Raw
    $newContent = $content -replace "version: .*", "version: $Version"
    $newContent | Set-Content $pubspecPath -NoNewline
} else {
    Write-Host "X Erro: pubspec.yaml nao encontrado!" -ForegroundColor Red
    exit 1
}

# 2. Build Release APK
Write-Host "[2/5] Gerando build release APK..." -ForegroundColor Yellow
& $flutterCommand build apk --release --tree-shake-icons
if ($LASTEXITCODE -ne 0) {
    Write-Host "X Erro no build do Flutter!" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $apkPath)) {
    Write-Host "X Erro: APK nao encontrado em $apkPath" -ForegroundColor Red
    exit 1
}

# 3. Gerar checksum e SQL do release
Write-Host "[3/5] Gerando SHA-256 e SQL do release..." -ForegroundColor Yellow
$apkHash = (Get-FileHash $apkPath -Algorithm SHA256).Hash.ToUpper()
$sql = Get-ReleaseSql -ReleaseVersion $Version -ApkSha256 $apkHash -ReleaseChannel $Channel -UpdateUrl $publicApkUrl

if (!(Test-Path $releaseMetadataDir)) {
    New-Item -ItemType Directory -Path $releaseMetadataDir | Out-Null
}

$slug = $Version.Replace("+", "_")
$sqlPath = Join-Path $releaseMetadataDir "release_${Channel}_$slug.sql"
$latestSqlPath = Join-Path $releaseMetadataDir "latest_${Channel}_release.sql"
$summaryPath = Join-Path $releaseMetadataDir "release_${Channel}_$slug.txt"

$sql | Set-Content $sqlPath
$sql | Set-Content $latestSqlPath
@(
    "version=$Version"
    "channel=$Channel"
    "apk_path=$(Resolve-Path $apkPath)"
    "public_apk=$publicApkUrl"
    "apk_sha256=$apkHash"
    "sql_path=$(Resolve-Path $sqlPath)"
) | Set-Content $summaryPath

# 4. Copiar APK para pasta public
Write-Host "[4/5] Movendo APK para a pasta de deploy..." -ForegroundColor Yellow
if (!(Test-Path "public")) {
    New-Item -ItemType Directory -Path "public" | Out-Null
}
Copy-Item $apkPath $publicApkPath -Force

# 5. Deploy no Surge.sh
Write-Host "[5/5] Fazendo deploy no Surge.sh..." -ForegroundColor Yellow
npx surge ./public somax-app.surge.sh

if ($LASTEXITCODE -ne 0) {
    Write-Host "X Erro no deploy do Surge!" -ForegroundColor Red
    exit 1
}

Write-Host "SUCCESS: O app versao $Version ($Channel) esta no ar via Surge!" -ForegroundColor Green
Write-Host "Link: $publicApkUrl" -ForegroundColor Blue
Write-Host "SHA-256: $apkHash" -ForegroundColor Cyan
Write-Host "SQL salvo em: $(Resolve-Path $sqlPath)" -ForegroundColor Cyan
Write-Host "Ultimo SQL salvo em: $(Resolve-Path $latestSqlPath)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cole este SQL no Supabase apos subir o APK com link direto:" -ForegroundColor Yellow
Write-Host $sql
