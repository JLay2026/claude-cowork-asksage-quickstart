# Changelog

All notable changes to this quickstart will be documented here. This project follows [Semantic Versioning](https://semver.org/).

## [1.3] — 2026-04-23

Corrects the Windows config-file path for Cowork 3P (Microsoft Store virtualization), adds a Local MCP server setup using GitHub's official Go binary, and introduces SecureString-based deployment scripts.

### Added
- **Part 4** of `README.md` — "Connect a local GitHub MCP server". Uses the official [`github/github-mcp-server`](https://github.com/github/github-mcp-server) Go binary (not the deprecated npm package). Includes the Managed vs Local MCP appendix so users don't lose another hour to the `enterpriseConfig.managedMcpServers` red herring.
- `scripts/find-cowork-config.ps1` — resolves the real Cowork 3P config directory on Windows by inspecting the running `Claude.exe` process (`--user-data-dir` arg), with a filesystem-probe fallback covering both Microsoft Store and direct-install layouts. Emits a single-line path so it pipes cleanly.
- `scripts/deploy-config.ps1` — SecureString-based config deployer. Prompts for the Ask Sage key with masked input, renders the template, writes UTF-8 without BOM to the correct path, and runs a 10-check validation pass. Scrubs plaintext from memory via `ZeroFreeBSTR` + `Remove-Variable` + `[GC]::Collect()`.
- `scripts/install-github-mcp.ps1` — downloads the GitHub MCP Go binary to `%LOCALAPPDATA%\Programs\github-mcp-server\`, prompts for a GitHub PAT as SecureString, and injects a top-level `mcpServers.github` entry into the Cowork config. Supports `-Version` to pin a release tag and `-SkipConfigUpdate` for download-only.
- `README.md` — new troubleshooting table for GitHub MCP covering the top-level-vs-managed config mix-up, 60-second `initialize` timeout on the npm package, and PAT auth failures.

### Changed
- **Part 1 / Step 3** of `README.md` rewritten around the two-location config-file reality on Windows: Microsoft Store builds live under `%LOCALAPPDATA%\Packages\Claude_<suffix>\LocalCache\Roaming\Claude-3p\`, direct-download builds live under `%APPDATA%\Claude-3p\`. Both folders are `Claude-3p`, not `Claude` — that's regular Claude Desktop, a different product.
- `claude_desktop_config.json` template: removed `deploymentOrganizationUuid`. The field isn't required for individual 3P gateway setups, and leaving placeholder or wrong values in it caused silent provisioning failures. Step 3 of Part 1 no longer asks for a UUID.
- `plugins.md` — new section clarifying that `enterpriseConfig.managedMcpServers` is admin-only (delivered via signed MDM policy) and the end-user key is top-level `mcpServers`. Includes the visual symptom users actually see (🔒 icon in the Managed panel).

### Notes
- Both new SecureString scripts produce UTF-8-no-BOM output via `[System.IO.File]::WriteAllText` with `UTF8Encoding($false)`. Do not switch them to `Set-Content -Encoding UTF8` — that emits a BOM, which Cowork's JSON parser rejects.
- The deprecated `@modelcontextprotocol/server-github` npm package is still documented upstream in some places but should not be used with Cowork; cold `npx -y` starts time out against Cowork's 60-second MCP initialize handshake. The Go binary starts in under a second.
- No changes to inference models, Ask Sage URL, auth scheme, or plugin list.

## [1.2] — 2026-04-23

Added an offline sideload path for tenants where outbound GitHub access is blocked by Cowork's egress policy.

### Added
- **Part 3** of `README.md` — "Offline sideload (when egress is blocked)". Full procedure for downloading the `anthropics/knowledge-work-plugins` repo on an unrestricted machine, transferring to the target workstation, extracting to `C:\Program Files\Claude\org-plugins` (or `/opt/claude/org-plugins`), and registering it as a local marketplace.
- `scripts/sideload-plugins.ps1` — elevated PowerShell script that automates extraction, flattening, and local-marketplace registration with the Claude Code CLI.
- New section in `plugins.md` — "Network access to github.com is blocked" — with three remediation options (allowlist, sideload, CLI).
- Two new troubleshooting rows in `README.md` covering the egress error and sideload edge cases.

### Notes
- The upstream marketplace now contains ~41 plugins; roughly 20 are bundled in the repo (`source: "./folder"`) and install fully offline from a sideload. The remaining ~21 are partner-built plugins with `source: "url"` pointing at other GitHub repos — those still require egress to github.com at install time. The 11 recommended plugins are all in the bundled group.
- No `claude_desktop_config.json` changes.
- Egress policy is a tenant-level Cowork setting (Settings → Capabilities → Network egress), not something this quickstart can alter from the client side.

## [1.1] — 2026-04-23

Added the Anthropic knowledge-work plugin suite to the setup flow.

### Added
- **Part 2** of the quickstart in `README.md` — installing all 11 Anthropic knowledge-work plugins ([anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins)) via either the in-app one-click flow at [claude.com/plugins](https://claude.com/plugins/) or the Claude Code CLI.
- `plugins.md` — full reference for each plugin (purpose, target user, connectors), activation mechanics, connector auth notes, and customization guidance.
- `scripts/install-plugins.sh` — bash bulk-installer that adds the `anthropics/knowledge-work-plugins` marketplace and installs all 11 plugins via the `claude` CLI.
- `scripts/install-plugins.ps1` — PowerShell equivalent for Windows users.
- Plugin-specific troubleshooting table in `README.md`.

### Notes
- No changes to `claude_desktop_config.json` — the config schema has no documented keys for pre-wiring plugin marketplaces in Cowork. Plugin install is user-driven (web one-click or CLI).
- All 11 plugins are Anthropic-authored and open source.

## [1.0] — 2026-04-23

Initial public release.

### Added
- Beginner-friendly quickstart walkthrough in `README.md` covering install, Developer Mode, UUID generation, config placement, restart, and first-message verification.
- `claude_desktop_config.json` template with:
  - `deploymentMode: "3p"` for direct Cowork boot
  - `enterpriseConfig.inferenceProvider: "gateway"` pointed at `https://api.asksage.ai/server/anthropic`
  - Bearer auth scheme
  - Six Claude model IDs in `inferenceModels` (Opus 4.7/4.6/4.5, Sonnet 4.6/4.5, Haiku 4.5)
  - Telemetry and non-essential services disabled by default
  - Cowork scheduled tasks and web search enabled in `preferences`
- Redacted placeholders (`PASTE_YOUR_ASKSAGE_KEY_HERE`, `PASTE_YOUR_UUID_HERE`) so the template can be committed safely.
- Troubleshooting table for the five most common setup issues.
- `.gitignore` to keep local secrets (`.env`, `.key`, `*.local`) out of commits.
