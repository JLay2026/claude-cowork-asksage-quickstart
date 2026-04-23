<#
.SYNOPSIS
    Sideload the Anthropic knowledge-work plugins into Claude Cowork
    when outbound access to github.com is blocked by tenant egress policy.

.DESCRIPTION
    Takes a pre-downloaded ZIP of the anthropics/knowledge-work-plugins
    repository, extracts it to C:\Program Files\Claude\org-plugins, and
    registers the folder with Claude Code as a local marketplace so Cowork
    can install plugins from it without any network egress.

    Run this script AFTER you've already downloaded the repo ZIP on an
    unrestricted machine and transferred it to this workstation.

    Must be run in an elevated PowerShell session (C:\Program Files is
    protected by default).

.PARAMETER ZipPath
    Path to knowledge-work-plugins-main.zip. Defaults to the current user's
    Downloads folder.

.PARAMETER Destination
    Target install path. Defaults to C:\Program Files\Claude\org-plugins.

.PARAMETER SkipClaudeCli
    Skip the optional `claude plugin marketplace add` step. Use if Claude
    Code CLI isn't installed.

.EXAMPLE
    .\sideload-plugins.ps1

.EXAMPLE
    .\sideload-plugins.ps1 -ZipPath "D:\transfer\knowledge-work-plugins-main.zip"

.NOTES
    After this script completes, you still need to:
      1. Fully quit and relaunch Claude Desktop (system tray > Quit)
      2. In Cowork, open Customizations > Plugins and click Install on
         each plugin you want
#>

[CmdletBinding()]
param(
    [string]$ZipPath = "$env:USERPROFILE\Downloads\knowledge-work-plugins-main.zip",
    [string]$Destination = "C:\Program Files\Claude\org-plugins",
    [switch]$SkipClaudeCli
)

$ErrorActionPreference = "Stop"

# Verify elevation
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator. Right-click PowerShell and choose 'Run as administrator'."
    exit 1
}

# Verify ZIP exists
if (-not (Test-Path $ZipPath)) {
    Write-Error "ZIP not found at: $ZipPath`n`nDownload https://github.com/anthropics/knowledge-work-plugins (green Code button > Download ZIP) on an unrestricted machine and transfer it here first."
    exit 1
}

Write-Host "Sideload: Anthropic knowledge-work-plugins" -ForegroundColor Cyan
Write-Host "  Source: $ZipPath"
Write-Host "  Target: $Destination"
Write-Host ""

# Step 1 - Create destination
Write-Host "[1/4] Creating destination folder..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $Destination -Force | Out-Null

# Step 2 - Extract
Write-Host "[2/4] Extracting ZIP..." -ForegroundColor Yellow
Expand-Archive -Path $ZipPath -DestinationPath $Destination -Force

# Step 3 - Flatten (ZIP wraps contents in knowledge-work-plugins-main\)
$nested = Join-Path $Destination "knowledge-work-plugins-main"
if (Test-Path $nested) {
    Write-Host "[3/4] Flattening nested folder..." -ForegroundColor Yellow
    Get-ChildItem -Path $nested -Force | Move-Item -Destination $Destination -Force
    Remove-Item -Path $nested -Recurse -Force
} else {
    Write-Host "[3/4] (Already flat, skipping)" -ForegroundColor Yellow
}

# Verify the marketplace manifest landed correctly
$manifest = Join-Path $Destination ".claude-plugin\marketplace.json"
if (-not (Test-Path $manifest)) {
    Write-Error "Extraction completed but $manifest was not found. The ZIP may be corrupted or have an unexpected layout."
    exit 1
}

# Step 4 - Register with Claude Code CLI (optional but helpful)
if (-not $SkipClaudeCli) {
    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if ($claude) {
        Write-Host "[4/4] Registering local marketplace with Claude Code CLI..." -ForegroundColor Yellow
        try {
            & claude plugin marketplace add $Destination
        } catch {
            Write-Warning "Claude CLI registration failed: $_"
            Write-Warning "You can still register the marketplace manually from Cowork's Customizations UI."
        }
    } else {
        Write-Host "[4/4] Claude CLI not found on PATH - skipping auto-register." -ForegroundColor Yellow
        Write-Host "      You'll add the marketplace from the Cowork UI instead." -ForegroundColor Yellow
    }
} else {
    Write-Host "[4/4] Skipping Claude CLI registration (per flag)." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Sideload complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Fully quit Claude Desktop (system tray > Quit - not just close the window)."
Write-Host "  2. Relaunch Claude Desktop."
Write-Host "  3. Open Settings > Customizations > Plugins."
Write-Host "  4. If the marketplace isn't already listed, click 'Add marketplace' and paste:"
Write-Host "       $Destination" -ForegroundColor White
Write-Host "  5. Click Install on each plugin you want."
Write-Host ""
Write-Host "Recommended plugins (all bundled, no network needed):" -ForegroundColor Cyan
@(
    "cowork-plugin-management", "productivity", "enterprise-search",
    "sales", "customer-support", "product-management", "marketing",
    "legal", "finance", "data", "bio-research"
) | ForEach-Object { Write-Host "  - $_" }
