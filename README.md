# Claude Cowork + Ask Sage Quickstart

A beginner-friendly walkthrough to point Claude Desktop at Ask Sage for inference. Takes about 10 minutes.

## Before you start

You'll need three things:

- **Claude Desktop** installed from [claude.com/download](https://claude.com/download)
- **Your Ask Sage API key** (a long string of letters and numbers)
- **A generated UUID** — we'll create one in Step 3

## Step 1 — Install and open Claude Desktop

1. Download and install Claude Desktop.
2. Launch it. If a sign-in screen appears, **don't sign in yet** — just leave it open.

## Step 2 — Turn on Developer Mode

1. In the top menu, click **Help → Troubleshooting → Enable Developer Mode**.
2. The app will acknowledge the change. You may need to restart it.

## Step 3 — Generate a UUID

A UUID is just a unique ID string. Pick one method:

- **Windows (PowerShell):** open PowerShell and run `[guid]::NewGuid().ToString()`
- **Mac/Linux (Terminal):** run `uuidgen`
- **No terminal handy:** use [uuidgenerator.net](https://www.uuidgenerator.net/) and copy the "Version 4" value

Copy the result — it looks like `f4a1c8e2-9b3d-4e7f-a6c5-1d8b2e9f3a4c`. You'll paste it in Step 5.

## Step 4 — Open the config file

1. In Claude Desktop, open **Settings**.
2. Click **Developer** in the left sidebar.
3. Find the **Local MCP servers** section.
4. Click **Edit Config**.

Your default text editor opens a file called **`claude_desktop_config.json`**. This is the file you'll replace.

## Step 5 — Replace the file contents

1. Select everything in the open file (Ctrl+A on Windows, Cmd+A on Mac) and delete it.
2. Copy the contents of [`claude_desktop_config.json`](./claude_desktop_config.json) from this repo and paste it in.
3. Make two edits:
   - Replace `PASTE_YOUR_ASKSAGE_KEY_HERE` with your Ask Sage API key (keep the quotes around it).
   - Replace `PASTE_YOUR_UUID_HERE` with the UUID you generated in Step 3 (keep the quotes).
4. **Save** the file (Ctrl+S / Cmd+S) and close the editor.

## Step 6 — Restart Claude Desktop

Fully quit Claude Desktop and reopen it. It must be a **complete quit**, not just closing the window:

- **Windows:** right-click the Claude icon in the system tray → Quit.
- **Mac:** Cmd+Q, or right-click in the Dock → Quit.

When it relaunches, it should go straight into Cowork mode (no sign-in screen).

## Step 7 — Test it

1. Start a new chat.
2. Open the model picker at the top. You should see the six Claude models from the config.
3. Pick one (Sonnet 4.5 is a good default) and send a test message like "hello".
4. If you get a response, you're done.

## If something goes wrong

| Problem | Most likely fix |
|---|---|
| App shows the normal sign-in screen | The config file didn't save or has a typo. Reopen it via Settings → Developer → Edit Config, check for missing quotes or commas. |
| Model picker is empty | The base URL is wrong, or your key doesn't have access. Double-check the URL is exactly `https://api.asksage.ai/server/anthropic` with no trailing slash. |
| "Unauthorized" or "401" error | The API key is wrong, missing, or has extra spaces. Paste it again carefully. |
| "Model not found" error | That model isn't enabled on your Ask Sage tenant. Remove it from the `inferenceModels` list and try another. |
| Changes aren't taking effect | You didn't fully quit before reopening. Quit from the system tray / Dock, not just the window. |

## Keep your key safe

Treat your Ask Sage API key like a password. Don't commit the config file to Git, don't email it, and if you think it's been exposed, generate a new key in the Ask Sage console and paste that one instead.

---

Once you confirm a model responds, you're running Claude Desktop entirely through your organization's Ask Sage gateway.
