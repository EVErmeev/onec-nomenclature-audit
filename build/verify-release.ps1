# verify-release.ps1 - Release consistency check for KontrolAudit ERF
param(
	$ErfPath = "dist\КонтрольЗаполненияНоменклатуры.erf",
	$ShaPath  = "dist\КонтрольЗаполненияНоменклатуры.erf.sha256",
	$ManifestPath = "dist\release-manifest.json",
	$DumpDir  = "build\dump_output",
	$SourceXml = "src\KontrolAudit.xml"
)

$ErrorActionPreference = "Continue"
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ProjectDir

$ErfPath    = if ([System.IO.Path]::IsPathRooted($ErfPath)) { $ErfPath } else { Join-Path $ProjectDir $ErfPath }
$ShaPath    = if ([System.IO.Path]::IsPathRooted($ShaPath)) { $ShaPath } else { Join-Path $ProjectDir $ShaPath }
$ManifestPath = if ([System.IO.Path]::IsPathRooted($ManifestPath)) { $ManifestPath } else { Join-Path $ProjectDir $ManifestPath }
$DumpDir    = if ([System.IO.Path]::IsPathRooted($DumpDir)) { $DumpDir } else { Join-Path $ProjectDir $DumpDir }
$SourceXml  = if ([System.IO.Path]::IsPathRooted($SourceXml)) { $SourceXml } else { Join-Path $ProjectDir $SourceXml }

$script:errors = 0
$CYRILLIC_SYNONYM    = [System.Text.Encoding]::UTF8.GetString(@(208,154,208,190,208,189,209,130,209,128,208,190,208,187,209,140,32,208,183,208,176,208,191,208,190,208,187,208,189,208,181,208,189,208,184,209,143,32,208,189,208,190,208,188,208,181,208,189,208,186,208,187,208,176,209,130,209,131,209,128,209,139))
$KANON_NAME           = "KontrolAudit"
$KANON_DEFFORM        = "ExternalReport.KontrolAudit.Form.MainForm"
$BASELINE_ERF_BLOB    = "6507ce694b0ec1e64314772d6b2bbe954b909905"

function Check($name, $ok, $detail) {
    $status = if ($ok) { "PASS" } else { $script:errors++; "FAIL" }
    $color = if ($ok) { "Green" } else { "Red" }
    Write-Host "[$status] $name" -ForegroundColor $color
    if ($detail) { Write-Host "       $detail" }
}

function Get-XmlTag($content, $tag) {
    $pattern = "<" + $tag + ">([^<]*)</" + $tag + ">"
    $m = [regex]::Match($content, $pattern)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return ""
}

function Get-XmlAttr($content, $elem, $attr) {
    $p = "<" + $elem + '[^>]*' + $attr + '="([^"]*)"'
    $m = [regex]::Match($content, $p)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return ""
}

Write-Host "=== KontrolAudit Release Verification ===" -ForegroundColor Cyan

# 1
$ok = Test-Path $ErfPath
Check "ERF file exists" $ok $ErfPath
if (-not $ok) { Write-Host "ABORTED"; exit 1 }

# 2
$bytes = [IO.File]::ReadAllBytes($ErfPath)
$isZip = ($bytes[0] -eq 0x50 -and $bytes[1] -eq 0x4B)
$hdr = [BitConverter]::ToString($bytes[0..3])
Check "ERF is not ZIP" (-not $isZip) "Header: $hdr"

# 3
$size = $bytes.Length
Check "ERF size > 0" ($size -gt 0) "$size bytes"

# 4
$actualHash = (Get-FileHash $ErfPath -Algorithm SHA256).Hash
if (Test-Path $ShaPath) {
    $sc = Get-Content $ShaPath -Encoding UTF8 -Raw
    $m = [regex]::Match($sc, 'SHA256:\s*([A-F0-9]{64})')
    $eh = if ($m.Success) { $m.Groups[1].Value } else { "" }
    Check "SHA256 matches .sha256" ($eh -eq $actualHash) ""
} else {
    Check "SHA256 file exists" $false "Missing"
}

