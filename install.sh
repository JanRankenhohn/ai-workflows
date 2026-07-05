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

# Parse arguments
FORCE=false
TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --workspace)
      if [ -z "${2:-}" ]; then
        echo "Error: --workspace requires a path argument." >&2
        exit 1
      fi
      TARGET="$2/.github/prompts"
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [ -z "$TARGET" ]; then
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

# --- Interactive config setup ---
CONFIG_DEST="$TARGET/t2p-config.yaml"
NEEDS_SETUP=false
if [ ! -f "$CONFIG_DEST" ] || [ "$FORCE" = true ]; then
  NEEDS_SETUP=true
fi

# Defaults
JIRA_ENABLED=false
JIRA_NAME="jira"
ADO_ENABLED=false
ADO_NAME="ado"

if [ "$NEEDS_SETUP" = true ]; then
  echo ""
  echo "=== t2p Workflow Setup ==="
  echo ""
  echo "Which MCP servers do you have configured?"
  echo ""

  # Jira
  echo "  Enable Jira MCP? Used by /t2p-EXPLORE, /t2p-PLAN, /t2p-REVIEW, /t2p-CREATE-PR."
  echo "  If disabled, the agent will ask you for ticket details instead."
  printf "  Enable? (y/N): "
  read -r jira_choice
  if [[ "$jira_choice" =~ ^[Yy] ]]; then
    JIRA_ENABLED=true
    read -e -i "$JIRA_NAME" -p "  Jira MCP server name (from your mcp.json): " jira_name
    if [ -n "$jira_name" ]; then JIRA_NAME="$jira_name"; fi
  fi

  echo ""

  # Azure DevOps
  echo "  Enable Azure DevOps MCP? Used by /t2p-CREATE-PR."
  echo "  If disabled, you create the PR manually."
  printf "  Enable? (y/N): "
  read -r ado_choice
  if [[ "$ado_choice" =~ ^[Yy] ]]; then
    ADO_ENABLED=true
    read -e -i "$ADO_NAME" -p "  Azure DevOps MCP server name (from your mcp.json): " ado_name
    if [ -n "$ado_name" ]; then ADO_NAME="$ado_name"; fi
  fi

  echo ""
  echo "Configuration:"
  if [ "$JIRA_ENABLED" = true ]; then
    echo "  Jira:         enabled (server: $JIRA_NAME)"
  else
    echo "  Jira:         disabled"
  fi
  if [ "$ADO_ENABLED" = true ]; then
    echo "  Azure DevOps: enabled (server: $ADO_NAME)"
  else
    echo "  Azure DevOps: disabled"
  fi
  echo ""
else
  # Read existing config for MCP names
  if grep -q 'jira:' "$CONFIG_DEST"; then
    JIRA_ENABLED=$(sed -n '/^\s*jira:/,/^\s*[a-z]/{ s/.*enabled:\s*\(true\|false\).*/\1/p; }' "$CONFIG_DEST" | head -1)
    jira_name_match=$(sed -n '/^\s*jira:/,/^\s*[a-z]/{ s/.*name:\s*"\([^"]*\)".*/\1/p; }' "$CONFIG_DEST" | head -1)
    if [ -n "$jira_name_match" ]; then JIRA_NAME="$jira_name_match"; fi
  fi
  if grep -q 'azure_devops:' "$CONFIG_DEST"; then
    ADO_ENABLED=$(sed -n '/^\s*azure_devops:/,/^\s*[a-z]/{ s/.*enabled:\s*\(true\|false\).*/\1/p; }' "$CONFIG_DEST" | head -1)
    ado_name_match=$(sed -n '/^\s*azure_devops:/,/^\s*[a-z]/{ s/.*name:\s*"\([^"]*\)".*/\1/p; }' "$CONFIG_DEST" | head -1)
    if [ -n "$ado_name_match" ]; then ADO_NAME="$ado_name_match"; fi
  fi
fi

# --- Copy and transform files ---
installed=0
skipped=0

for file in "$SOURCE"/t2p-*; do
  name="$(basename "$file")"
  dest="$TARGET/$name"

  if [ "$name" = "t2p-config.yaml" ]; then
    if [ "$NEEDS_SETUP" = true ]; then
      content="$(cat "$file")"
      # Substitute enabled/name values
      content="$(echo "$content" | sed "s/\(jira:\s*\n\s*enabled:\s*\)false/\1$JIRA_ENABLED/")"
      content="$(echo "$content" | sed "s/\(name: \)\"jira\"/\1\"$JIRA_NAME\"/" )"
      content="$(echo "$content" | sed "s/\(azure_devops:\s*\n\s*enabled:\s*\)false/\1$ADO_ENABLED/")"
      content="$(echo "$content" | sed "s/\(name: \)\"ado\"/\1\"$ADO_NAME\"/")"
      printf '%s' "$content" > "$dest"
      installed=$((installed + 1))
    else
      skipped=$((skipped + 1))
      echo "  Skipped $name (already exists — preserving your settings)"
    fi
  else
    content="$(cat "$file")"

    if [ "$JIRA_ENABLED" = true ]; then
      content="$(echo "$content" | sed "s/__JIRA_MCP__/$JIRA_NAME/g")"
    else
      # Remove disabled MCP tool entries
      content="$(echo "$content" | sed 's/"__JIRA_MCP__\/\*",\?[[:space:]]*//g')"
      content="$(echo "$content" | sed 's/"__JIRA_MCP__",\?[[:space:]]*//g')"
    fi

    if [ "$ADO_ENABLED" = true ]; then
      content="$(echo "$content" | sed "s/__ADO_MCP__/$ADO_NAME/g")"
    else
      content="$(echo "$content" | sed 's/"__ADO_MCP__\/\*",\?[[:space:]]*//g')"
      content="$(echo "$content" | sed 's/"__ADO_MCP__",\?[[:space:]]*//g')"
    fi

    # Clean trailing commas in arrays
    content="$(echo "$content" | sed 's/,[[:space:]]*\]/]/g')"

    printf '%s' "$content" > "$dest"
    installed=$((installed + 1))
  fi
done

echo ""
echo "Installed $installed files to $TARGET"
if [ "$skipped" -gt 0 ]; then
  echo "Skipped $skipped config file(s) (use --force to overwrite)"
fi
echo ""
echo "Run /t2p-PLAN PROJ-123 in Copilot Chat to get started."
fi
