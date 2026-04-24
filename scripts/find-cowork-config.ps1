<#
.SYNOPSIS
  Locate the real claude_desktop_config.json used by Claude Cowork on Windows.

.DESCRIPTION
  Claude Cowork 3P ships two different Windows distributions:

    1. Microsoft Store build
       Config path (virtualized per user):
         %LOCALAPPDATA%\Packages\Claude_<suffix>\LocalCache\Roaming\Claude-3p\
       The Store runtime silently redirects writes to this package-scoped
       folder. Editing %APPDATA%\Claude-3p directly will not persist.

    2. Direct-download build (MSI / EXE installer from claude.com/download)
       Config path:
         %APPDATA%\Claude-3p\

  This script inspects a running Claude process via its --user-data-dir arg,
  falls back to a filesystem probe of both known locations, and prints the
  resolved path. If Claude is not running, it prints the first path that
  already exists on disk; if neither exists, it prints the expected
  direct-install path so the caller can create it.

  NOTE: The Cowork 3P folder is "Claude-3p". The regular Claude Desktop
  folder is "Claude". They are different products — do not confuse them.

.OUTPUTS
  The absolute path of the active config directory (stdout, single line).

.EXAMPLE
  PS> .\find-cowork-config.ps1
  C:\Users\jane\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude-3p

.EXAMPLE
  # Use the result to open the config in Notepad
  PS> notepad (Join-Path (.\find-cowork-config.ps1) 'claude_desktop_config.json')
#>

[CmdletBinding()]
param()

# NOTE: Do not declare a custom -Verbose switch here. [CmdletBinding()] already
# provides -Verbose as a built-in common parameter; redeclaring it triggers
# "A parameter with the name 'Verbose' was defined multiple times for the
# command." Consumers pass -Verbose normally and $VerbosePreference is honored.

$ErrorActionPreference = 'Stop'

function Write-Info($msg) {
    if ($VerbosePreference -ne 'SilentlyContinue') {
        Write-Host "[find-cowork-config] $msg" -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------------------------
# 1. Live process probe — most reliable. The Cowork 3P process is launched
#    with an explicit --user-data-dir argument that points at the active
#    config root. Reading it tells us exactly what the running app is using.
# ---------------------------------------------------------------------------
$live = $null
try {
    $procs = Get-CimInstance Win32_Process -Filter "Name='Claude.exe'" -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        if ($p.CommandLine -match '--user-data-dir=("?)([^"\s]+Claude-3p[^"\s]*)\1') {
            $live = $Matches[2]
            Write-Info "Resolved from running Claude.exe: $live"
            break
        }
    }
} catch {
    Write-Info "Process probe failed: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 2. Filesystem probe — fall back to the two canonical locations.
# ---------------------------------------------------------------------------
function Get-StoreConfigPath {
    $pkgRoot = Join-Path $env:LOCALAPPDATA 'Packages'
    if (-not (Test-Path $pkgRoot)) { return $null }
    $pkg = Get-ChildItem $pkgRoot -Directory -Filter 'Claude_*' -ErrorAction SilentlyContinue |
           Select-Object -First 1
    if (-not $pkg) { return $null }
    $candidate = Join-Path $pkg.FullName 'LocalCache\Roaming\Claude-3p'
    if (Test-Path $candidate) { return $candidate }
    return $null
}

function Get-DirectConfigPath {
    $candidate = Join-Path $env:APPDATA 'Claude-3p'
    if (Test-Path $candidate) { return $candidate }
    return $null
}

$store  = Get-StoreConfigPath
$direct = Get-DirectConfigPath

if ($live) {
    $resolved = $live
    $source = 'running process'
} elseif ($store -and $direct) {
    # Both exist — prefer the one with a real config file, else Store (the
    # Store build is the one most users end up with from claude.com/download
    # on Windows 11).
    $storeCfg  = Join-Path $store  'claude_desktop_config.json'
    $directCfg = Join-Path $direct 'claude_desktop_config.json'
    if ((Test-Path $storeCfg) -and -not (Test-Path $directCfg)) {
        $resolved = $store ;  $source = 'filesystem (Store build)'
    } elseif ((Test-Path $directCfg) -and -not (Test-Path $storeCfg)) {
        $resolved = $direct ; $source = 'filesystem (direct install)'
    } else {
        $resolved = $store ;  $source = 'filesystem (both present — Store preferred)'
    }
} elseif ($store) {
    $resolved = $store ;  $source = 'filesystem (Store build)'
} elseif ($direct) {
    $resolved = $direct ; $source = 'filesystem (direct install)'
} else {
    # Nothing on disk yet. Default to the direct-install path so the caller
    # can mkdir and drop a config in. Cowork will pick it up on next launch
    # only if the installed build is the direct-download variant; Store
    # users must launch Cowork once to materialize the package folder.
    $resolved = Join-Path $env:APPDATA 'Claude-3p'
    $source = 'default (not yet created)'
}

Write-Info "Source: $source"
Write-Info ("Config file: {0}" -f (Join-Path $resolved 'claude_desktop_config.json'))

# Emit the resolved directory path on a single stdout line so callers can
# capture it with `$cfgDir = .\find-cowork-config.ps1`.
Write-Output $resolved
