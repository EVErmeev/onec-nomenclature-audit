# Build script for external report "КонтрольЗаполненияНоменклатуры"
# 
# Method: 1C Configurator batch mode (/LoadExternalDataProcessorOrReportFromFiles)
# ZIP-fallback is FORBIDDEN per project requirements.
#
# Environment variables:
#   ONEC_EXE       - path to 1cv8.exe
#   ONEC_IB_PATH   - path to file-based infobase
#   ONEC_USER      - 1C user name
#   ONEC_PASSWORD  - 1C user password

$ErrorActionPreference = "Stop"
$BuildDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $BuildDir
$SrcDir = Join-Path $ProjectDir "src"
$DistDir = Join-Path $ProjectDir "dist"
$LogsDir = Join-Path $ProjectDir "logs"

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null

$LogFile = Join-Path $LogsDir "build.log"
$ErfPath = Join-Path $DistDir "КонтрольЗаполненияНоменклатуры.erf"

Remove-Item $LogFile -ErrorAction SilentlyContinue

Write-Host "=== External Report Build ===" -ForegroundColor Cyan

# Check sources first
Write-Host "[1] Checking sources..."
$RootXml = Join-Path $SrcDir "КонтрольЗаполненияНоменклатуры.xml"
if (-not (Test-Path $RootXml)) { Write-Host "ERROR: $RootXml not found" -ForegroundColor Red; exit 1 }
if (-not (Test-Path (Join-Path $SrcDir "КонтрольЗаполненияНоменклатуры\Ext\ObjectModule.bsl"))) { Write-Host "ERROR: ObjectModule.bsl not found" -ForegroundColor Red; exit 1 }
if (-not (Test-Path (Join-Path $SrcDir "КонтрольЗаполненияНоменклатуры\Forms\MainForm\Ext\Form.xml"))) { Write-Host "ERROR: Form.xml not found" -ForegroundColor Red; exit 1 }
if (-not (Test-Path (Join-Path $SrcDir "КонтрольЗаполненияНоменклатуры\Forms\MainForm\Ext\Form\Module.bsl"))) { Write-Host "ERROR: Form module not found" -ForegroundColor Red; exit 1 }
Write-Host "  OK: all source files present"

# Try Configurator first
$OneCExe = $env:ONEC_EXE
if (-not $OneCExe) {
    if (Test-Path "C:\Program Files\1cv8\8.3.27.1559\bin\1cv8.exe") {
        $OneCExe = "C:\Program Files\1cv8\8.3.27.1559\bin\1cv8.exe"
    } elseif (Test-Path "C:\Program Files\1cv8\8.3.27.1688\bin\1cv8s.exe") {
        $OneCExe = "C:\Program Files\1cv8\8.3.27.1688\bin\1cv8s.exe"
    }
}

$IbPath = $env:ONEC_IB_PATH
if (-not $IbPath) {
    if ((Test-Path "F:\UT_DEMO_HTTP\default.vrd") -and ((Get-Content "F:\UT_DEMO_HTTP\default.vrd" -Raw) -match 'File="([^"]+)"')) {
        $IbPath = $Matches[1]
    }
}
if (-not $IbPath) { $IbPath = "F:\UT_Demo" }
$OneCUser = if ($env:ONEC_USER) { $env:ONEC_USER } else { "Admin" }
$OneCPass = if ($env:ONEC_PASSWORD) { $env:ONEC_PASSWORD } else { "" }

$configuratorWorked = $false
if ((Test-Path $OneCExe) -and (Test-Path $IbPath)) {
    Write-Host "[2] Trying Configurator: $OneCExe"
    Write-Host "  Base: $IbPath, User: $OneCUser"
    
    $passArgs = if ($OneCPass) { @("/P", $OneCPass) } else { @() }
    $buildArgs = @("DESIGNER", "/F", $IbPath, "/N", $OneCUser) + $passArgs + @(
        "/LoadExternalDataProcessorOrReportFromFiles", $RootXml, $ErfPath,
        "/Out", $LogFile
    )
    
    $proc = Start-Process -FilePath $OneCExe -ArgumentList $buildArgs -NoNewWindow -Wait -PassThru
    Write-Host "  Exit code: $($proc.ExitCode)"
    
    if ((Test-Path $ErfPath) -and ((Get-Item $ErfPath).Length -gt 0)) {
        $configuratorWorked = $true
        Write-Host "  OK: .erf built by Configurator" -ForegroundColor Green
    } else {
        Write-Host "  Configurator did not produce .erf"
        if (Test-Path $LogFile) {
            Write-Host "  Log:"
            Get-Content $LogFile -Encoding UTF8 | ForEach-Object { Write-Host "    $_" }
        }
    }
}

if (-not $configuratorWorked) {
    Write-Host "ERROR: Configurator failed to build .erf" -ForegroundColor Red
    if (Test-Path $LogFile) {
        Write-Host "  Log:"
        Get-Content $LogFile -Encoding UTF8 | ForEach-Object { Write-Host "    $_" }
    }
    Write-Host "ZIP-fallback is FORBIDDEN per project requirements." -ForegroundColor Red
    exit 1
}

# SHA-256
Write-Host "[3] Computing SHA-256..."
$size = (Get-Item $ErfPath).Length
$hash = (Get-FileHash $ErfPath -Algorithm SHA256).Hash
$platformVer = if ($OneCExe) { Split-Path (Split-Path (Split-Path $OneCExe -Parent) -Parent) -Leaf } else { "unknown" }

$shaFile = "$ErfPath.sha256"
@"
File: КонтрольЗаполненияНоменклатуры.erf
SHA256: $hash
Build date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Size: $size bytes
Platform: $platformVer
Method: Configurator (/LoadExternalDataProcessorOrReportFromFiles)
Base: $IbPath
"@ | Set-Content $shaFile -Encoding UTF8

Write-Host "  SHA256: $hash" -ForegroundColor Green
Write-Host "  Size: $size bytes"
Write-Host ""
Write-Host "=== Build complete ===" -ForegroundColor Green
Write-Host "  Output: $ErfPath"
Write-Host "  SHA256: $shaFile"
exit 0
