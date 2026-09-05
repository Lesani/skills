---
name: setup-foundry-claude
description: Set up a shell wrapper that launches Claude Code against Azure AI Foundry without leaking provider config into the rest of the shell session, pin the model aliases to current models, and add a ccstatusline badge showing when an override endpoint is active. Covers PowerShell (Windows) and bash/zsh (Linux/macOS), plus an optional LiteLLM proxy so the same wrapper can run non-Anthropic models (GPT etc.) hosted on the Foundry resource, and a desktop launcher entry. Use when Claude Code should run against Foundry, when `opus`/`sonnet` resolve to older models than expected, or when a provider wrapper contaminates later `claude` runs in the same terminal.
---

# Foundry Wrapper for Claude Code

## What This Sets Up

- **`foundry_claude`** — a shell function launching Claude Code against Azure AI Foundry
- **`Invoke-Claude`** / **`claude_run`** — a helper that scopes provider env vars to a single run instead of the whole shell
- **Model alias pinning** so `opus`/`sonnet`/`haiku`/`fable` resolve to current models
- **A ccstatusline badge** that appears only when an override endpoint is in use
- **Optional: other providers on the same resource** — a loopback LiteLLM proxy translating Anthropic Messages for GPT-class deployments, so `/model gpt-5` works inside one Claude Code session (step 7)

Each step below gives both a **PowerShell (Windows)** and a **bash / zsh (Linux, macOS)** variant. Do only the one for your shell.

## The Two Problems This Solves

### 1. Env vars leak into the whole shell session

**PowerShell**: `$env:X = "..."` inside a function is **not** scoped to that function. It writes to the process environment of the entire shell and persists until the window closes.

So a naive wrapper permanently flips the shell into Foundry mode, and every later `claude` in that terminal silently inherits it. With several wrappers (Foundry, a proxy, a third-party endpoint) they also contaminate each other.

Fix: clear every managed variable, apply only this run's config, restore on exit.

**bash / zsh**: the same trap exists — `export X=1` inside a function writes to the shell's own environment and outlives the function. But POSIX shells have a better tool: `env -u VAR ... VAR=val command` builds the child's environment directly, so nothing is ever set in the parent. No save/restore, no cleanup path to get wrong, and the wrapper cannot leak even if it's interrupted.

The prefix form alone (`X=1 claude`) is *not* enough — it adds variables but doesn't clear ones already exported in the shell. The `-u` flags are what make switching wrappers safe.

### 2. Alias defaults lag behind released models

Claude Code ships a built-in alias table that does not necessarily point at the newest model. An `opus` alias can resolve to a previous Opus generation even when a newer one is deployed and working.

The alias table is what's stale — **not** the Foundry deployment. Verify before assuming a model is unavailable (step 2).

Fix: set `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU,FABLE}_MODEL` explicitly.

## Steps

### 1. Collect Foundry details

You need the resource name and an API key. Leave the key empty in the profile and fill it in locally — never commit a real key.

### 2. Verify which models the resource actually serves

Probe the endpoint before pinning anything. A model that returns a message here is safe to pin:

```bash
for m in claude-opus-5 claude-sonnet-5 claude-haiku-4-5 claude-fable-5-1; do
  r=$(curl -s -X POST "https://<RESOURCE>.services.ai.azure.com/anthropic/v1/messages" \
    -H "x-api-key: $ANTHROPIC_FOUNDRY_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "{\"model\":\"$m\",\"max_tokens\":4,\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}")
  echo "$r" | grep -q '"type":"message"' && echo "[OK] $m" || echo "[FAIL] $m"
done
```

Pin only models that come back `[OK]`.

### 3. Add the wrapper to the shell profile

#### PowerShell (Windows)

Write to `$PROFILE` (typically `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`). Back up the existing profile first.

