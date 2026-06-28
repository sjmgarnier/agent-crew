#!/usr/bin/env bash
set -euo pipefail

# Agent Crew — installer / uninstaller
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/sjmgarnier/agent-crew/main/install.sh | bash
#   curl -fsSL ... | bash -s -- --local       # install to .opencode/agents/ in current dir
#   curl -fsSL ... | bash -s -- --uninstall   # remove from ~/.config/opencode/agents/
#   curl -fsSL ... | bash -s -- --uninstall --local

BASE_URL="https://raw.githubusercontent.com/sjmgarnier/agent-crew/main/agents"
DEST="global"
ACTION="install"
FAILED=0

for arg in "$@"; do
  case "$arg" in
    --local)     DEST="local" ;;
    --uninstall) ACTION="uninstall" ;;
    --help|-h)
      echo "Usage: install.sh [--local] [--uninstall]"
      echo ""
      echo "  (no flags)          Install to ~/.config/opencode/agents/"
      echo "  --local             Install to .opencode/agents/ in current directory"
      echo "  --uninstall         Remove from ~/.config/opencode/agents/"
      echo "  --uninstall --local Remove from .opencode/agents/ in current directory"
      exit 0
      ;;
  esac
done

if [ "$DEST" = "local" ]; then
  TARGET=".opencode/agents"
else
  TARGET="$HOME/.config/opencode/agents"
fi

AGENTS=(surveyor architect foreman librarian adjudicator builder inspector)

if [ "$ACTION" = "uninstall" ]; then
  echo "Uninstalling Agent Crew from $TARGET"

  for agent in "${AGENTS[@]}"; do
    if [ -f "$TARGET/$agent.md" ]; then
      rm "$TARGET/$agent.md"
      echo "  ✓ $agent"
    else
      echo "  ✗ $agent (not found)"
    fi
  done

  # Remove target directory if now empty
  if [ -d "$TARGET" ] && [ -z "$(ls -A "$TARGET")" ]; then
    rmdir "$TARGET"
  fi

  echo ""
  echo "Done. Restart OpenCode to apply changes."
else
  echo "Installing Agent Crew → $TARGET"

  mkdir -p "$TARGET"

  for agent in "${AGENTS[@]}"; do
    if curl -fsSL "$BASE_URL/$agent.md" -o "$TARGET/$agent.md" 2>/dev/null; then
      echo "  ✓ $agent"
    else
      echo "  ✗ $agent (download failed)"
      FAILED=1
    fi
  done

  echo ""

  if [ "$FAILED" -eq 1 ]; then
    echo "Some agents failed to download. Check your connection and try again."
    exit 1
  fi

  echo "Done. Restart OpenCode to use the crew."
  echo "  Tab → Surveyor / Architect / Foreman"
  echo "  Task tool → Librarian / Adjudicator / Builder / Inspector"
fi
