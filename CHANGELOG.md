# Changelog

All notable changes to this quickstart will be documented here. This project follows [Semantic Versioning](https://semver.org/).

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
