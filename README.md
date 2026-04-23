# Claude Cowork + Ask Sage Quickstart

A beginner-friendly walkthrough to point Claude Desktop at Ask Sage for inference, then layer on the Anthropic knowledge-work plugin suite. Takes about 15 minutes end-to-end.

## What you'll end up with

- Claude Desktop running in Cowork 3P mode, with all inference flowing through your organization's Ask Sage tenant.
- The six Claude models (Opus 4.7/4.6/4.5, Sonnet 4.6/4.5, Haiku 4.5) available in the model picker.
- All 11 Anthropic knowledge-work plugins installed — productivity, sales, customer-support, product-management, marketing, legal, finance, data, enterprise-search, bio-research, and cowork-plugin-management.
- If your tenant blocks outbound network egress (most hardened enterprise Cowork tenants do), you can sideload the plugin suite from a local folder instead of the hosted marketplace. See [Part 3](#part-3--offline-sideload-when-egress-is-blocked).

## Before you start

- **Claude Desktop** installed from [claude.com/download](https://claude.com/download)
- **Your Ask Sage API key** (a long string of letters and numbers)
- **A generated UUID** — we'll create one in Step 3

---

## Part 1 — Ask Sage inference setup

### Step 1 — Install and open Claude Desktop

1. Download and install Claude Desktop.
2. Launch it. If a sign-in screen appears, **don't sign in yet** — just leave it open.

### Step 2 — Turn on Developer Mode

1. In the top menu, click **Help → Troubleshooting → Enable Developer Mode**.
2. The app will acknowledge the change. You may need to restart it.

### Step 3 — Generate a UUID

A UUID is just a unique ID string. Pick one method:

- **Windows (PowerShell):** open PowerShell and run `[guid]::NewGuid().ToString()`
- **Mac/Linux (Terminal):** run `uuidgen`
- **No terminal handy:** use [uuidgenerator.net](https://www.uuidgenerator.net/) and copy the "Version 4" value

Copy the result — it looks like `f4a1c8e2-9b3d-4e7f-a6c5-1d8b2e9f3a4c`. You'll paste it in Step 5.

### Step 4 — Open the config file

1. In Claude Desktop, open **Settings**.
2. Click **Developer** in the left sidebar.
3. Find the **Local MCP servers** section.
4. Click **Edit Config**.

Your default text editor opens a file called **`claude_desktop_config.json`**. This is the file you'll replace.

### Step 5 — Replace the file contents

1. Select everything in the open file (Ctrl+A on Windows, Cmd+A on Mac) and delete it.
2. Copy the contents of [`claude_desktop_config.json`](./claude_desktop_config.json) from this repo and paste it in.
3. Make two edits:
   - Replace `PASTE_YOUR_ASKSAGE_KEY_HERE` with your Ask Sage API key (keep the quotes around it).
   - Replace `PASTE_YOUR_UUID_HERE` with the UUID you generated in Step 3 (keep the quotes).
4. **Save** the file (Ctrl+S / Cmd+S) and close the editor.

### Step 6 — Restart Claude Desktop

Fully quit Claude Desktop and reopen it. It must be a **complete quit**, not just closing the window:

- **Windows:** right-click the Claude icon in the system tray → Quit.
- **Mac:** Cmd+Q, or right-click in the Dock → Quit.

When it relaunches, it should go straight into Cowork mode (no sign-in screen).

### Step 7 — Test it

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

## If something goes wrong

### Inference setup

| Problem | Most likely fix |
|---|---|
| App shows the normal sign-in screen | The config file didn't save or has a typo. Reopen it via Settings → Developer → Edit Config, check for missing quotes or commas. |
| Model picker is empty | The base URL is wrong, or your key doesn't have access. Double-check the URL is exactly `https://api.asksage.ai/server/anthropic` with no trailing slash. |
| "Unauthorized" or "401" error | The API key is wrong, missing, or has extra spaces. Paste it again carefully. |
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

---

## Keep your key safe

Treat your Ask Sage API key like a password. Don't commit the config file to Git, don't email it, and if you think it's been exposed, generate a new key in the Ask Sage console and paste that one instead.

---

## Pin a known-good version

This repo uses semantic version tags. To pin your team to a tested baseline, reference a release tag instead of `main`:

- Latest: [releases/latest](https://github.com/JLay2026/claude-cowork-asksage-quickstart/releases/latest)
- Tag-specific: [releases/tag/v1.2](https://github.com/JLay2026/claude-cowork-asksage-quickstart/releases/tag/v1.2)

See [CHANGELOG.md](./CHANGELOG.md) for what's changed between versions.