```powershell
# Every variable any claude wrapper touches. Invoke-Claude clears all of them before
# each run, so switching wrappers in one shell can never inherit the previous config.
$script:ClaudeEnvKeys = @(
  'ANTHROPIC_BASE_URL'
  'ANTHROPIC_AUTH_TOKEN'
  'ANTHROPIC_API_KEY'
  'API_TIMEOUT_MS'
  'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC'
  'CLAUDE_CODE_USE_FOUNDRY'
  'ANTHROPIC_FOUNDRY_API_KEY'
  'ANTHROPIC_FOUNDRY_RESOURCE'
  'ANTHROPIC_FOUNDRY_BASE_URL'
  'ANTHROPIC_DEFAULT_OPUS_MODEL'
  'ANTHROPIC_DEFAULT_SONNET_MODEL'
  'ANTHROPIC_DEFAULT_HAIKU_MODEL'
  'ANTHROPIC_DEFAULT_FABLE_MODEL'
)

$script:FoundryKey = ""              # fill in locally, never commit
$script:FoundryResource = ""         # e.g. my-foundry-resource

function Invoke-Claude {
  param(
    [hashtable] $Config = @{},
    [string[]]  $ClaudeArgs = @()
  )

  $saved = @{}
  foreach ($key in $script:ClaudeEnvKeys) {
    $saved[$key] = [Environment]::GetEnvironmentVariable($key)
    Remove-Item "env:$key" -ErrorAction SilentlyContinue
  }

  try {
    foreach ($key in $Config.Keys) { Set-Item "env:$key" $Config[$key] }
    claude @ClaudeArgs
  }
  finally {
    foreach ($key in $script:ClaudeEnvKeys) {
      if ([string]::IsNullOrEmpty($saved[$key])) {
        Remove-Item "env:$key" -ErrorAction SilentlyContinue
      } else {
        Set-Item "env:$key" $saved[$key]
      }
    }
  }
}

function foundry_claude {
  Invoke-Claude -ClaudeArgs $args -Config @{
    ANTHROPIC_FOUNDRY_API_KEY                = $script:FoundryKey
    ANTHROPIC_FOUNDRY_RESOURCE               = $script:FoundryResource
    CLAUDE_CODE_USE_FOUNDRY                  = "1"
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
    ANTHROPIC_DEFAULT_OPUS_MODEL             = "claude-opus-5"
    ANTHROPIC_DEFAULT_SONNET_MODEL           = "claude-sonnet-5"
    ANTHROPIC_DEFAULT_HAIKU_MODEL            = "claude-haiku-4-5"
    ANTHROPIC_DEFAULT_FABLE_MODEL            = "claude-fable-5"
  }
}
```

#### bash / zsh (Linux, macOS)

Write to `~/.bashrc` (bash) or `~/.zshrc` (zsh). Back up the existing file first.

```bash
# Every variable any claude wrapper touches. claude_run unsets all of them for the
# child process, so switching wrappers in one shell can never inherit the previous config.
CLAUDE_ENV_KEYS=(
  ANTHROPIC_BASE_URL
  ANTHROPIC_AUTH_TOKEN
  ANTHROPIC_API_KEY
  API_TIMEOUT_MS
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
  CLAUDE_CODE_USE_FOUNDRY
  ANTHROPIC_FOUNDRY_API_KEY
  ANTHROPIC_FOUNDRY_RESOURCE
  ANTHROPIC_FOUNDRY_BASE_URL
  ANTHROPIC_DEFAULT_OPUS_MODEL
  ANTHROPIC_DEFAULT_SONNET_MODEL
  ANTHROPIC_DEFAULT_HAIKU_MODEL
  ANTHROPIC_DEFAULT_FABLE_MODEL
)

FOUNDRY_KEY=""                       # fill in locally, never commit
FOUNDRY_RESOURCE=""                  # e.g. my-foundry-resource

# claude_run VAR=VAL ... -- <command> [args]
# Builds the child environment directly: nothing is ever set in this shell.
claude_run() {
  local -a scrub=() config=()
  local k
  for k in "${CLAUDE_ENV_KEYS[@]}"; do scrub+=(-u "$k"); done
  while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do config+=("$1"); shift; done
  [ "$#" -gt 0 ] && shift
  env "${scrub[@]}" "${config[@]}" "$@"
}

foundry_claude() {
  claude_run \
    ANTHROPIC_FOUNDRY_API_KEY="$FOUNDRY_KEY" \
    ANTHROPIC_FOUNDRY_RESOURCE="$FOUNDRY_RESOURCE" \
    CLAUDE_CODE_USE_FOUNDRY=1 \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
    ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-5 \
    ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-5 \
    ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4-5 \
    ANTHROPIC_DEFAULT_FABLE_MODEL=claude-fable-5 \
    -- claude "$@"
}
```

