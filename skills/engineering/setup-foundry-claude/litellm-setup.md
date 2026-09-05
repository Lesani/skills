# Multi-provider Foundry setup with LiteLLM

Install procedure for the bundled `foundry_claude` script. Follow it top to
bottom on a fresh Linux machine; every step names the file it touches and how
to check it worked. Nothing here modifies the plain `claude` command.

## How it fits together

```
foundry_claude ──(asks profile)──► env -u <scrub> ANTHROPIC_BASE_URL=http://127.0.0.1:4000
                                      ANTHROPIC_AUTH_TOKEN=<master key> ANTHROPIC_DEFAULT_*_MODEL=<pins>
                                      ──► claude
                                            │  Anthropic Messages API
                                            ▼
                               foundry-litellm (docker, loopback :4000, litellm.yaml)
                     ┌──────────────────────┼───────────────────────────┐
     claude-* ───────┘          gpt-* ──────┘              other ───────┘
 azure_ai/<id>            azure/responses/<deployment>     azure_ai/<deployment>
 <res>.services.ai.azure.com/anthropic   <res>.openai.azure.com   <res>.services.ai.azure.com/models
```

- Claude Code only speaks the Anthropic Messages format. LiteLLM translates it
  per upstream, so one session can `/model` between Claude, GPT and other
  deployments on the same Foundry resource.
- The wrapper builds the child environment with `env -u …`; nothing is exported
  into the calling shell, so a plain `claude` afterwards still uses the
  claude.ai subscription.
- A **profile** is a set of alias pins: what `opus`, `sonnet`, `haiku` and
  `fable` resolve to. `--model opus`, `/model sonnet` and subagents declared
  with `model: haiku` all land on the profile's deployments.
- `--direct` skips the proxy and uses Claude Code's native Foundry integration
  (Claude deployments only, full feature fidelity).

## Prerequisites

| Need | Check | Notes |
|---|---|---|
| Claude Code on `PATH` | `type claude` prints a path | must be a binary or shim, not a shell function |
| docker + compose v2 | `docker compose version` | the script calls `sudo -n docker …`; `sudo` must be passwordless for docker, or add the user to the `docker` group and drop `sudo -n` from `dc()` |
| python3, curl | `python3 --version` | used by `proxy probe` |
| gum (optional) | `command -v gum` | interactive profile picker; without it the script silently defaults to `anthropic` |
| Foundry resource + API key | portal → *Endpoints and keys* | see step 2 for resource vs. project |

## 1. Install the files

```bash
mkdir -p ~/.config/foundry-claude ~/.local/bin
cp compose.yaml litellm.yaml ~/.config/foundry-claude/
cp env.example ~/.config/foundry-claude/.env && chmod 600 ~/.config/foundry-claude/.env
install -m 755 foundry_claude ~/.local/bin/foundry_claude
docker pull ghcr.io/berriai/litellm:main-latest        # ~1.7 GB, do it once up front
```

`~/.local/bin` must be on `PATH` (it is on most distros; `echo "$PATH"`).

## 2. Fill in `.env`

```
FOUNDRY_RESOURCE=<resource>          # NOT the project — see below
AZURE_AI_API_KEY=<key>
LITELLM_MASTER_KEY=sk-<openssl rand -hex 24>
```

**Resource vs. project.** The Foundry portal shows a project endpoint like
`https://<resource>.services.ai.azure.com/api/projects/<project>`. The value you
want is `<resource>`; the project name in that field fails with NXDOMAIN on the
first message. The script also accepts the full host
(`<resource>.services.ai.azure.com`).

`LITELLM_MASTER_KEY` is the credential Claude Code presents to the local proxy.
It never leaves the machine; generate it, don't reuse anything.

## 3. Find out what the resource serves

```bash
foundry_claude proxy probe
```

The first block lists every **deployment** on the resource (deployment name →
model). This comes from
`https://<resource>.openai.azure.com/openai/deployments?api-version=2023-03-15-preview`
with the `api-key` header. Do not use `/openai/v1/models` for this — it lists
the Azure catalogue, not what is deployed.

The second block sends a small request through every `model_name` in
`litellm.yaml` and prints `[OK]` / `[FAIL] <reason>`.

## 4. Edit `litellm.yaml` to match the deployments

Three entry shapes, pick by upstream:

```yaml
  # Claude — Foundry's native Anthropic endpoint, no translation
  - model_name: claude-opus-5
    litellm_params:
      model: azure_ai/claude-opus-5
      api_base: os.environ/AZURE_AI_ANTHROPIC_BASE
      api_key: os.environ/AZURE_AI_API_KEY

  # OpenAI deployments — Responses API. Chat completions does NOT work with
  # Claude Code: Azure rejects function tools together with reasoning_effort.
  - model_name: gpt-5-mini
    litellm_params:
      model: azure/responses/<deployment-name>
      api_base: os.environ/AZURE_OPENAI_BASE
      api_version: preview
      api_key: os.environ/AZURE_AI_API_KEY

  # Everything else (Kimi, DeepSeek, Grok, Llama …) — Foundry Models endpoint
  - model_name: kimi-k2
    litellm_params:
      model: azure_ai/<deployment-name>
      api_base: os.environ/AZURE_AI_API_BASE
      api_key: os.environ/AZURE_AI_API_KEY
```

- `model_name` is what you type at `/model`; keep it short.
- The name after `azure_ai/` or `azure/responses/` is the **deployment name**
  from step 3, which is not always the model name (a `Kimi-K2.6-1` deployment
  serving `Kimi-K2.6`, for instance).
