# AGENTS.md — amp-thread-ops deployment runbook

Goal: make the `amp-thread-ops` skill discoverable by every agent in an Amp setup — Amp's own agent and all external agents (Pi, Claude Code, Codex, OpenCode, Cursor CLI, Grok CLI, Antigravity) — in orb threads and local runs.

Any assistant (Puck, Amp, Pi, Claude Code…) given this repository can perform the steps below. All steps are idempotent and reversible.

## Step 0 — Preflight

```bash
amp --version                      # Amp CLI present and authenticated
amp config external-agents list    # note the agent keys
```

## Step 1 — Install for Amp's own agent

```bash
amp skill add https://github.com/WyrdWerk/amp-thread-ops
amp skill list | grep amp-thread-ops   # verify
```

## Step 2 — Install for the current machine (all Agent Skills-spec agents)

```bash
curl -fsSL https://raw.githubusercontent.com/WyrdWerk/amp-thread-ops/main/install.sh | bash
ls ~/.agents/skills/amp-thread-ops/SKILL.md   # verify
```

Agents scan `~/.agents/skills/` at process start — install before launching the agent, not mid-session.

## Step 3 — Bootstrap external-agent orb threads

Orbs are fresh sandboxes: they receive neither Amp User Skills nor local files. For each external-agent key from Step 0:

1. Read the current new-thread command:

   ```bash
   amp config external-agents show <key>
   ```

2. If the command already contains `amp-thread-ops/main/install.sh`, skip (idempotent).
3. Prepend — never replace — this non-fatal bootstrap:

   ```
   (curl -fsSL https://raw.githubusercontent.com/WyrdWerk/amp-thread-ops/main/install.sh | bash) >/dev/null 2>&1; 
   ```

4. Apply:

   ```bash
   amp config external-agents update <key> --new-thread-command '<full new command>'
   ```

Rules:

- Preserve the original command byte-for-byte after the prefix.
- The prefix is non-fatal (`>/dev/null 2>&1` + `;` separator): a network failure must never block the agent from starting.
- NEVER set `--setup-script` on a built-in agent — it replaces the agent's default install command.
- Resume commands need no change: resumes run in the same orb, where the skill is already installed.

## Step 4 — Verify end-to-end

1. `amp skill list | grep amp-thread-ops`
2. Launch a test orb thread in an external-agent mode; ask the agent to confirm it can read `~/.agents/skills/amp-thread-ops/SKILL.md`.

## Revert

- `amp config external-agents reset <key>` restores defaults — but also clears pre-existing customizations; recover exact pre-deploy commands from `deploy/originals.json`.
- `amp skill remove amp-thread-ops`
- `rm -rf ~/.agents/skills/amp-thread-ops`
