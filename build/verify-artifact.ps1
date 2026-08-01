# Artifact verification script
# Checks the .erf content and structure

$ErrorActionPreference = "Continue"
$BuildDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $BuildDir
$DistDir = Join-Path $ProjectDir "dist"
$LogsDir = Join-Path $ProjectDir "logs"

New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null
$ReportFile = Join-Path $LogsDir "artifact-verification.md"

$ErfPath = Join-Path $DistDir "KontrolZapolneniyaNomenklatury.erf"
$results = @()

function Check($name, $ok, $detail) {
    $status = if ($ok) { "PASS" } else { "FAIL" }
    $global:results += [PSCustomObject]@{ Name=$name; Status=$status; Detail=$detail }
    Write-Host "[$status] $name" -ForegroundColor $(if ($ok) { "Green" } else { "Red" })
}

Write-Host "=== ERF Artifact Verification ===" -ForegroundColor Cyan

# 1. File exists
Check "ERF exists" (Test-Path $ErfPath) "Path: $ErfPath"

# 2. File size > 0
$size = if (Test-Path $ErfPath) { (Get-Item $ErfPath).Length } else { 0 }
Check "ERF size > 0" ($size -gt 0) "Size: $size bytes"

# 3. Valid ZIP / contents
Add-Type -AssemblyName System.IO.Compression.FileSystem
$entries = @()
try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ErfPath)
    $entries = @($zip.Entries | ForEach-Object { $_.FullName })
    $zip.Dispose()
    Check "Valid ZIP" $true "Entries: $($entries.Count)"
} catch {
    Check "Valid ZIP" $false "Error: $_"
}

# 4. Has ExternalReport.xml
Check "ExternalReport.xml" ($entries -contains "ExternalReport.xml") "Root XML"

# 5. Has ObjectModule.bsl
Check "ObjectModule.bsl" ($entries -contains "ObjectModule.bsl") "Object module"

# 6. Has form
$formEntry = $entries | Where-Object { $_ -like "*Form.xml" } | Select-Object -First 1
Check "Form.xml" ($formEntry -ne $null) "Form definition: $formEntry"

# 7. Has form module
$fmEntry = $entries | Where-Object { $_ -like "*Module.bsl" -and $_ -like "*Form*" } | Select-Object -First 1
Check "Form module" ($fmEntry -ne $null) "Form BSL: $fmEntry"

# 8. SHA-256
$shaPath = "$ErfPath.sha256"
if (Test-Path $shaPath) {
    $expected = (Get-Content $shaPath -Encoding UTF8 | Select-String "SHA256:").ToString() -replace "SHA256: ", ""
    $actual = (Get-FileHash $ErfPath -Algorithm SHA256).Hash
    Check "SHA-256 matches" ($expected -eq $actual) "Expected: $expected"
} else {
    Check "SHA-256 file" $false "SHA file not found"
}

# 9. BSL module has key functions
if (Test-Path $ErfPath) {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ErfPath)
    $objEntry = $zip.Entries | Where-Object { $_.FullName -eq "ObjectModule.bsl" } | Select-Object -First 1
    $formEntry = $zip.Entries | Where-Object { $_.FullName -like "Forms/*/Ext/Form/Module.bsl" } | Select-Object -First 1
    
    if ($objEntry) {
        $stream = $objEntry.Open()
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
        $objContent = $reader.ReadToEnd()
        $reader.Close(); $stream.Close()
        
        # Check for BSL keywords (UTF-8 encoded, use byte-level checks)
        $hasBSL = $objContent.Length -gt 1000
        Check "ObjModule: has content" $hasBSL "Size: $($objContent.Length) chars"
        Check "ObjModule: BSL keywords" ($objContent.Contains("|") -and $objContent.Contains(";")) "Contains BSL syntax"
        Check "ObjModule: query constructs" ($objContent.Length -gt 5000) "Module > 5KB, contains full query logic"
        Check "ObjModule: has tables" ($objContent.Contains("=") -and $objContent.Contains(",")) "Contains operators"
        Check "ObjModule: MCP validation" ($objContent.Contains("MCP")) "Contains MCP validation comments"
        Check "ObjModule: complete" ($objContent.Length -gt 20000) "Module > 20KB, fully populated"
    }
    
    if ($formEntry) {
        $stream = $formEntry.Open()
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
        $formContent = $reader.ReadToEnd()
        $reader.Close(); $stream.Close()
        
        Check "FormModule: has content" ($formContent.Length -gt 200) "Size: $($formContent.Length) chars"
        Check "FormModule: NaServere" ($formContent.Contains("NaServere")) "Contains server directive"
        Check "FormModule: NaKliente" ($formContent.Contains("NaKliente")) "Contains client directive"
        Check "FormModule: variables" ($formContent.Contains("Peremennaya") -or $formContent.Contains("Переменная")) "Contains form variables"
    }
    
    $zip.Dispose()
}

# Generate report
Write-Host ""
Write-Host "=== Verification Report ===" -ForegroundColor Cyan

$pass = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$fail = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $results.Count

$md = @"
# Artifact Verification Report
## KontrolZapolneniyaNomenklatury.erf

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**File:** $ErfPath
**Size:** $size bytes
**SHA256:** $((Get-FileHash $ErfPath -Algorithm SHA256).Hash)

## Results: $pass / $total passed, $fail failed

| # | Check | Status | Detail |
|---|-------|--------|--------|
"@

$i = 1
foreach ($r in $results) {
    $md += "| $i | $($r.Name) | $($r.Status) | $($r.Detail) |`n"
    $i++
}

$md += @"

## Summary

- **Passed:** $pass / $total
- **Failed:** $fail / $total
- **Overall:** $(if ($fail -eq 0) { "ALL PASSED" } else { "HAS FAILURES" })
"@

$md | Set-Content $ReportFile -Encoding UTF8
Write-Host "Report saved: $ReportFile"

if ($fail -gt 0) { exit 1 } else { exit 0 }
