# amp-thread-ops

A skill for operating [Amp](https://ampcode.com) threads programmatically — verified end-to-end against amp 0.0.1790228929 (2026-09-24).

Covers: launching server-visible threads (orb vs local executors), steering, reading results with sync-lag-safe polling, launching in different modes (`low`/`medium`/`high`/`ultra` or custom mode keys) and verifying the served model, thread lifecycle (archive/unarchive/delete, snooze asymmetry), and cleanup.

## Install

Amp:

```bash
amp skill add https://github.com/WyrdWerk/amp-thread-ops
```

Any Agent Skills-spec agent (pi, Claude Code, etc.):

```bash
git clone https://github.com/WyrdWerk/amp-thread-ops ~/.agents/skills/amp-thread-ops-src
cp -r ~/.agents/skills/amp-thread-ops-src/amp-thread-ops ~/.agents/skills/
```

The skill itself lives in [`amp-thread-ops/SKILL.md`](amp-thread-ops/SKILL.md).

## Key gotchas encoded

- The `-x` message must immediately follow the flag.
- Local (`-x`) threads are invisible in the web UI and can never be uploaded — use `-ox`.
- `threads share` is not an upload; `amp.remoteThreadCreation.enabled` does not create server records (falsified by test).
- Orb threads are async — poll for the reply marker; transcripts sync with lag.
- Mode name ≠ served model — verify via `amp threads export`.
- Snooze is detect-only from CLI/MCP (web-UI-only action).
