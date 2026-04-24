<#
.SYNOPSIS
  Install GitHub's official Go-based MCP server for Claude Cowork, and
  optionally register it in your claude_desktop_config.json as a Local MCP
  server.

.DESCRIPTION
  Why the Go binary:

    - The legacy npm package @modelcontextprotocol/server-github is
      deprecated and, on cold starts, `npx -y` downloads ~150 MB of node
      modules. Cowork enforces a 60-second MCP initialize handshake, so the
      first invocation times out on most machines.
    - GitHub now publishes an official, self-contained Go binary:
      github/github-mcp-server. Download, unzip, point Cowork at the exe,
      done. No Node required. Startup is under a second.

  What this script does:

    1. Downloads the latest (or pinned) GitHub MCP server release for
       Windows x64 to %LOCALAPPDATA%\Programs\github-mcp-server\.
    2. Extracts github-mcp-server.exe.
    3. Prompts for your GitHub Personal Access Token as a SecureString.
    4. Finds the active Cowork config via find-cowork-config.ps1.
    5. Adds/updates the "mcpServers" entry under the TOP-LEVEL key (NOT
       enterpriseConfig.managedMcpServers — that key is ignored for
       end-user installs; it only takes effect via signed MDM policy).
    6. Writes the updated config as UTF-8 without BOM.
    7. Scrubs the PAT from memory.

  The token is stored, in plaintext, in claude_desktop_config.json. That
  is how Cowork's stdio MCP config works today. Keep the config file's
  NTFS ACLs locked to your user, and rotate the PAT if exposed.

.PARAMETER Version
  Pinned release tag (e.g. "v1.0.2"). If omitted, "latest" is resolved
  via the GitHub releases API.

.PARAMETER InstallDir
  Where to put the binary. Default: %LOCALAPPDATA%\Programs\github-mcp-server

.PARAMETER SkipConfigUpdate
  Download and extract only — don't touch claude_desktop_config.json.

.EXAMPLE
  PS> .\scripts\install-github-mcp.ps1

.EXAMPLE
  PS> .\scripts\install-github-mcp.ps1 -Version v1.0.2 -SkipConfigUpdate
#>

[CmdletBinding()]
param(
    [string]$Version,
    [string]$InstallDir,
    [switch]$SkipConfigUpdate
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $InstallDir) {
    $InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\github-mcp-server'
}

# ---------------------------------------------------------------------------
# 1. Resolve version.
# ---------------------------------------------------------------------------
if (-not $Version) {
    Write-Host '[install-github-mcp] Resolving latest release...' -ForegroundColor DarkGray
    try {
        $rel = Invoke-RestMethod -UseBasicParsing `
            -Uri 'https://api.github.com/repos/github/github-mcp-server/releases/latest' `
            -Headers @{ 'User-Agent' = 'claude-cowork-quickstart' }
        $Version = $rel.tag_name
    } catch {
        throw "Could not resolve latest release: $($_.Exception.Message). Pass -Version explicitly."
    }
}
Write-Host "[install-github-mcp] Version: $Version" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 2. Download + extract.
# ---------------------------------------------------------------------------
$arch = 'x86_64'
if ([Environment]::Is64BitOperatingSystem -eq $false) {
    throw 'github-mcp-server only ships 64-bit Windows binaries.'
}
$zipName = "github-mcp-server_Windows_${arch}.zip"
$url = "https://github.com/github/github-mcp-server/releases/download/$Version/$zipName"

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
$zipPath = Join-Path $InstallDir $zipName

Write-Host "[install-github-mcp] Downloading $url" -ForegroundColor DarkGray
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zipPath

Write-Host "[install-github-mcp] Extracting to $InstallDir" -ForegroundColor DarkGray
Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
Remove-Item $zipPath -Force

$exe = Join-Path $InstallDir 'github-mcp-server.exe'
if (-not (Test-Path $exe)) {
    throw "Extraction did not produce github-mcp-server.exe at $exe"
}

