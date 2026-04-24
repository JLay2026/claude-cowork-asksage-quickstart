#requires -Version 5.1
<#
.SYNOPSIS
    Moves the 'github' MCP server from top-level mcpServers into
    enterpriseConfig.managedMcpServers and attaches a per-tool toolPolicy that
    auto-approves all read tools and prompts for all write tools.

.DESCRIPTION
    Why this exists:
    On Cowork's 3P developer build, top-level user-added mcpServers do not
    support per-tool approval overrides via the JSON config -- and the
    Customize-page tool-permission dropdowns are greyed out for LOCAL DEV
    servers on some builds. The documented mechanism that DOES work is
    enterpriseConfig.managedMcpServers with a toolPolicy map of
    <tool_name> -> "allow" | "ask" | "blocked".

    managedMcpServers ONLY supports remote HTTP/SSE servers (not local STDIO
    binaries) -- the schema requires a 'url' field and rejects entries with
    'command'/'args'. So this script switches github from the local
    github-mcp-server.exe over to GitHub's hosted MCP endpoint at
    https://api.githubcopilot.com/mcp/, authenticating with the same PAT.

    This script:
      1. Finds Cowork's active config (Microsoft Store OR direct-install path)
      2. Backs it up with a timestamp
      3. Removes mcpServers.github if present (prevents duplicate server)
      4. Writes a managedMcpServers entry for github with:
         - url = https://api.githubcopilot.com/mcp/ (transport: http)
         - headers.Authorization = Bearer <PAT>
         - A toolPolicy covering all 102 tools in github-mcp-server v1.0.2:
           * 50 read tools      -> "allow"
           * 52 write tools     -> "ask"
      5. Writes UTF-8 without BOM (required -- Cowork's parser rejects BOM)
      6. Prints a verification summary

    Tool classification source:
    Taken from github-mcp-server v1.0.2 source tree (__toolsnaps__/ metadata),
    using the official readOnlyHint flag on each tool definition. Not guesswork.

.NOTES
    Run from repo root:   .\scripts\apply-github-toolpolicy.ps1
    Restart Cowork (fully quit from tray, then relaunch) after this completes.
#>

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# --- Tool inventory from github-mcp-server v1.0.2 __toolsnaps__/ -------------
# 50 read-only tools (readOnlyHint: true in the official tool metadata)
$readTools = @(
    'actions_get','actions_list',
    'get_code_scanning_alert','get_commit','get_dependabot_alert',
    'get_discussion','get_discussion_comments','get_file_contents','get_gist',
    'get_global_security_advisory','get_job_logs','get_label','get_latest_release',
    'get_me','get_notification_details','get_release_by_tag','get_repository_tree',
    'get_secret_scanning_alert','get_tag','get_team_members','get_teams',
    'issue_read',
    'list_branches','list_code_scanning_alerts','list_commits',
    'list_dependabot_alerts','list_discussion_categories','list_discussions',
    'list_gists','list_global_security_advisories','list_issue_types',
    'list_issues','list_label','list_notifications',
    'list_org_repository_security_advisories','list_pull_requests',
    'list_releases','list_repository_security_advisories',
    'list_secret_scanning_alerts','list_starred_repositories','list_tags',
    'projects_get','projects_list','pull_request_read',
    'search_code','search_issues','search_orgs','search_pull_requests',
    'search_repositories','search_users'
)

# 52 mutating tools (no readOnlyHint in the official metadata)
$writeTools = @(
    'actions_run_trigger',
    'add_comment_to_pending_review','add_issue_comment',
    'add_pull_request_review_comment','add_reply_to_pull_request_comment',
    'add_sub_issue','assign_copilot_to_issue',
    'create_branch','create_gist','create_issue','create_or_update_file',
    'create_pull_request','create_pull_request_review','create_repository',
    'delete_file','delete_pending_pull_request_review',
    'dismiss_notification','fork_repository',
    'issue_write','label_write',
    'manage_notification_subscription',
    'manage_repository_notification_subscription',
    'mark_all_notifications_read','merge_pull_request',
    'projects_write','pull_request_review_write','push_files',
    'remove_sub_issue','reprioritize_sub_issue',
    'request_copilot_review','request_pull_request_reviewers',
    'resolve_review_thread','set_issue_fields',
    'star_repository','sub_issue_write',
    'submit_pending_pull_request_review','unresolve_review_thread',
    'unstar_repository','update_gist',
    'update_issue_assignees','update_issue_body','update_issue_labels',
    'update_issue_milestone','update_issue_state','update_issue_title',
    'update_issue_type','update_pull_request','update_pull_request_body',
    'update_pull_request_branch','update_pull_request_draft_state',
    'update_pull_request_state','update_pull_request_title'
)

function Write-Info($msg) { Write-Host "[apply-toolpolicy] $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "[apply-toolpolicy] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[apply-toolpolicy] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "[apply-toolpolicy] $msg" -ForegroundColor Red }

# --- 1. Locate the active config -------------------------------------------
$storePattern = Join-Path $env:LOCALAPPDATA 'Packages\Claude_*\LocalCache\Roaming\Claude-3p\claude_desktop_config.json'
$storeCfg = Get-ChildItem -Path $storePattern -ErrorAction SilentlyContinue | Select-Object -First 1
$directCfg = Join-Path $env:APPDATA 'Claude-3p\claude_desktop_config.json'

$cfgPath = $null
if ($storeCfg -and (Test-Path $storeCfg.FullName)) {
    $cfgPath = $storeCfg.FullName
    Write-Info "Using Microsoft Store config: $cfgPath"
} elseif (Test-Path $directCfg) {
    $cfgPath = $directCfg
    Write-Info "Using direct-install config: $cfgPath"
} else {
    Write-Err "No claude_desktop_config.json found. Expected one of:"
    Write-Err "  $storePattern"
    Write-Err "  $directCfg"
    exit 1
}

# --- 2. Read and parse ------------------------------------------------------
$raw = Get-Content $cfgPath -Raw
$cfg = $raw | ConvertFrom-Json
Write-Info "Current top-level keys: $($cfg.PSObject.Properties.Name -join ', ')"

# --- 3. Extract existing PAT (or prompt) ------------------------------------
$pat = $null
if ($cfg.mcpServers -and $cfg.mcpServers.github -and $cfg.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN) {
    $pat = $cfg.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN
    Write-Info "Reusing PAT from existing mcpServers.github ($($pat.Length) chars)"
} elseif ($cfg.enterpriseConfig.managedMcpServers) {
    # Might already be in managedMcpServers from a prior run
    $existingMgd = $cfg.enterpriseConfig.managedMcpServers
    if ($existingMgd -is [string]) {
        try {
            $mgdArr = $existingMgd | ConvertFrom-Json
            $ghExisting = $mgdArr | Where-Object { $_.name -eq 'github' } | Select-Object -First 1
            if ($ghExisting) {
                # New shape: headers.Authorization = 'Bearer <PAT>'
                if ($ghExisting.headers -and $ghExisting.headers.Authorization) {
                    $authVal = [string]$ghExisting.headers.Authorization
                    if ($authVal -match '^Bearer\s+(.+)$') {
                        $pat = $Matches[1]
                        Write-Info "Reusing PAT from existing managedMcpServers.github headers ($($pat.Length) chars)"
                    }
                }
                # Old shape (pre-pivot to remote): env.GITHUB_PERSONAL_ACCESS_TOKEN
                if (-not $pat -and $ghExisting.env -and $ghExisting.env.GITHUB_PERSONAL_ACCESS_TOKEN) {
                    $pat = $ghExisting.env.GITHUB_PERSONAL_ACCESS_TOKEN
                    Write-Info "Reusing PAT from existing managedMcpServers.github env ($($pat.Length) chars)"
                }
            }
        } catch {}
    }
}
if (-not $pat) {
    Write-Warn "No existing PAT found. You'll be prompted to paste one."
    $secure = Read-Host "GitHub Personal Access Token (input hidden)" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $pat = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    if (-not $pat) { Write-Err "Empty PAT. Aborting."; exit 1 }
}

# --- 4. Backup --------------------------------------------------------------
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$bak = "$cfgPath.bak-$ts"
Copy-Item -LiteralPath $cfgPath -Destination $bak -Force
Write-Ok "Backup: $bak"

# --- 5. Build toolPolicy ----------------------------------------------------
$toolPolicy = [ordered]@{}
foreach ($t in ($readTools  | Sort-Object -Unique)) { $toolPolicy[$t] = 'allow' }
foreach ($t in ($writeTools | Sort-Object -Unique)) { $toolPolicy[$t] = 'ask' }
$readCount  = $readTools.Count
$writeCount = $writeTools.Count
$policyLen  = $toolPolicy.Count
$policySummary = "$readCount allow, $writeCount ask"
Write-Info "toolPolicy entries: $policyLen [$policySummary]"

# --- 6. Build managed server entry -----------------------------------------
# IMPORTANT: managedMcpServers ONLY supports REMOTE servers (HTTP/SSE).
# Local STDIO binaries (command/args/env) are not allowed by the schema and are
# silently rejected by Cowork. We use GitHub's hosted MCP at
# https://api.githubcopilot.com/mcp/ with PAT in the Authorization header.
# Per docs: required fields are 'name' and 'url' (https only). Optional:
# 'transport' (http|sse, default http), 'headers', 'toolPolicy'.
# NOTE: Cowork's org-provisioned 'engineering' plugin claims the bare name
# 'github' and shadows any other registration with a no-op to prevent SDK
# double-load. Use a distinct name so our entry actually loads.
$githubEntry = [ordered]@{
    name       = 'github-direct'
    url        = 'https://api.githubcopilot.com/mcp/'
    transport  = 'http'
    headers    = [ordered]@{
        Authorization = "Bearer $pat"
    }
    toolPolicy = $toolPolicy
}

# --- 7. Merge into existing config -----------------------------------------
# Ensure enterpriseConfig exists
if (-not $cfg.enterpriseConfig) {
    Write-Err "enterpriseConfig block missing from config. This script expects a 3P profile."
    exit 1
}

# managedMcpServers is documented as a JSON-stringified array.
# Parse any existing value, replace/add the github entry, re-stringify.
$existingRaw = $cfg.enterpriseConfig.managedMcpServers
$mgdArray = @()
if ($existingRaw) {
    if ($existingRaw -is [string]) {
        try { $mgdArray = @($existingRaw | ConvertFrom-Json) } catch { $mgdArray = @() }
    } elseif ($existingRaw -is [array]) {
        $mgdArray = @($existingRaw)
    }
}
# Remove any prior github / github-direct entry (covers pre-rename builds)
$mgdArray = @($mgdArray | Where-Object { $_.name -ne 'github' -and $_.name -ne 'github-direct' })
# Append our new one (convert hashtable to PSCustomObject for consistent shape)
$mgdArray += [PSCustomObject]$githubEntry

# Stringify back (Cowork's schema: managedMcpServers is a JSON string)
$mgdJson = $mgdArray | ConvertTo-Json -Depth 10 -Compress

# Assign back. PowerShell 5.1 can't always use dotted assignment on parsed
# JSON, so rebuild the enterpriseConfig object via Add-Member/force.
if ($cfg.enterpriseConfig.PSObject.Properties['managedMcpServers']) {
    $cfg.enterpriseConfig.managedMcpServers = $mgdJson
} else {
    $cfg.enterpriseConfig | Add-Member -MemberType NoteProperty -Name managedMcpServers -Value $mgdJson
}

# Remove mcpServers.github so we don't have a duplicate Local Dev registration
if ($cfg.mcpServers -and $cfg.mcpServers.PSObject.Properties['github']) {
    $cfg.mcpServers.PSObject.Properties.Remove('github')
    Write-Info "Removed mcpServers.github (now lives under managedMcpServers)"
    # If mcpServers is now empty, drop the key entirely
    if (-not $cfg.mcpServers.PSObject.Properties.Name) {
        $cfg.PSObject.Properties.Remove('mcpServers')
    }
}

# --- 8. Serialize and write (UTF-8 NO BOM -- Cowork requires this) ----------
$finalJson = $cfg | ConvertTo-Json -Depth 20

if ($DryRun) {
    Write-Warn "DRY RUN -- config would be written but is not. Preview below:"
    Write-Host ""
    Write-Host $finalJson
    exit 0
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($cfgPath, $finalJson, $utf8NoBom)

# Verify it parses
try {
    $verify = Get-Content $cfgPath -Raw | ConvertFrom-Json
    $verifiedMgd = $verify.enterpriseConfig.managedMcpServers | ConvertFrom-Json
    $verifiedGh  = $verifiedMgd | Where-Object { $_.name -eq 'github' } | Select-Object -First 1
    if (-not $verifiedGh) { throw 'github entry missing after write' }
    $policyCount = ($verifiedGh.toolPolicy.PSObject.Properties.Name).Count
} catch {
    Write-Err "Write completed but verification failed: $_"
    Write-Err "Restore from backup: Copy-Item '$bak' '$cfgPath' -Force"
    exit 1
}

# Clear PAT from memory
Remove-Variable pat -ErrorAction SilentlyContinue
[GC]::Collect()

# --- 9. Report --------------------------------------------------------------
Write-Ok ""
Write-Ok "=========================================="
Write-Ok "Applied github toolPolicy successfully."
Write-Ok "  Config:        $cfgPath"
Write-Ok "  Backup:        $bak"
$finalSummary = "$readCount allow / $writeCount ask"
Write-Ok "  Tool policies: $policyCount [$finalSummary]"
Write-Ok "=========================================="
Write-Ok ""
Write-Ok "NEXT STEPS:"
Write-Ok "  1. Fully quit Claude Cowork (system tray -> Quit)"
Write-Ok "  2. Relaunch Cowork"
Write-Ok "  3. New chat: 'List my 5 most recently updated repos'"
Write-Ok "     -> should complete with NO approval prompt"
Write-Ok "  4. New chat: 'Open an issue on <somerepo> titled test'"
Write-Ok "     -> should prompt for approval"
Write-Ok ""
Write-Ok "If reads still prompt, check: Settings -> Customize -> github"
Write-Ok "The per-tool indicators should show green/allow icons, not hands."
