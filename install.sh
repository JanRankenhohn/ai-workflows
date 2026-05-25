#!/usr/bin/env bash
# Install ticket-to-pr workflow into VS Code prompts folder.
# Usage: ./install.sh [--workspace <path>]
#
#   --workspace <path>   Install to <path>/.github/prompts/ instead of user prompts

set -euo pipefail

WORKFLOW_DIR="workflows/ticket-to-pr"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/$WORKFLOW_DIR"

if [ ! -d "$SOURCE" ]; then
  echo "Error: $SOURCE not found. Run this script from the repo root." >&2
  exit 1
fi

# Determine target directory
if [ "${1:-}" = "--workspace" ]; then
  if [ -z "${2:-}" ]; then
    echo "Error: --workspace requires a path argument." >&2
    exit 1
  fi
  TARGET="$2/.github/prompts"
else
  case "$(uname -s)" in
    Darwin)  TARGET="$HOME/Library/Application Support/Code/User/prompts" ;;
    Linux*)  TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/prompts" ;;
    MINGW*|MSYS*|CYGWIN*)
      TARGET="$APPDATA/Code/User/prompts" ;;
    *)
      echo "Error: Unsupported OS. Copy the files manually." >&2
      exit 1 ;;
  esac
fi

mkdir -p "$TARGET"

count=0
for file in "$SOURCE"/t2p-*; do
  name="$(basename "$file")"
  cp "$file" "$TARGET/$name"
  count=$((count + 1))
done

echo "Installed $count files to $TARGET"
echo ""
echo "Next steps:"
echo "  1. Edit $TARGET/t2p-config.yaml with your settings"
echo "  2. Run /t2p-PLAN PROJ-123 in Copilot Chat"