`env` execs a program found on `PATH`, so `claude` must be a real binary or shim — not a shell alias or function. `type claude` should print a path. If yours is an alias, drop to `command claude` inside a subshell instead, or point `claude_run` at the resolved path.

Plain `claude` needs no wrapper on either platform. Nothing was set in the shell, so there is nothing to undo when `foundry_claude` exits.

**Adding more wrappers later**: give each its own config block and add any new variable it sets to `$script:ClaudeEnvKeys` / `CLAUDE_ENV_KEYS`. A variable missing from that list is a variable that can leak.

### 4. Check the profile parses

**PowerShell:**

```bash
pwsh -NoProfile -Command '$e=$null; $null=[System.Management.Automation.Language.Parser]::ParseFile("<PROFILE_PATH>",[ref]$null,[ref]$e); if($e){$e|%{$_.Message}}else{"[OK] syntax valid"}'
```

**bash / zsh:**

```bash
bash -n ~/.bashrc && echo "[OK] syntax valid"     # bash
zsh  -n ~/.zshrc  && echo "[OK] syntax valid"     # zsh
```

### 5. Add the ccstatusline provider badge (optional)

Config lives at `~/.config/ccstatusline/settings.json` on every platform. Add as the **first** widget of the first line so it reads as a prefix.

**Windows** — the widget runs through `cmd.exe`, so use `cmd` syntax:

```json
{
  "id": "<uuid>",
  "type": "custom-command",
  "commandPath": "if defined CLAUDE_CODE_USE_FOUNDRY (echo FOUNDRY) else (echo.)",
  "timeout": 3000,
  "bold": true
}
```

**Linux / macOS** — the widget runs through `/bin/sh`, so use POSIX shell syntax. The trailing `|| true` is load-bearing:

```json
{
  "id": "<uuid>",
  "type": "custom-command",
  "commandPath": "[ -n \"$CLAUDE_CODE_USE_FOUNDRY\" ] && echo FOUNDRY || true",
  "timeout": 3000,
  "bold": true
}
```

How it behaves:

- ccstatusline trims command output and **hides widgets that render empty**, so a normal session looks untouched. The badge appears only when you're *not* on the standard endpoint — the direction worth being warned about.
- The widget runs via `execSync` with `env: process.env`, so it sees the environment Claude Code was launched with.
- **A non-zero exit renders a visible `[Exit: N]`, not an empty string.** On Windows both `cmd` branches exit 0, so the naive form is safe. On Linux/macOS `[ -n "$X" ] && echo FOUNDRY` exits **1** when the variable is unset, and the status line shows a permanent `[Exit: 1]` instead of hiding. `|| true` is what forces exit 0 in the empty branch.
- On timeout it renders `[Timeout]`. A shell spawn is a few tens of ms, so `3000` leaves ample headroom.

Widget fields are top-level, not nested under `metadata`: `commandPath`, `timeout`, `maxWidth`, `preserveColors`.

To test a badge without restarting a session, feed ccstatusline a status-line JSON payload on stdin:

