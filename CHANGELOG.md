# Changelog

All notable changes to this quickstart will be documented here. This project follows [Semantic Versioning](https://semver.org/).

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