# Smoke test: the binary should respond to --help.
try {
    $null = & $exe --help 2>&1 | Out-String
    Write-Host "[install-github-mcp] Binary OK: $exe" -ForegroundColor Green
} catch {
    throw "github-mcp-server.exe failed to run: $($_.Exception.Message)"
}

if ($SkipConfigUpdate) {
    Write-Host '[install-github-mcp] -SkipConfigUpdate set; leaving claude_desktop_config.json untouched.' -ForegroundColor Yellow
    return
}

# ---------------------------------------------------------------------------
# 3. Resolve Cowork config path.
# ---------------------------------------------------------------------------
$finder = Join-Path $scriptDir 'find-cowork-config.ps1'
if (-not (Test-Path $finder)) { throw "Missing dependency: $finder" }
$targetDir = & $finder
$targetFile = Join-Path $targetDir 'claude_desktop_config.json'
if (-not (Test-Path $targetFile)) {
    throw @"
$targetFile does not exist. Deploy the base config first:
  .\scripts\deploy-config.ps1
"@
}

# ---------------------------------------------------------------------------
# 4. Prompt for GitHub PAT (SecureString).
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Paste your GitHub Personal Access Token. Input is masked.' -ForegroundColor Yellow
Write-Host 'Fine-grained PAT or classic PAT both work. Scopes depend on what' -ForegroundColor DarkGray
Write-Host 'you want the server to do (repo read/write, issues, PRs, etc.).' -ForegroundColor DarkGray
$secure = Read-Host -AsSecureString 'GitHub PAT'
if ($secure.Length -eq 0) { throw 'No token entered — aborting.' }

$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
    $pat = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)

    # ------------------------------------------------------------------
    # 5. Load config, inject mcpServers.github block.
    # ------------------------------------------------------------------
    $cfg = Get-Content -Raw -LiteralPath $targetFile | ConvertFrom-Json

    # PSCustomObject — use Add-Member to set/replace top-level mcpServers.
    $exePath = $exe -replace '\\', '\\\\'   # not actually needed for ConvertTo-Json, kept for clarity

    $githubServer = [ordered]@{
        command = $exe
        args    = @('stdio')
        env     = [ordered]@{
            GITHUB_PERSONAL_ACCESS_TOKEN = $pat
        }
    }

    if ($cfg.PSObject.Properties.Name -contains 'mcpServers') {
        # Replace or add the github entry without wiping siblings.
        if ($cfg.mcpServers.PSObject.Properties.Name -contains 'github') {
            $cfg.mcpServers.PSObject.Properties.Remove('github')
        }
        $cfg.mcpServers | Add-Member -NotePropertyName 'github' -NotePropertyValue $githubServer -Force
    } else {
        $cfg | Add-Member -NotePropertyName 'mcpServers' -NotePropertyValue ([ordered]@{ github = $githubServer }) -Force
    }

    $json = $cfg | ConvertTo-Json -Depth 12
    if ($json -notmatch 'github-mcp-server\.exe') {
        throw 'Serialization did not include github-mcp-server.exe path — refusing to write.'
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($targetFile, $json, $utf8NoBom)
    Write-Host "[install-github-mcp] Updated $targetFile" -ForegroundColor Green
}
finally {
    if ($bstr -ne [IntPtr]::Zero) {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    if (Get-Variable -Name pat -Scope Local -ErrorAction SilentlyContinue) {
        Remove-Variable pat -Scope Local
    }
    if (Get-Variable -Name json -Scope Local -ErrorAction SilentlyContinue) {
        Remove-Variable json -Scope Local
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

Write-Host ''
Write-Host 'Done. Next steps:' -ForegroundColor Cyan
Write-Host '  1. Fully quit Claude Desktop (system tray - Quit).'
Write-Host '  2. Relaunch. Settings - Developer - Local MCP servers should list "github".'
Write-Host '  3. In a new chat, ask: "List my 5 most recently updated GitHub repos."'