```bash
echo '{"model":{"display_name":"Opus 5"},"workspace":{"current_dir":"/tmp"},"session_id":"x","transcript_path":"/dev/null"}' \
  | CLAUDE_CODE_USE_FOUNDRY=1 ccstatusline
```

### 6. Verify

Run a headless one-shot in a shell scrubbed of the Foundry variables, and confirm both the model resolution and the cleanup.

**PowerShell:**

```powershell
. $PROFILE
"BEFORE: [$env:CLAUDE_CODE_USE_FOUNDRY]"
foundry_claude -p "Reply with only your exact model ID, nothing else." --model opus
"AFTER:  [$env:CLAUDE_CODE_USE_FOUNDRY]"
```

**bash / zsh:**

```bash
source ~/.bashrc                      # or ~/.zshrc
echo "BEFORE: [$CLAUDE_CODE_USE_FOUNDRY]"
foundry_claude -p "Reply with only your exact model ID, nothing else." --model opus
echo "AFTER:  [$CLAUDE_CODE_USE_FOUNDRY]"
```

- [ ] The model ID printed is the pinned model, not an older generation
- [ ] `BEFORE` and `AFTER` are both empty — no leak
- [ ] A plain `claude` in the same window still uses the default endpoint
- [ ] Status line shows the badge under `foundry_claude` and hides it otherwise

To confirm which model a subagent really used, ask it directly — the Agent tool result echoes only the alias you passed, not the resolved ID.

### 7. Optional: other providers through a LiteLLM proxy (bash)

Claude Code speaks only the Anthropic Messages format. To use GPT-class or other
deployments on the same Foundry resource, put a LiteLLM proxy on loopback and
point Claude Code at it with `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN`.
Claude deployments go through it too, so one session can switch models freely.

Bundled next to this file, ready to copy into `~/.config/foundry-claude/`:

