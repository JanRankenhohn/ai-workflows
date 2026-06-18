#!/usr/bin/env bash
# Install ticket-to-pr workflow into VS Code prompts folder.
# Usage: ./install.sh [--workspace <path>] [--force]
#
#   --workspace <path>   Install to <path>/.github/prompts/ instead of user prompts
#   --force              Overwrite config file even if it already exists

set -euo pipefail

WORKFLOW_DIR="workflows/ticket-to-pr"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/$WORKFLOW_DIR"

if [ ! -d "$SOURCE" ]; then
  echo "Error: $SOURCE not found. Run this script from the repo root." >&2
  exit 1
fi

# Determine target directory
FORCE=false
POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --workspace)
      if [ -z "${2:-}" ]; then
        echo "Error: --workspace requires a path argument." >&2
        exit 1
      fi
      POSITIONAL+=("$1" "$2")
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if [[ " ${POSITIONAL[*]:-} " == *" --workspace "* ]]; then
  for i in "${!POSITIONAL[@]}"; do
    if [ "${POSITIONAL[$i]}" = "--workspace" ]; then
      TARGET="${POSITIONAL[$((i+1))]}/.github/prompts"
      break
    fi
  done
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

installed=0
skipped=0
for file in "$SOURCE"/t2p-*; do
  name="$(basename "$file")"
  dest="$TARGET/$name"
  if [ "$name" = "t2p-config.yaml" ] && [ -f "$dest" ] && [ "$FORCE" = false ]; then
    skipped=$((skipped + 1))
    echo "  Skipped $name (already exists — preserving your settings)"
  else
    cp "$file" "$dest"
    installed=$((installed + 1))
  fi
done

echo ""
echo "Installed $installed files to $TARGET"
if [ "$skipped" -gt 0 ]; then
  echo "Skipped $skipped config file(s) (use --force to overwrite)"
fi
if [ ! -f "$TARGET/t2p-config.yaml" ]; then
  echo ""
  echo "Next steps:"
  echo "  1. Edit $TARGET/t2p-config.yaml with your settings"
  echo "  2. Run /t2p-PLAN PROJ-123 in Copilot Chat"
else
  echo ""
  echo "Run /t2p-PLAN PROJ-123 in Copilot Chat to get started."
fi
