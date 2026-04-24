# Claude Cowork + Ask Sage Quickstart

A beginner-friendly walkthrough to point Claude Desktop at Ask Sage for inference, layer on the Anthropic knowledge-work plugin suite, and connect a local GitHub MCP server. About 20 minutes end-to-end.

## What you'll end up with

- Claude Desktop running in Cowork 3P mode, with all inference flowing through your organization's Ask Sage tenant.
- The six Claude models (Opus 4.7/4.6/4.5, Sonnet 4.6/4.5, Haiku 4.5) available in the model picker.
- All 11 Anthropic knowledge-work plugins installed — productivity, sales, customer-support, product-management, marketing, legal, finance, data, enterprise-search, bio-research, and cowork-plugin-management.
- A **local GitHub MCP server** attached to Cowork so Claude can read/write issues, PRs, and repo contents on your behalf.
- If your tenant blocks outbound network egress (most hardened enterprise Cowork tenants do), you can sideload the plugin suite from a local folder instead of the hosted marketplace. See [Part 3](#part-3--offline-sideload-when-egress-is-blocked).

## Before you start

- **Claude Desktop (Cowork)** installed from [claude.com/download](https://claude.com/download)
- **Your Ask Sage API key** (a long string of letters and numbers)
- **A GitHub Personal Access Token** if you plan to do Part 4 (fine-grained or classic PAT)

---

## Part 1 — Ask Sage inference setup

### Step 1 — Install and open Claude Desktop

1. Download and install Claude Desktop.
2. Launch it. If a sign-in screen appears, **don't sign in yet** — just leave it open.

### Step 2 — Turn on Developer Mode

1. In the top menu, click **Help → Troubleshooting → Enable Developer Mode**.
2. The app acknowledges the change. You may need to restart it.

### Step 3 — Find your config file

> Cowork 3P on Windows ships as two different distributions. They store their config in different places. This trips up almost every first-time user. Read this step carefully.

| Install | Config path |
|---|---|
| Microsoft Store (most Windows 11 users) | `%LOCALAPPDATA%\Packages\Claude_<suffix>\LocalCache\Roaming\Claude-3p\claude_desktop_config.json` |
| Direct download (MSI/EXE from claude.com) | `%APPDATA%\Claude-3p\claude_desktop_config.json` |
| macOS | `~/Library/Application Support/Claude-3p/claude_desktop_config.json` |
| Linux | `~/.config/Claude-3p/claude_desktop_config.json` |

**The folder is `Claude-3p`, not `Claude`.** Regular Claude Desktop (the one that lives at `%APPDATA%\Claude`) is a different product — editing that folder will not affect Cowork.

**Easiest way to find yours on Windows:** run the bundled helper from this repo:

```powershell
.\scripts\find-cowork-config.ps1
```

It inspects the running Claude process (reads its `--user-data-dir` argument) and falls back to a filesystem probe of both locations. It prints the resolved directory — one line, so you can pipe it.

**The UI-driven way:** in Claude Desktop open **Settings → Developer → Local MCP servers → Edit Config**. Cowork opens the right file in your default editor regardless of which install flavor you have.

### Step 4 — Replace the config contents

Option A — **helper script (Windows, recommended).** The script prompts for your Ask Sage key as a SecureString (input is masked and plaintext never touches a shell variable or log file), renders the template, and writes a UTF-8-no-BOM config to the correct Cowork-3p path. It also runs a 10-check validation pass.

```powershell
.\scripts\deploy-config.ps1
```

Option B — **manual.** Open the config file from Step 3, replace its entire contents with the text of [`claude_desktop_config.json`](./claude_desktop_config.json) from this repo, then replace `PASTE_YOUR_ASKSAGE_KEY_HERE` with your Ask Sage API key (keep the quotes). Save as UTF-8 without BOM.

> v1.3 change: the `deploymentOrganizationUuid` field was removed. It's not required for individual 3P gateway setups, and leaving it blank or wrong caused silent provisioning failures for some users.

### Step 5 — Restart Claude Desktop

Fully quit Claude Desktop and reopen it. It must be a **complete quit**, not just closing the window:

- **Windows:** right-click the Claude icon in the system tray → Quit.
- **Mac:** Cmd+Q, or right-click in the Dock → Quit.

When it relaunches, it should go straight into Cowork mode (no sign-in screen).

### Step 6 — Test it

1. Start a new chat.
2. Open the model picker at the top. You should see the six Claude models from the config.
3. Pick one (Sonnet 4.5 is a good default) and send a test message like "hello".
4. If you get a response, the inference side is working.

---

## Part 2 — Install the knowledge-work plugin suite

Anthropic maintains an open-source marketplace of 11 role-specific plugins at [github.com/anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins). Each plugin bundles skills, slash commands, sub-agents, and MCP connectors for a specific job function.

Pick the path that matches your comfort level. Both paths install the same plugins.

### Path A — In-app one-click (Cowork, easiest)

1. With Claude Desktop running in Cowork mode, open a browser and go to **[claude.com/plugins](https://claude.com/plugins/)**.
2. Filter by the **Cowork** tag.
3. Click **Install** on each plugin you want. Claude Desktop will prompt you to accept — click through.
4. Repeat for each of the 11 plugins listed in [`plugins.md`](./plugins.md).

Each install takes a few seconds. When you're done, plugins activate automatically — skills fire when relevant, and slash commands become available (e.g., `/sales:call-prep`, `/data:write-query`).

### Path B — Claude Code CLI (fastest for all 11 at once)

> **Blocked by "Network access to github.com is blocked by egress settings"?** Skip this path — use [Part 3](#part-3--offline-sideload-when-egress-is-blocked) instead.

If you also have Claude Code installed, you can bulk-install with a single script.

**Windows (PowerShell):**
```powershell
.\scripts\install-plugins.ps1
```

**Mac/Linux (bash):**
```bash
./scripts/install-plugins.sh
```

Both scripts:
1. Add the `anthropics/knowledge-work-plugins` marketplace.
2. Install all 11 plugins from it.
3. Print a summary of what got installed.

Plugins installed via the CLI are visible and usable from within Cowork as well — they share the same local plugin store.

### Verify plugins are active

1. In any Cowork chat, type `/` to open the slash-command menu.
2. You should see commands namespaced per plugin — for example `/sales:...`, `/finance:...`, `/data:...`.
3. Try `/productivity:...` — if the productivity commands appear, plugins are wired up correctly.

For the full plugin list and what each one does, see [`plugins.md`](./plugins.md).

---

## Part 3 — Offline sideload (when egress is blocked)

Use this path when Path A or Path B fails with:

> **Network access to "github.com" is blocked by egress settings.**

Hardened Cowork tenants default-deny all outbound destinations except an allowlist — the hosted marketplace flow needs to `git clone github.com/anthropics/knowledge-work-plugins`, so it fails at the Sync step. The fix is to download the repo on a machine that *can* reach GitHub, drop the folder onto the target workstation, and register it with Cowork as a **local marketplace**. Cowork reads local folders through the normal filesystem — egress policy doesn't apply.

### What this covers (and what it doesn't)

The upstream marketplace now lists roughly 40 plugins. They fall into two groups:

- **Bundled in the repo** (about 20, including all 11 on our recommended list) — `source: "./<folder>"`. These install fully offline from a local sideload. ✅
- **Partner-built, hosted elsewhere** (the rest) — `source: "url"` pointing at other GitHub repos like `planetscale/claude-plugin`, `intercom/claude-plugin-external`, etc. These still require outbound GitHub access at install time. If your tenant's egress policy blocks github.com, these plugins cannot be installed via sideload — you either allowlist github.com (see [troubleshooting section in plugins.md](./plugins.md#network-access-to-githubcom-is-blocked)) or skip them.

The recommended 11-plugin knowledge-work set is entirely in the bundled group, so this sideload gets you everything that matters for the quickstart.

### Step 1 — Download the repo archive (on an unrestricted machine)

On any machine with internet access to github.com (your laptop at home, a bastion host, etc.):

1. Open [github.com/anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins).
2. Click the green **Code** button → **Download ZIP**. You'll get `knowledge-work-plugins-main.zip` (a few MB).
3. Transfer the ZIP to the target workstation via your org's approved file-transfer method (OneDrive, USB per policy, SCCM package, etc.).

Alternatively, on any machine with `git` installed and egress to GitHub:

```powershell
git clone https://github.com/anthropics/knowledge-work-plugins.git
# then zip and transfer the resulting folder
```

### Step 2 — Extract into the org-plugins folder (Windows)

On the target workstation, open **PowerShell as Administrator** (required because `C:\Program Files` is protected):

```powershell
# Create the destination
$dest = "C:\Program Files\Claude\org-plugins"
New-Item -ItemType Directory -Path $dest -Force | Out-Null

# Extract the ZIP you transferred (adjust source path as needed)
$zip = "$env:USERPROFILE\Downloads\knowledge-work-plugins-main.zip"
Expand-Archive -Path $zip -DestinationPath $dest -Force

# The ZIP extracts to a nested folder — flatten it so .claude-plugin sits at the root of org-plugins
Move-Item -Path "$dest\knowledge-work-plugins-main\*" -Destination $dest -Force
Remove-Item -Path "$dest\knowledge-work-plugins-main" -Recurse -Force

# Sanity check — you should see a .claude-plugin folder and per-plugin folders (sales, finance, data, etc.)
Get-ChildItem $dest | Select-Object Name
```

Your final layout should look like:

```
C:\Program Files\Claude\org-plugins\
├── .claude-plugin\
│   └── marketplace.json        ← Cowork reads this
├── bio-research\
├── cowork-plugin-management\
├── customer-support\
├── data\
├── enterprise-search\
├── finance\
├── legal\
├── marketing\
├── product-management\
├── productivity\
├── sales\
├── partner-built\             ← url-sourced plugins live here but still need egress
├── README.md
└── LICENSE
```

**macOS/Linux equivalent:**

```bash
sudo mkdir -p /opt/claude/org-plugins
sudo unzip ~/Downloads/knowledge-work-plugins-main.zip -d /opt/claude/org-plugins
sudo mv /opt/claude/org-plugins/knowledge-work-plugins-main/* /opt/claude/org-plugins/
sudo rmdir /opt/claude/org-plugins/knowledge-work-plugins-main
```

### Step 3 — Fully quit and relaunch Claude Desktop

As before, quit from the system tray (Windows) or Dock (macOS) — closing the window isn't enough. Cowork reads plugin configuration on startup.

### Step 4 — Register the local marketplace

1. In Cowork, open **Settings** (or the app menu) → **Customizations** → **Plugins**.
2. Click **Browse plugins** (or **Add marketplace**).
3. In the URL field, paste the **local filesystem path**, not a GitHub slug:
   - Windows: `C:\Program Files\Claude\org-plugins`
   - macOS/Linux: `/opt/claude/org-plugins`
4. Click **Sync**.

Cowork reads `.claude-plugin\marketplace.json` directly from disk. The red egress banner won't appear for this path — no network call is made.

If the dialog rejects the absolute path, try adding the marketplace via Claude Code CLI instead (it shares the same plugin store with Cowork):

```powershell
claude plugin marketplace add "C:\Program Files\Claude\org-plugins"
```

### Step 5 — Install the plugins

1. Still in **Customizations → Plugins**, the `knowledge-work-plugins` marketplace now appears in your list.
2. Click into it — you'll see every plugin in `marketplace.json`.
3. Click **Install** on each plugin you want (the recommended 11 are listed in [`plugins.md`](./plugins.md)).
4. Bundled plugins (`./folder` sources) install instantly — no network involved.
5. Partner-built plugins (`url` sources) will try to clone their upstream repo; those will fail with the same egress error unless github.com is allowlisted. Skip them if you can't allowlist.

**Bulk-install via CLI (optional):**

```powershell
$plugins = @(
  "cowork-plugin-management", "productivity", "enterprise-search",
  "sales", "customer-support", "product-management", "marketing",
  "legal", "finance", "data", "bio-research"
)
foreach ($p in $plugins) {
  claude plugin install "$p@knowledge-work-plugins"
}
```

### Step 6 — Verify

Start a new Cowork chat. Type `/` — you should see commands namespaced per plugin (`/sales:...`, `/finance:...`, `/data:...`). If they appear, the sideload worked.

### Keeping sideloaded plugins updated

When Anthropic updates the upstream repo, repeat Step 1 on the unrestricted machine, transfer the new ZIP, and re-run Step 2 (`Expand-Archive -Force` overwrites). Then in Cowork **Customizations → Plugins**, click the **⋯** menu on the marketplace and choose **Check for updates**.

For a scripted one-shot sideload, see [`scripts/sideload-plugins.ps1`](./scripts/sideload-plugins.ps1).

---

## Part 4 — Connect a local GitHub MCP server

Once inference is live and plugins are installed, you can give Claude Cowork direct read/write access to GitHub (issues, PRs, repo contents, code search) via a **Local MCP server**.

### Why the GitHub-official Go binary (not the npm one)

- `@modelcontextprotocol/server-github` (npm) is deprecated. The first time Cowork launches it, `npx -y` downloads ~150 MB of Node modules, which blows past Cowork's 60-second MCP `initialize` handshake and times out.
- GitHub now publishes an official, self-contained Go binary — [`github/github-mcp-server`](https://github.com/github/github-mcp-server). No Node, no dependencies, ~7 MB zip, sub-second startup. This is what you want.

### Step 1 — Create a GitHub Personal Access Token

1. Go to [github.com/settings/tokens](https://github.com/settings/tokens) (classic) or [settings/personal-access-tokens](https://github.com/settings/personal-access-tokens) (fine-grained).
2. Grant the scopes that match what you want Claude to do. Common starters:
   - **Classic:** `repo`, `read:org`, `read:user`, `workflow` if you want Actions reads.
   - **Fine-grained:** pick the repos you want reachable, then grant Contents/Issues/Pull requests read or write.
3. Copy the token — you'll paste it in the next step. GitHub only shows it once.

### Step 2 — Install the binary and update your config

**Windows (recommended — helper script):**

```powershell
.\scripts\install-github-mcp.ps1
```

The script:
1. Downloads the latest `github-mcp-server` release for Windows x64 to `%LOCALAPPDATA%\Programs\github-mcp-server\`.
2. Extracts `github-mcp-server.exe` and smoke-tests `--help`.
3. Prompts for your PAT as a SecureString (input is masked).
4. Finds your active Cowork config via `find-cowork-config.ps1`.
5. Injects (or replaces) an `mcpServers.github` block under the **top-level** `mcpServers` key.
6. Writes the config as UTF-8 without BOM and scrubs the PAT from memory.

Pin a specific version with `-Version v1.0.2`. Skip the config rewrite (download only) with `-SkipConfigUpdate`.

**macOS/Linux (manual):**

```bash
# Pick the right asset for your arch: Darwin_arm64, Darwin_x86_64, Linux_x86_64, etc.
VER="v1.0.2"
curl -L -o /tmp/gh-mcp.tar.gz \
  "https://github.com/github/github-mcp-server/releases/download/${VER}/github-mcp-server_$(uname -s)_$(uname -m).tar.gz"
mkdir -p "$HOME/.local/share/github-mcp-server"
tar -xzf /tmp/gh-mcp.tar.gz -C "$HOME/.local/share/github-mcp-server"

# Edit the Cowork 3P config at the path for your OS (see Step 1 of Part 1),
# and add this block at the TOP LEVEL — NOT nested under enterpriseConfig:
```

```json
{
  "deploymentMode": "3p",
  "enterpriseConfig": { "...unchanged...": true },
  "mcpServers": {
    "github": {
      "command": "/Users/you/.local/share/github-mcp-server/github-mcp-server",
      "args": ["stdio"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_..."
      }
    }
  }
}
```

### Step 3 — Restart and verify

1. Fully quit Claude Desktop (system tray → Quit on Windows; Cmd+Q on macOS).
2. Relaunch. Open **Settings → Developer → Local MCP servers**. You should see `github` listed with a green/connected indicator.
3. In a new chat, ask: **"List my 5 most recently updated GitHub repos."** Claude should call the `github` MCP tool and return real repo names.

### Appendix — Managed vs Local MCP servers

Cowork has two MCP configuration keys. They look similar, but one of them **only works for org admins with signed policy**.

| Layer | Config key | Who controls it | Use it when |
|---|---|---|---|
| **Local MCP servers** (end-user) | **top-level** `mcpServers` | You, on your own machine | You want to add a personal MCP server (GitHub, Notion, filesystem, etc.) — this is what Part 4 uses. |
| **Managed MCP servers** (admin-only) | `enterpriseConfig.managedMcpServers` | Org admin via MDM / signed configuration | Your org IT wants to fleet-deploy a remote MCP server to every user. **Cowork silently ignores this key when it's written by an end user** — it only activates when delivered through a signed enterprise channel. The Managed panel in Settings shows a 🔒 icon when you don't have the policy signature. |

**Symptom to remember:** if you add a server to `enterpriseConfig.managedMcpServers`, restart Claude, and the Local MCP servers panel shows "No servers added" while the Managed panel shows the lock icon — you're not an admin; move the block to top-level `mcpServers`.

---

## If something goes wrong

### Inference setup

| Problem | Most likely fix |
|---|---|
| App shows the normal sign-in screen | The config file didn't save or has a typo. Reopen it via Settings → Developer → Edit Config, check for missing quotes or commas. |
| "My edits keep disappearing after restart" | You edited `%APPDATA%\Claude-3p` but you have the Microsoft Store build, which lives under `%LOCALAPPDATA%\Packages\Claude_<suffix>\LocalCache\Roaming\Claude-3p`. Run `.\scripts\find-cowork-config.ps1` to confirm the right path. |
| Model picker is empty | The base URL is wrong, or your key doesn't have access. Double-check the URL is exactly `https://api.asksage.ai/server/anthropic` with no trailing slash. |
| "Unauthorized" or "401" error | The API key is wrong, missing, or has extra spaces. Paste it again carefully — or re-run `.\scripts\deploy-config.ps1` to redeploy with a fresh SecureString prompt. |
| "Model not found" error | That model isn't enabled on your Ask Sage tenant. Remove it from the `inferenceModels` list and try another. |
| Changes aren't taking effect | You didn't fully quit before reopening. Quit from the system tray / Dock, not just the window. |

### Plugins

| Problem | Most likely fix |
|---|---|
| `claude.com/plugins` install button does nothing | Desktop app isn't registered as the `claude://` handler. Quit fully, reopen Cowork, try again. |
| CLI install reports "marketplace not found" | Run `claude plugin marketplace add anthropics/knowledge-work-plugins` once, then retry the installs. |
| Slash commands don't appear after install | Restart the Cowork chat session (new conversation). Plugins load on session start. |
| Plugin's MCP connectors don't work | Expected — you need to authenticate each external tool (Slack, Notion, etc.) separately. See the plugin's README in the upstream repo. |
| "Network access to github.com is blocked by egress settings" on Sync | Your Cowork tenant's egress allowlist blocks GitHub. Either ask your Owner/Admin to add github.com (Settings → Capabilities → Network egress → Package managers only), or use the [offline sideload in Part 3](#part-3--offline-sideload-when-egress-is-blocked). |
| Sideload: "No marketplace found at path" | The `.claude-plugin\marketplace.json` file isn't at the root of your org-plugins folder. You probably skipped the `Move-Item` step that flattens the extracted ZIP. Re-run Step 2. |
| Sideload: partner plugins still fail | Expected — plugins with `url` sources in marketplace.json still need outbound GitHub access. Either allowlist github.com or skip those plugins; the 11 recommended ones are all bundled locally. |

### GitHub MCP (Part 4)

| Problem | Most likely fix |
|---|---|
| Local MCP servers panel shows "No servers added" after restart | You put the GitHub block under `enterpriseConfig.managedMcpServers` instead of top-level `mcpServers`. Only the top-level key takes effect for end users. Move the block. |
| Managed MCP servers panel is locked (🔒) | Expected for non-admins. See the appendix in Part 4 — this panel only activates under signed MDM policy. |
| `initialize` handshake times out after 60s | You're running the deprecated npm `@modelcontextprotocol/server-github` via `npx -y`. Switch to the Go binary (Part 4 Step 2). |
| "401 Unauthorized" from github-mcp-server | Bad or expired PAT. Regenerate it on GitHub and re-run `.\scripts\install-github-mcp.ps1`. |
| `github-mcp-server.exe` not found on PATH | The binary lives at `%LOCALAPPDATA%\Programs\github-mcp-server\github-mcp-server.exe` and is referenced by absolute path in the config — PATH doesn't matter. If the file is missing, re-run the installer. |

---

## Keep your secrets safe

- Treat your Ask Sage API key and GitHub PAT like passwords. Don't commit the config file to Git, don't email it.
- The deploy and install scripts in this repo prompt with `Read-Host -AsSecureString`, keep the plaintext only in an unmanaged BSTR for the duration of one write call, and scrub it with `ZeroFreeBSTR`. Use them over hand-editing whenever practical.
- If you think a secret has been exposed: rotate the Ask Sage key in the Ask Sage console, revoke the GitHub PAT at [github.com/settings/tokens](https://github.com/settings/tokens), and re-run the deploy scripts to load fresh ones.

---

## Pin a known-good version

This repo uses semantic version tags. To pin your team to a tested baseline, reference a release tag instead of `main`:

- Latest: [releases/latest](https://github.com/JLay2026/claude-cowork-asksage-quickstart/releases/latest)
- Tag-specific: [releases/tag/v1.3](https://github.com/JLay2026/claude-cowork-asksage-quickstart/releases/tag/v1.3)

See [CHANGELOG.md](./CHANGELOG.md) for what's changed between versions.
