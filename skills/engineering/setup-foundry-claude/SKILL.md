---
name: setup-foundry-claude
description: Set up a PowerShell wrapper that launches Claude Code against Azure AI Foundry without leaking provider config into the rest of the shell session, pin the model aliases to current models, and add a ccstatusline badge showing when an override endpoint is active. Use when Claude Code should run against Foundry, when `opus`/`sonnet` resolve to older models than expected, or when a provider wrapper contaminates later `claude` runs in the same terminal.
---

# Foundry Wrapper for Claude Code

## What This Sets Up

- **`foundry_claude`** — a PowerShell function launching Claude Code against Azure AI Foundry
- **`Invoke-Claude`** — a helper that scopes provider env vars to a single run instead of the whole shell
- **Model alias pinning** so `opus`/`sonnet`/`haiku`/`fable` resolve to current models
- **A ccstatusline badge** that appears only when an override endpoint is in use

## The Two Problems This Solves

### 1. Env vars leak into the whole shell session

`$env:X = "..."` inside a PowerShell function is **not** scoped to that function. It writes to the process environment of the entire shell and persists until the window closes.

So a naive wrapper permanently flips the shell into Foundry mode, and every later `claude` in that terminal silently inherits it. With several wrappers (Foundry, a proxy, a third-party endpoint) they also contaminate each other.

Fix: clear every managed variable, apply only this run's config, restore on exit.

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
for m in claude-opus-5 claude-sonnet-5 claude-haiku-4-5 claude-fable-5; do
  r=$(curl -s -X POST "https://<RESOURCE>.services.ai.azure.com/anthropic/v1/messages" \
    -H "x-api-key: $ANTHROPIC_FOUNDRY_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "{\"model\":\"$m\",\"max_tokens\":4,\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}")
  echo "$r" | grep -q '"type":"message"' && echo "[OK] $m" || echo "[FAIL] $m"
done
```

Pin only models that come back `[OK]`.

### 3. Add the wrapper to the PowerShell profile

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

Plain `claude` needs no wrapper. Once `foundry_claude` exits the environment is already restored.

**Adding more wrappers later**: give each its own `Config` hashtable and add any new variable it sets to `$script:ClaudeEnvKeys`. A variable missing from that list is a variable that can leak.

### 4. Check the profile parses

```bash
pwsh -NoProfile -Command '$e=$null; $null=[System.Management.Automation.Language.Parser]::ParseFile("<PROFILE_PATH>",[ref]$null,[ref]$e); if($e){$e|%{$_.Message}}else{"[OK] syntax valid"}'
```

### 5. Add the ccstatusline provider badge (optional)

Config lives at `~/.config/ccstatusline/settings.json`. Add as the **first** widget of the first line so it reads as a prefix:

```json
{
  "id": "<uuid>",
  "type": "custom-command",
  "commandPath": "if defined CLAUDE_CODE_USE_FOUNDRY (echo FOUNDRY) else (echo.)",
  "timeout": 3000,
  "bold": true
}
```

How it behaves:

- ccstatusline trims command output and **hides widgets that render empty**, so `echo.` in the default branch means a normal session looks untouched. The badge appears only when you're *not* on the standard endpoint — the direction worth being warned about.
- The widget runs via `execSync` with `env: process.env`, so it sees the environment Claude Code was launched with. On Windows that goes through `cmd.exe`, so use `cmd` syntax (`if defined ...`), not bash or PowerShell.
- On timeout it renders a visible `[Timeout]`. A `cmd` spawn is ~40 ms, so `3000` leaves ample headroom.

Widget fields are top-level, not nested under `metadata`: `commandPath`, `timeout`, `maxWidth`, `preserveColors`.

### 6. Verify

Run a headless one-shot in a shell scrubbed of the Foundry variables, and confirm both the model resolution and the cleanup:

```powershell
. $PROFILE
"BEFORE: [$env:CLAUDE_CODE_USE_FOUNDRY]"
foundry_claude -p "Reply with only your exact model ID, nothing else." --model opus
"AFTER:  [$env:CLAUDE_CODE_USE_FOUNDRY]"
```

- [ ] The model ID printed is the pinned model, not an older generation
- [ ] `BEFORE` and `AFTER` are both empty — no leak
- [ ] A plain `claude` in the same window still uses the default endpoint
- [ ] Status line shows the badge under `foundry_claude` and hides it otherwise

To confirm which model a subagent really used, ask it directly — the Agent tool result echoes only the alias you passed, not the resolved ID.

## Notes

- Claude Code reads these variables **once at launch**. Changing them mid-session has no effect; restart.
- A real key in the profile is plaintext on disk. One `$script:FoundryKey` line makes it a single place to swap for a credential-store lookup or rotate.
- If a Powerline theme is active, it assigns colors by visible-widget index, so everything shifts one slot when the badge shows. Empty widgets consume no slot, so default sessions are unaffected. Set `preserveColors` and emit your own ANSI codes if you want the badge pinned to a fixed color.
