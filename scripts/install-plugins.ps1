# Bulk-install all 11 Anthropic knowledge-work plugins via the Claude Code CLI.
# Requires: Claude Code installed and on PATH. https://claude.com/product/claude-code

$ErrorActionPreference = 'Stop'

$Marketplace = 'anthropics/knowledge-work-plugins'
$Plugins = @(
    'cowork-plugin-management',
    'productivity',
    'enterprise-search',
    'sales',
    'customer-support',
    'product-management',
    'marketing',
    'legal',
    'finance',
    'data',
    'bio-research'
)

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Error "'claude' CLI not found on PATH. Install Claude Code first: https://claude.com/product/claude-code"
    exit 1
}

Write-Host "==> Adding marketplace: $Marketplace"
try {
    claude plugin marketplace add $Marketplace
} catch {
    Write-Host "  (marketplace may already be added; continuing)"
}

Write-Host ""
Write-Host "==> Installing $($Plugins.Count) plugins"

$installed = @()
$failed = @()
foreach ($plugin in $Plugins) {
    Write-Host ""
    Write-Host "--- $plugin ---"
    try {
        claude plugin install "$plugin@knowledge-work-plugins"
        $installed += $plugin
    } catch {
        Write-Warning "Install failed for $plugin : $_"
        $failed += $plugin
    }
}

Write-Host ""
Write-Host "==================================================="
Write-Host ("Installed ({0}): {1}" -f $installed.Count, ($installed -join ', '))
if ($failed.Count -gt 0) {
    Write-Host ("Failed ({0}): {1}" -f $failed.Count, ($failed -join ', '))
    Write-Host "Retry a failed plugin manually with:"
    Write-Host "  claude plugin install <name>@knowledge-work-plugins"
    exit 1
}
Write-Host "All plugins installed. Open Cowork and type / to see new slash commands."
