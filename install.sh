#!/usr/bin/env bash
# Installs the amp-thread-ops skill into ~/.agents/skills/ (Agent Skills spec location).
# Idempotent, dependency-light (git preferred, curl fallback), safe in orbs and local runs.
set -euo pipefail

REPO="https://github.com/WyrdWerk/amp-thread-ops"
DEST="${HOME}/.agents/skills/amp-thread-ops"

mkdir -p "${HOME}/.agents/skills"

if command -v git >/dev/null 2>&1; then
  rm -rf "$DEST"
  git clone --depth 1 --quiet "$REPO" "$DEST"
  rm -rf "$DEST/.git"
else
  rm -rf "$DEST"
  mkdir -p "$DEST"
  curl -fsSL "$REPO/raw/main/amp-thread-ops/SKILL.md" -o "$DEST/SKILL.md"
fi

if [ -f "$DEST/SKILL.md" ]; then
  echo "amp-thread-ops installed: $DEST"
else
  echo "amp-thread-ops install FAILED" >&2
  exit 1
fi
