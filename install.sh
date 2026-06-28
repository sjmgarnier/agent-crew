#!/usr/bin/env bash
set -euo pipefail

# Agent Crew — installer / uninstaller
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/sjmgarnier/agent-crew/main/install.sh | bash
#   curl -fsSL ... | bash -s -- --local         # install to .opencode/agents/ in current dir
#   curl -fsSL ... | bash -s -- --uninstall     # remove from ~/.config/opencode/agents/
#   curl -fsSL ... | bash -s -- --uninstall --local
#   curl -fsSL ... | bash -s -- --force         # overwrite existing agent files

BASE_URL="https://raw.githubusercontent.com/sjmgarnier/agent-crew/main/agents"
DEST="global"
ACTION="install"
FORCE=0
FAILED=0
SKIPPED=0

for arg in "$@"; do
  case "$arg" in
    --local)     DEST="local" ;;
    --uninstall) ACTION="uninstall" ;;
    --force)     FORCE=1 ;;
    --help|-h)
      echo "Usage: install.sh [--local] [--uninstall] [--force]"
      echo ""
      echo "  (no flags)          Install to ~/.config/opencode/agents/"
      echo "  --local             Install to .opencode/agents/ in current directory"
      echo "  --uninstall         Remove from ~/.config/opencode/agents/"
      echo "  --uninstall --local Remove from .opencode/agents/ in current directory"
      echo "  --force             Overwrite existing agent files"
      exit 0
      ;;
  esac
done

if [ "$DEST" = "local" ]; then
  TARGET=".opencode/agents"
else
  TARGET="$HOME/.config/opencode/agents"
fi

MANIFEST="$TARGET/.agent-crew"
AGENTS=(surveyor architect foreman librarian groundskeeper examiner builder inspector)

if [ "$ACTION" = "uninstall" ]; then
  echo "Uninstalling Agent Crew from $TARGET"

  if [ ! -f "$MANIFEST" ]; then
    echo "  ✗ No Agent Crew manifest found at $TARGET."
    echo "    If you installed manually, remove the agent files yourself."
    exit 1
  fi

  while IFS= read -r agent; do
    if [ -f "$TARGET/$agent.md" ]; then
      rm "$TARGET/$agent.md"
      echo "  ✓ $agent"
    else
      echo "  ✗ $agent (not found)"
    fi
  done < "$MANIFEST"

  rm "$MANIFEST"

  # Remove target directory if now empty
  if [ -d "$TARGET" ] && [ -z "$(ls -A "$TARGET")" ]; then
    rmdir "$TARGET"
  fi

  echo ""
  echo "Done. Restart OpenCode to apply changes."
else
  echo "Installing Agent Crew → $TARGET"

  if ! mkdir -p "$TARGET"; then
    echo "  ✗ Could not create $TARGET — check permissions."
    exit 1
  fi

  INSTALLED=()

  for agent in "${AGENTS[@]}"; do
    if [ -f "$TARGET/$agent.md" ] && [ "$FORCE" -eq 0 ]; then
      echo "  ⚠ $agent (already exists — use --force to overwrite)"
      SKIPPED=1
      continue
    fi
    if curl -fsSL "$BASE_URL/$agent.md" -o "$TARGET/$agent.md" 2>/dev/null; then
      echo "  ✓ $agent"
      INSTALLED+=("$agent")
    else
      echo "  ✗ $agent (download failed)"
      FAILED=1
    fi
  done

  # Write manifest of agents installed in this run
  if [ ${#INSTALLED[@]} -gt 0 ]; then
    printf '%s\n' "${INSTALLED[@]}" > "$MANIFEST"
  fi

  echo ""

  if [ "$FAILED" -eq 1 ]; then
    echo "Some agents failed to download. Check your connection and try again."
    exit 1
  fi

  if [ "$SKIPPED" -eq 1 ]; then
    echo "Some agents were skipped (already exist). Run with --force to overwrite."
    echo ""
  fi

  echo "Done. Restart OpenCode to use the crew."
  echo "  Tab → Surveyor / Architect / Foreman"
  echo "  Task tool → Librarian / Adjudicator / Builder / Inspector"
fi
