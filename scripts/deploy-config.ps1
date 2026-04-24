<#
.SYNOPSIS
  Deploy claude_desktop_config.json for Claude Cowork 3P using SecureString
  prompts — no API keys or UUIDs ever land in PowerShell history, logs, or
  files on disk until the final config is written.

.DESCRIPTION
  This script:

    1. Resolves the active Cowork config directory (Store vs direct install)
       by calling .\find-cowork-config.ps1.
    2. Prompts for the Ask Sage API key as a SecureString (characters are
       masked at input and the plaintext is only held in an unmanaged BSTR
       long enough to be written to disk).
    3. Reads the repo template claude_desktop_config.json, substitutes the
       placeholder, and writes the result as UTF-8 without BOM (Cowork's
       JSON parser rejects a BOM on Windows).
    4. Scrubs the plaintext from memory (ZeroFreeBSTR + Remove-Variable +
       [GC]::Collect()) before returning.
    5. Runs a 10-check validation pass on the written file.

  UUID field handling: per v1.3 the deploymentOrganizationUuid field is
  removed from the template entirely. Cowork does not require it for
  individual 3P setups with a gateway inference provider. If the template
  still contains PASTE_YOUR_UUID_HERE for any reason, this script strips
  the whole line rather than prompting for a value.

.PARAMETER TemplatePath
  Path to the repo template. Defaults to ..\claude_desktop_config.json
  relative to this script.

.PARAMETER DryRun
  Validate inputs and print the resolved target path without writing.

.EXAMPLE
  PS> cd claude-cowork-asksage-quickstart
  PS> .\scripts\deploy-config.ps1
  [prompts for Ask Sage key — input masked]
  [writes config, runs 10 validation checks, prints ✓ for each]

.EXAMPLE
  PS> .\scripts\deploy-config.ps1 -DryRun
  Would write: C:\Users\jane\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\...
#>

[CmdletBinding()]
param(
    [string]$TemplatePath,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $TemplatePath) {
    $TemplatePath = Join-Path (Split-Path -Parent $scriptDir) 'claude_desktop_config.json'
}

if (-not (Test-Path $TemplatePath)) {
    throw "Template not found: $TemplatePath"
}

# ---------------------------------------------------------------------------
# 1. Resolve target directory.
# ---------------------------------------------------------------------------
$finder = Join-Path $scriptDir 'find-cowork-config.ps1'
if (-not (Test-Path $finder)) {
    throw "Missing dependency: $finder"
}
$targetDir = & $finder
if (-not $targetDir) { throw 'find-cowork-config.ps1 returned no path.' }

$targetFile = Join-Path $targetDir 'claude_desktop_config.json'
Write-Host "[deploy-config] Target: $targetFile" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host '[deploy-config] DryRun — exiting without writing.' -ForegroundColor Yellow
    return
}

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Write-Host "[deploy-config] Created $targetDir" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# 2. Prompt for the Ask Sage key as SecureString.
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Paste your Ask Sage API key. Input is masked.' -ForegroundColor Yellow
$secure = Read-Host -AsSecureString 'Ask Sage API key'
if ($secure.Length -eq 0) { throw 'No key entered — aborting.' }

