# amp-thread-ops

A skill for operating [Amp](https://ampcode.com) threads programmatically — verified end-to-end against amp 0.0.1790228929 (2026-09-24).

Covers: launching server-visible threads (orb vs local executors), steering, reading results with sync-lag-safe polling, launching in different modes (`low`/`medium`/`high`/`ultra` or custom mode keys) and verifying the served model, thread lifecycle (archive/unarchive/delete, snooze asymmetry), and cleanup.

## One-shot bootstrap via Puck (or any assistant)

Open Puck in any Amp setup and say:

> Set up the skill at https://github.com/WyrdWerk/amp-thread-ops end-to-end for all my agents — follow its AGENTS.md runbook.

Puck (or Amp, Pi, Claude Code…) follows [`AGENTS.md`](AGENTS.md): installs for Amp's own agent (`amp skill add`), for the local machine (`install.sh` → `~/.agents/skills/`), and bootstraps every external agent's orb threads (non-fatal install prefix on each new-thread command). All steps idempotent and reversible.

## Manual install

Amp's agent:

```bash
amp skill add https://github.com/WyrdWerk/amp-thread-ops
```

Any Agent Skills-spec agent (pi, Claude Code, etc.):

```bash
curl -fsSL https://raw.githubusercontent.com/WyrdWerk/amp-thread-ops/main/install.sh | bash
```

The skill itself lives in [`amp-thread-ops/SKILL.md`](amp-thread-ops/SKILL.md).

## Why the orb bootstrap exists

Orb threads run in fresh server sandboxes: they receive neither Amp User Skills nor local files. External agents (pi, claude-code, …) scan `~/.agents/skills/` at process start. The new-thread-command prefix installs the skill into the orb before the agent launches. See [`AGENTS.md`](AGENTS.md) for the full procedure and revert steps.

## Key gotchas encoded

- The `-x` message must immediately follow the flag.
- Local (`-x`) threads are invisible in the web UI and can never be uploaded — use `-ox`.
- `threads share` is not an upload; `amp.remoteThreadCreation.enabled` does not create server records (falsified by test).
- Orb threads are async — poll for the reply marker; transcripts sync with lag.
- Mode name ≠ served model — verify via `amp threads export`.
- Snooze is detect-only from CLI/MCP (web-UI-only action).