# 5
$gs = & git status --porcelain -- "$ErfPath" 2>$null
Check "ERF tracked in Git (clean)" (-not $gs) "$gs"

# 6
$cb = & git hash-object "$ErfPath" 2>$null
Check "ERF blob != baseline" ($cb -ne $BASELINE_ERF_BLOB) "Current: $cb"

# 7
$dumpXml = Join-Path $DumpDir "KontrolAudit.xml"
$de = Test-Path $dumpXml
Check "Dump exists" $de $dumpXml

if ($de) {
    $dc = Get-Content $dumpXml -Encoding UTF8 -Raw
    $dn = Get-XmlTag $dc "Name"
    Check "Dump Name = $KANON_NAME" ($dn -eq $KANON_NAME) "Found: $dn"
    $df = Get-XmlTag $dc "DefaultForm"
    Check "Dump DefaultForm = $KANON_DEFFORM" ($df -eq $KANON_DEFFORM) "Found: $df"
    $ascii = [Text.Encoding]::UTF8.GetBytes($dn).Count -eq $dn.Length
    Check "Dump Name is ASCII-only" $ascii ""
    Check "Dump has Synonym (Cyrillic)" $dc.Contains($CYRILLIC_SYNONYM) ""

    $dmp = Join-Path $DumpDir "KontrolAudit\Ext\ObjectModule.bsl"
    $me = Test-Path $dmp
    Check "ObjectModule.bsl in dump" $me ""
    if ($me) {
        $mc = Get-Content $dmp -Encoding UTF8 -Raw
        Check "Has EmptyString param" $mc.Contains('&') ""
        Check "Has CreateQueryDupNames" $mc.Contains('Create') ""
        $hasBroken = ($mc.Length -lt 1000)
        Check "ObjectModule has content" (-not $hasBroken) "$($mc.Length) chars"
    }
}

# 8
$rok = Test-Path $SourceXml
if ($rok) {
    $src = Get-Content $SourceXml -Encoding UTF8 -Raw
    Check "Source Name = $KANON_NAME" ((Get-XmlTag $src "Name") -eq $KANON_NAME) ""
    Check "Source DefaultForm correct" ((Get-XmlTag $src "DefaultForm") -eq $KANON_DEFFORM) ""
    $ru = Get-XmlAttr $src "ExternalReport" "uuid"

    $fmp = Join-Path $ProjectDir "src\KontrolAudit\Forms\MainForm.xml"
    if (Test-Path $fmp) {
        $fm = Get-Content $fmp -Encoding UTF8 -Raw
        $fu = Get-XmlAttr $fm "Form" "uuid"
        Check "Report UUID != Form UUID" ($ru -ne $fu) "Rpt: $ru / Frm: $fu"
    }
}

# 9
Check "Release manifest exists" (Test-Path $ManifestPath) ""
if (Test-Path $ManifestPath) {
    $mf = Get-Content $ManifestPath -Encoding UTF8 -Raw | ConvertFrom-Json
    Check "Manifest name = $KANON_NAME" ($mf.internalName -eq $KANON_NAME) ""
    Check "Manifest SHA256 matches" ($mf.sha256 -eq $actualHash) ""
    Check "Manifest size matches" ($mf.sizeBytes -eq $size) ""
}

# 10
$dupCount = @(Get-ChildItem -Recurse -LiteralPath $ProjectDir -Filter "ObjectModule.bsl" -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch 'dump_output' -and $_.FullName -notmatch '\\tools\\' -and $_.FullName -notmatch '\\.git\\'
}).Count
Check "Single ObjectModule.bsl in src" ($dupCount -le 1) "Count: $dupCount"

Write-Host ""
$c = if ($script:errors -eq 0) { "Green" } else { "Red" }
Write-Host "=== Result: $script:errors error(s) ===" -ForegroundColor $c
if ($script:errors -gt 0) {
    exit 1
}
exit 0