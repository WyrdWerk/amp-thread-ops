---
name: amp-thread-ops
description: Operate Amp (ampcode.com) threads programmatically — launch server-visible threads in any mode, steer them, read results, verify the served model, manage lifecycle (archive/snooze/delete), and clean up. Use when creating or continuing Amp threads from the CLI or scripts, when threads must appear in the Amp web UI, when switching agent modes or models, or when orchestrating external agents through Amp.
---

# Amp Thread Operations

Working procedures for launching, steering, reading, and managing Amp threads non-interactively. Verified end-to-end 2026-09-24 against amp 0.0.1790228929 on Linux.

## Mental model

- CLI: `~/.amp/bin/amp`, authenticated per user. MCP tools `amp_find_thread`, `amp_read_thread`, `amp_manage_amp`, `amp_puck` expose read/config surfaces.
- Non-interactive runs use execute mode: `-x [message]`.
- Two executors:
  - **local** (default for `-x`): thread lives ONLY on this machine (`executorType: local-client`, `createdOnServer: false`). Invisible in the web UI and **cannot be uploaded later** — `threads share` only flips a visibility flag, and multiplayer is orb-only. Treat local threads as disposable.
  - **orb** (`-ox`): async thread on Amp's server (`executorType: sandbox`), visible in the web UI at the printed URL. The command returns immediately with the URL; work continues server-side.
- **Web-UI visibility requires `-ox`** (orb executor). Tested: even with `"amp.remoteThreadCreation.enabled": true` in `~/.config/amp/settings.json`, a plain `-x` thread still comes out `executorType: local-client`, `createdOnServer: false`. That setting governs remote creation requests to a `--no-tui` runner — it does NOT create server-side thread records. Always pass `-ox` when the operator must see the thread.

## Launch a server-visible thread

```bash
amp -ox -m <mode> -x "<prompt>" --title "<title>" --no-archive-after-execute
```

- The message MUST immediately follow `-x`. A trailing positional after other flags fails with "User message must be provided".
- `-m` accepts `low|medium|high|ultra` or a plugin/custom mode key (case-insensitive).
- `--no-archive-after-execute` keeps the thread steerable; the default auto-archives after the run (verified: `"archived": true` in export after a plain `-x` run).
- Capture the thread ID (`T-...`) from the printed URL.
- The warning "No Amp project matches the Git remotes" is benign outside a git repo.

## Launching threads in different modes

`-m` selects the agent mode at creation and is **fixed for the thread's lifetime** — `--mode` is ignored by `threads continue` (the thread keeps its original mode). Two verified forms:

```bash
# Built-in thinking tier
amp -ox -m low -x "<prompt>" --title "t1" --no-archive-after-execute

# Custom/plugin mode key (case-insensitive; resolves model + system prompt + tools)
amp -ox -m zro-deepseek -x "<prompt>" --title "t2" --no-archive-after-execute
```

Mode selection methodology:

1. **Discover available mode keys** before guessing: `manage_amp` (MCP) with `topic: settings, operation: get, keys: [dial_modes]` → read `enumValues` (built-in `low|medium|high|ultra` plus every custom key, e.g. `zro-deepseek`, `deepseek-v4.1-flash`, `glm-5.3`, `gpt-6-astra-high`).
2. **Launch** with `-m <key>` as above.
3. **Verify what actually served the thread** — mode labels can mislead:
   - `amp threads export <id>` → `"model"` field (e.g. mode `zro-deepseek` served `deepseek/deepseek-v4.1-flash` via the ZRO router — the mode is the "main agent route" but the model is Flash).
   - MCP `amp_read_thread` front-matter shows `agentMode` for built-in modes.
4. **Compare modes** by running the same probe prompt in two modes and diffing the `"model"` fields of both exports.

Providers/routers behind modes: `amp config model-providers list`, then `amp config model-providers show <id>` for baseURL and modelMapping (e.g. ZRO maps `deepseek/deepseek-v4.1-flash -> zro/deepseek-v4.1-flash`).

## Steer an existing thread

```bash
amp threads continue <thread-id-or-url> -ox -x "<follow-up>"
```

- Steering preserves full conversation context (verified: turn-2 answers correctly about turn-1 details).
- `continue <id> -x` (no `-ox`) works for local threads, but prefer orb threads for operator visibility.

## Read results

| Need | Method |
|---|---|
| Full transcript (Markdown, front-matter shows `agentMode`) | MCP `amp_read_thread {thread}` |
| Last assistant message | stdout of the `-x` command itself |
| Metadata: served model, executor, visibility | `amp threads export <id>` |
| Locate a thread | MCP `amp_find_thread {query, limit}` — `amp threads list` is checkout/project-scoped and often misses orb threads; trust `find_thread` |