- `AZURE_AI_API_BASE`, `AZURE_AI_ANTHROPIC_BASE` and `AZURE_OPENAI_BASE` are
  derived in `compose.yaml` from `FOUNDRY_RESOURCE`; don't hardcode hosts.
- Foundry has no startup model check: a wrong entry fails at the first prompt,
  not at launch. Keep only `[OK]` rows.

Then:

```bash
foundry_claude proxy probe          # reloads the container first; `proxy up` alone would keep the old catalogue
```

**The probe is not proof for OpenAI deployments.** Its 4-token request has no
tools, and the tools + reasoning rejection only appears once Claude Code sends
tools. Step 6 covers that.

## 5. Set the profiles

`pins()` in `foundry_claude` holds one line per profile:

```bash
    anthropic) o=claude-opus-5;  s=claude-sonnet-5;  h=claude-haiku-4-5; f=claude-fable-5-1 ;;
    openai)    o=gpt-5.6-sol;    s=gpt-5.6-terra;    h=gpt-5.6-luna;     f=gpt-6-astra ;;
```

Change the targets to this machine's `model_name`s, add or remove profiles
(update `PROFILES=(…)` and the two `gum choose` lines in `pick_profile` to
match). Single aliases can be overridden without editing the script:
`FOUNDRY_OPENAI_OPUS_MODEL=gpt-5.6-terra` in `.env`.

Every profile also sets `ANTHROPIC_MODEL=opus`, so the session starts on the
profile's opus target.

## 6. Verify with real sessions

```bash
foundry_claude --profile anthropic -p "Reply with only your exact model ID." --model haiku
foundry_claude --profile openai    -p "Use the Bash tool to run: uname -r. Reply with only the output." --model opus --allowedTools Bash
foundry_claude --profile openai    -p "Reply with only your exact model ID." --model fable
echo "LEAK=[${ANTHROPIC_BASE_URL:-}${CLAUDE_CODE_USE_FOUNDRY:-}]"     # must print LEAK=[]
```

- The first prints the pinned Claude id.
- The second exercises tool calling on a GPT deployment — this is where a
  chat-completions entry fails with `Function tools with reasoning_effort are
  not supported … use /v1/responses`. Switch that entry to `azure/responses/`.
- `[claude-code:unrecognized_model] {"model":"gpt-…"}` on stderr is
  informational, not an error.
- `sudo docker logs foundry-litellm 2>&1 | grep 'POST /v1/messages'` shows one
  line per request with the upstream status.

Then run `foundry_claude` with no arguments in a terminal: the gum picker
appears, and `/status` inside Claude Code shows the proxy URL and
`ANTHROPIC_AUTH_TOKEN` as the credential.

## 7. Desktop launcher and status-line badge

A script on `PATH` is all a `.desktop` file needs. Omarchy:

```bash
omarchy tui install "Foundry Claude" foundry_claude tile https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/claude-ai.png
sed -i '/^Type=Application/a Path='"$HOME"'/Work' "$HOME/.local/share/applications/Foundry Claude.desktop"   # optional start dir
```

Any other XDG desktop: `Exec=xdg-terminal-exec --app-id=TUI.tile -e foundry_claude`,
`Terminal=false`. The picker runs inside the spawned terminal.

Badge: the script exports `CLAUDE_PROVIDER_BADGE` (`FOUNDRY/ANTHROPIC`,
`FOUNDRY/OPENAI`, or `FOUNDRY` for `--direct`). ccstatusline widget, first on
line one:

```json
{ "id": "<uuid>", "type": "custom-command",
  "commandPath": "[ -n \"$CLAUDE_PROVIDER_BADGE\" ] && echo \"$CLAUDE_PROVIDER_BADGE\" || true",
  "timeout": 3000, "bold": true }
```

## Day-to-day

```bash
foundry_claude                       # pick a profile, go
foundry_claude --profile openai      # skip the picker (FOUNDRY_PROFILE=openai does the same)
foundry_claude --direct              # Claude only, no proxy
foundry_claude proxy status|logs|down|reload|probe
```

- The container has `restart: unless-stopped`, but a socket-activated docker
  daemon does not start it at boot; the wrapper's `proxy up` is idempotent and
  starts both on demand.
- `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` is set on the proxy path because
  a session can switch to a non-Claude upstream at any time, and those reject
  the beta tool-schema fields with `400`. `--direct` keeps the betas.
- Remote Control and voice dictation are unavailable in a gateway session
  (they need a claude.ai identity).
- `ANTHROPIC_AUTH_TOKEN` (bearer) is the right variable for LiteLLM; a wrong
  token gets `400` from LiteLLM, not `401`.
- Non-Claude models never appear in the `/model` picker: gateway discovery
  keeps only ids containing `claude` or `anthropic`. Type the name.
- Update LiteLLM with `docker pull ghcr.io/berriai/litellm:main-latest && foundry_claude proxy reload`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Name or service not known` / NXDOMAIN in `proxy logs` | project name in `FOUNDRY_RESOURCE` | use the resource name (step 2) |
| `DeploymentNotFound` | `model:` names a deployment that doesn't exist | copy the exact deployment name from `probe` |
| `Function tools with reasoning_effort are not supported … /v1/chat/completions` | OpenAI deployment on `azure_ai/` | switch to `azure/responses/<deployment>` |
| catalogue edit has no effect | container still running the old config | `foundry_claude proxy reload` |
| picker never appears, always anthropic | no tty on stdin/stderr, or gum missing | run from a terminal; `command -v gum` |
| Claude Code asks to log in | `.env` incomplete, wrapper never set the token | fill `.env`; the script refuses to launch without resource + key |
| `400 invalid beta flag` / `Extra inputs are not permitted` | betas reaching a non-Claude upstream | already off on the proxy path; check you didn't remove `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` |