| File | Role |
|---|---|
| [`foundry_claude`](./foundry_claude) | the wrapper as a **script** on `PATH` (a function can't be called from a desktop launcher). Asks for a **profile** with `gum` on a tty (`anthropic` or `openai`: what `opus/sonnet/haiku/fable` resolve to), `--profile X` / `FOUNDRY_PROFILE` skip the question, non-tty defaults to `anthropic`; `--direct` bypasses the proxy; `proxy up\|down\|reload\|status\|logs\|probe` manages it |
| [`compose.yaml`](./compose.yaml) | `ghcr.io/berriai/litellm` bound to `127.0.0.1:4000`, healthcheck, restart policy |
| [`litellm.yaml`](./litellm.yaml) | model catalogue: `claude-*` → `azure_ai/<id>` on the `/anthropic` base, OpenAI deployments → `azure/responses/<deployment>` on `<resource>.openai.azure.com`, other providers → `azure_ai/<deployment>` on the resource root |
| [`env.example`](./env.example) | resource, key, generated master key — `chmod 600`, never committed |

```bash
mkdir -p ~/.config/foundry-claude && cp compose.yaml litellm.yaml ~/.config/foundry-claude/
cp env.example ~/.config/foundry-claude/.env && chmod 600 ~/.config/foundry-claude/.env   # then fill it in
install -m 755 foundry_claude ~/.local/bin/foundry_claude
foundry_claude proxy probe          # lists deployments, sends a request through every catalogue entry
```

Rules that came out of building it:

- **Pin only what `probe` returns `[OK]`.** The name after `azure_ai/` is the Foundry *deployment name*, not the catalogue name, and Foundry has no startup model check — a wrong pin fails at the first prompt. The deployment list comes from `https://<resource>.openai.azure.com/openai/deployments?api-version=2023-03-15-preview` with the `api-key` header; the `/openai/v1/models` endpoint lists the catalogue, not your deployments.
- **`FOUNDRY_RESOURCE` is the resource, not the project.** A Foundry project endpoint looks like `https://<resource>.services.ai.azure.com/api/projects/<project>`; the value you want is `<resource>`. The script also accepts the full host. A project name in that field shows up as NXDOMAIN on the first request.
- **OpenAI deployments must use the Responses API route** (`azure/responses/<deployment>`, `api_version: preview`). On chat completions Azure answers `Function tools with reasoning_effort are not supported … use /v1/responses`, which only shows up once Claude Code sends tools — the 4-token probe passes either way. The Responses route handled tool calls plus adaptive thinking in testing; the Foundry Models endpoint (`azure_ai/`) stayed fine for non-OpenAI providers such as Kimi.
- **A profile is just a set of alias pins.** `pins <profile>` emits `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU,FABLE}_MODEL` plus `ANTHROPIC_MODEL=opus`, so `--model opus`, `/model sonnet` and subagents declared with `model: haiku` all land on the profile's deployments. `[claude-code:unrecognized_model]` on stderr for a non-Claude id is informational.
- **`litellm.yaml` is read once at start.** `proxy reload` (and `probe`, which calls it) restarts the container; `proxy up` alone does not pick up catalogue edits.
- **Set `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` on the proxy path.** A session can switch to a non-Claude upstream at any time, and those reject the beta tool-schema fields with `400`. `drop_params: true` in `litellm_settings` covers the body fields LiteLLM can't translate.
- **Non-Claude models never show in the `/model` picker.** Gateway model discovery keeps only ids containing `claude` or `anthropic`. Type `/model gpt-5`; it works.
- **Bearer, not x-api-key.** LiteLLM reads `Authorization: Bearer <master key>`, so the wrapper sets `ANTHROPIC_AUTH_TOKEN`, which also takes precedence over a saved claude.ai login without a prompt. A wrong token gets `400` from LiteLLM, not `401`.
- **Add every new variable to the scrub list.** The script's `CLAUDE_ENV_KEYS` grew to include `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` and the badge variable — anything missing there is a variable that can leak between wrappers.
- **Socket-activated docker needs an on-demand starter.** `docker compose up -d --wait` in the wrapper is idempotent and also boots the daemon; nothing has to run at login.
- Remote Control and voice dictation are off in a gateway session (they need a claude.ai identity).

**Badge**: with two wrappers, key the ccstatusline widget on one variable both set — the bundled script exports `CLAUDE_PROVIDER_BADGE` (`FOUNDRY` or `FOUNDRY/LITELLM`) and the widget is `[ -n "$CLAUDE_PROVIDER_BADGE" ] && echo "$CLAUDE_PROVIDER_BADGE" || true`.

**Launcher entry** (Omarchy / any XDG desktop): a script on `PATH` is all a `.desktop` file needs.

```bash
omarchy tui install "Foundry Claude" foundry_claude tile https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/claude-ai.png
# generic: Exec=xdg-terminal-exec --app-id=TUI.tile -e foundry_claude ; add Path=<project dir> to choose the start directory
```

Verify the proxy path the same way as step 6, then confirm a non-Claude model answers:

```bash
foundry_claude --profile openai -p "Use the Bash tool to run: uname -r. Reply with only the output." --model opus --allowedTools Bash
sudo docker logs foundry-litellm 2>&1 | grep 'POST /v1/messages'   # one line per request with upstream status
```

## Notes

- Claude Code reads these variables **once at launch**. Changing them mid-session has no effect; restart.
- A real key in the profile is plaintext on disk. One `$script:FoundryKey` / `FOUNDRY_KEY` line makes it a single place to swap for a credential-store lookup or rotate.
- If a Powerline theme is active, it assigns colors by visible-widget index, so everything shifts one slot when the badge shows. Empty widgets consume no slot, so default sessions are unaffected. Set `preserveColors` and emit your own ANSI codes if you want the badge pinned to a fixed color.
- On a distro with no system `node` (immutable images like Bazzite), ccstatusline installed via bun needs a launcher shim on `PATH` that runs the CLI under bun, and `statusLine.command` in `~/.claude/settings.json` should point at that shim.