Orb transcripts sync with lag — a first read can be empty or stale. Poll `amp_read_thread` until the expected reply marker appears (e.g. every 8 s, ~90 s budget) instead of reading once.

## Thread lifecycle: archive, snooze, delete

```bash
amp threads archive <id>              # hide from switcher/navigation (reversible)
amp threads archive <id> --unarchive  # restore an archived thread
amp threads delete <id>               # permanent removal
```

Verified behavior (2026-09-24):

- **Archive** works on orb threads from the CLI; both directions confirmed. Full round-trip tested: archive → unarchive → re-archive.
- **Verify lifecycle state via server search, not `threads list`** (list is checkout-scoped and unreliable for orb threads):
  - `amp_find_thread {query: "archived:true"}` — archived threads appear; omit the filter and they disappear.
  - Combine with `id:<thread>` for a single-thread check: `archived:true id:T-...`.
- **Snooze is NOT programmatically settable**: no CLI command (`amp --help | grep -i snooze` → nothing) and no MCP surface (`manage_amp` has no threads topic). Snoozing is a web-UI-only action. Its **state is still queryable**: `amp_find_thread` accepts `snoozed:true|false` filters. If the operator asks to snooze, point them to the web UI.
- Archived ≠ deleted: archived threads keep their URL, transcript, and can still be read via `amp_read_thread` and restored with `--unarchive`.

## Deployment & propagation (this skill's own distribution)

Canonical home: GitHub `WyrdWerk/amp-thread-ops` (hosts `install.sh`, `AGENTS.md` runbook, `deploy/originals.json`). Three copies of SKILL.md must stay in sync: `~/.agents/skills/amp-thread-ops/` (local), the Amp Personal/User Skills repo (`amp clone user-skills`), and GitHub.

Discovery gaps (verified):

- **Amp's own agent** reads the User Skills repo. Account install: `amp skill add https://github.com/WyrdWerk/amp-thread-ops`.
- **External agents in orbs get neither User Skills nor local files** — a fresh orb has no `~/.agents/skills/`. Bootstrap by prepending a non-fatal installer to each external agent's new-thread command (see `AGENTS.md` Step 3):

  ```
  (curl -fsSL https://raw.githubusercontent.com/WyrdWerk/amp-thread-ops/main/install.sh | bash) >/dev/null 2>&1; <original command>
  ```

  Never set `--setup-script` on a built-in external agent — it replaces the agent's default install command.
- **Agents scan `~/.agents/skills/` at process start** — install before the agent launches, not mid-session. A thread whose agent is already running will only see the skill after a restart/new thread.
- **Hand-off pattern**: a user can give this repo URL to Puck in any Amp setup; Puck follows `AGENTS.md` to deploy end-to-end (Amp agent + local + all external agents) with verification and revert steps.

## Gotchas (all encountered and verified)

1. Message must immediately follow `-x`.
2. Local threads can never be pushed to the server — delete and recreate with `-ox`.
3. `threads share` is not an upload; it only sets visibility.
4. `amp threads list` presence/counts are unreliable for orb threads; use `find_thread` + `export`.
5. Orb threads are async — poll for the completion marker.
6. Mode is fixed at creation; `--mode` on `threads continue -ox` is ignored.
7. Snooze cannot be set from CLI/MCP — web UI only (state queryable via `snoozed:` filters).
8. Mode name ≠ served model — always verify via `threads export` `"model"`.
9. Orb external-agent threads may show no transcript output while booting — check the web UI terminal view for permission prompts.
10. `amp.remoteThreadCreation.enabled` does not make `-x` threads server-visible — only `-ox` does (falsified by test).

## Standard verification loop

1. Launch → capture URL/ID.
2. Poll `amp_read_thread` until the reply marker is present.
3. `amp threads export` → confirm `executorType: "sandbox"` and the expected model/mode.
4. Steer once to confirm continuity if the workflow depends on it.
5. Report the URL to the operator — they watch threads in the web UI.
6. When done with test threads: archive (reversible) or delete (permanent), then verify with `find_thread archived:true`.

## Maintenance

Three copies of this skill must stay in sync: `~/.agents/skills/amp-thread-ops/` (local), the Personal Skills repo (`amp clone user-skills`, commit, push to `main`), and GitHub `WyrdWerk/amp-thread-ops` (canonical; also carries `install.sh`, `AGENTS.md`, `deploy/originals.json`). After learning new mechanics, update all three.