$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)

    # ------------------------------------------------------------------
    # 3. Render template → final JSON.
    # ------------------------------------------------------------------
    $raw = Get-Content -Raw -LiteralPath $TemplatePath

    # Strip the UUID line entirely (v1.3: field is optional for 3P gateway
    # setups and we don't prompt for it). Match the whole line incl.
    # trailing comma so we don't leave a stray "," that breaks JSON.
    $raw = [regex]::Replace(
        $raw,
        '\s*"deploymentOrganizationUuid"\s*:\s*"[^"]*"\s*,?\r?\n',
        [System.Environment]::NewLine,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    # Sanity: fail loudly if template still contains a placeholder we
    # didn't expect to survive this rewrite.
    if ($raw -match 'PASTE_YOUR_UUID_HERE') {
        throw 'Template still contains PASTE_YOUR_UUID_HERE after strip — refusing to write.'
    }

    $final = $raw -replace 'PASTE_YOUR_ASKSAGE_KEY_HERE', $plain

    if ($final -match 'PASTE_YOUR_ASKSAGE_KEY_HERE') {
        throw 'Key placeholder substitution failed — refusing to write.'
    }

    # Validate it parses as JSON before writing.
    try { $final | ConvertFrom-Json -ErrorAction Stop | Out-Null }
    catch { throw "Rendered config is not valid JSON: $($_.Exception.Message)" }

    # ------------------------------------------------------------------
    # 4. Write UTF-8 WITHOUT BOM. Set-Content -Encoding UTF8 writes a BOM;
    #    [System.IO.File]::WriteAllText with UTF8Encoding($false) does not.
    # ------------------------------------------------------------------
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($targetFile, $final, $utf8NoBom)
    Write-Host "[deploy-config] Wrote $targetFile" -ForegroundColor Green
}
finally {
    # ------------------------------------------------------------------
    # 5. Scrub plaintext from memory.
    # ------------------------------------------------------------------
    if ($bstr -ne [IntPtr]::Zero) {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    if (Get-Variable -Name plain -Scope Local -ErrorAction SilentlyContinue) {
        Remove-Variable plain -Scope Local
    }
    if (Get-Variable -Name final -Scope Local -ErrorAction SilentlyContinue) {
        Remove-Variable final -Scope Local
    }
    if (Get-Variable -Name raw -Scope Local -ErrorAction SilentlyContinue) {
        Remove-Variable raw -Scope Local
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

# ---------------------------------------------------------------------------
# 6. Validation — 10 checks. Each prints ✓ or ✗. Script exits non-zero on
#    any failure so CI / callers can catch it.
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Validating deployed config...' -ForegroundColor Cyan

$checks = @()
$cfg = Get-Content -Raw -LiteralPath $targetFile | ConvertFrom-Json

$checks += @{ Name = 'File exists';                 Pass = (Test-Path $targetFile) }
$checks += @{ Name = 'File is non-empty';           Pass = ((Get-Item $targetFile).Length -gt 0) }
$checks += @{ Name = 'Parses as JSON';              Pass = ($null -ne $cfg) }
$checks += @{ Name = 'deploymentMode = "3p"';       Pass = ($cfg.deploymentMode -eq '3p') }
$checks += @{ Name = 'enterpriseConfig present';    Pass = ($null -ne $cfg.enterpriseConfig) }
$checks += @{ Name = 'inferenceProvider = gateway'; Pass = ($cfg.enterpriseConfig.inferenceProvider -eq 'gateway') }
$checks += @{ Name = 'Ask Sage URL correct';
              Pass = ($cfg.enterpriseConfig.inferenceGatewayBaseUrl -eq 'https://api.asksage.ai/server/anthropic') }
$checks += @{ Name = 'API key length plausible (>=20)';
              Pass = ($cfg.enterpriseConfig.inferenceGatewayApiKey.Length -ge 20) }
$checks += @{ Name = 'No placeholder leaked';
              Pass = -not (Select-String -Path $targetFile -Pattern 'PASTE_YOUR_' -Quiet) }
# UTF-8-BOM check: read first 3 bytes; byte sequence 0xEF 0xBB 0xBF is the BOM.
$bomBytes = [System.IO.File]::ReadAllBytes($targetFile) | Select-Object -First 3
$hasBom = ($bomBytes.Count -ge 3 -and $bomBytes[0] -eq 0xEF -and $bomBytes[1] -eq 0xBB -and $bomBytes[2] -eq 0xBF)
$checks += @{ Name = 'UTF-8 without BOM'; Pass = (-not $hasBom) }

$fail = 0
foreach ($c in $checks) {
    if ($c.Pass) {
        Write-Host ("  [OK]   {0}" -f $c.Name) -ForegroundColor Green
    } else {
        Write-Host ("  [FAIL] {0}" -f $c.Name) -ForegroundColor Red
        $fail++
    }
}

Write-Host ''
if ($fail -eq 0) {
    Write-Host "All 10 checks passed. Fully quit Claude Desktop (system tray - Quit), then relaunch." -ForegroundColor Green
} else {
    Write-Host "$fail check(s) failed. Review $targetFile before launching Claude." -ForegroundColor Red
    exit 1
}
