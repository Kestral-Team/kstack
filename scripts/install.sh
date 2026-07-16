#!/usr/bin/env bash
# Install kstack skills into a target project (.agents/-first, with host shims).
#
# Usage:
#   ./scripts/install.sh /path/to/project
#   ./scripts/install.sh /path/to/project --ref v2.0.0
#   ./scripts/install.sh /path/to/project --symlink

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
REF=""
USE_SYMLINK=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)
      REF="$2"
      shift 2
      ;;
    --symlink)
      USE_SYMLINK=true
      shift
      ;;
    -h | --help)
      echo "Usage: $0 <target-project> [--ref <tag>] [--symlink]"
      exit 0
      ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"
      else
        echo "Unknown argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "ERROR: target project path required" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"
SRC_SKILLS="$REPO_ROOT/.agents/skills"
SRC_AGENT="$REPO_ROOT/.agents/agents/kstack.md"

if [[ ! -d "$SRC_SKILLS" ]]; then
  echo "ERROR: skills not found at $SRC_SKILLS" >&2
  exit 1
fi
if [[ ! -f "$SRC_AGENT" ]]; then
  echo "ERROR: kstack agent not found at $SRC_AGENT" >&2
  exit 1
fi

TARGET_AGENTS_SKILLS="$TARGET/.agents/skills"
TARGET_AGENTS_AGENT_DIR="$TARGET/.agents/agents"
TARGET_CURSOR_AGENTS="$TARGET/.cursor/agents"
TARGET_CLAUDE_SKILLS="$TARGET/.claude/skills"

mkdir -p "$TARGET_AGENTS_SKILLS" "$TARGET_AGENTS_AGENT_DIR" "$TARGET_CURSOR_AGENTS"

copy_tree() {
  local src="$1"
  local dest="$2"
  mkdir -p "$dest"
  for item in "$src"/*; do
    local name
    name="$(basename "$item")"
    if [[ -L "$item" ]]; then
      continue
    fi
    if [[ -d "$item" ]]; then
      copy_tree "$item" "$dest/$name"
    elif [[ -f "$item" ]]; then
      if [[ "$name" == context.md ]] || [[ "$name" == context.*.md ]]; then
        if [[ -f "$dest/$name" ]]; then
          continue
        fi
      fi
      cp "$item" "$dest/$name"
    fi
  done
}

link_tree() {
  local src="$1"
  local dest="$2"
  mkdir -p "$dest"
  for item in "$src"/*; do
    local name
    name="$(basename "$item")"
    if [[ -L "$item" ]]; then
      continue
    fi
    if [[ -d "$item" ]]; then
      link_tree "$item" "$dest/$name"
    elif [[ -f "$item" ]]; then
      if [[ "$name" == context.md ]] || [[ "$name" == context.*.md ]]; then
        if [[ -f "$dest/$name" ]]; then
          continue
        fi
      fi
      ln -sf "$item" "$dest/$name"
    fi
  done
}

if [[ -n "$REF" ]]; then
  git -C "$REPO_ROOT" fetch --tags origin 2>/dev/null || true
  git -C "$REPO_ROOT" checkout "$REF"
fi

if [[ "$USE_SYMLINK" == true ]]; then
  link_tree "$SRC_SKILLS" "$TARGET_AGENTS_SKILLS"
  ln -sf "$SRC_AGENT" "$TARGET_AGENTS_AGENT_DIR/kstack.md"
else
  copy_tree "$SRC_SKILLS" "$TARGET_AGENTS_SKILLS"
  cp "$SRC_AGENT" "$TARGET_AGENTS_AGENT_DIR/kstack.md"
fi

# Cursor discovers subagents under .cursor/agents/; skills under .agents/skills.
cp "$TARGET_AGENTS_AGENT_DIR/kstack.md" "$TARGET_CURSOR_AGENTS/kstack.md"

# Claude Code: discover skills via .claude/skills → .agents/skills
mkdir -p "$TARGET/.claude"
if [[ -e "$TARGET_CLAUDE_SKILLS" && ! -L "$TARGET_CLAUDE_SKILLS" ]]; then
  echo "NOTE: $TARGET_CLAUDE_SKILLS already exists and is not a symlink — left unchanged."
else
  ln -sfn "../.agents/skills" "$TARGET_CLAUDE_SKILLS"
fi

# Optional Cursor skills shim for hosts that only look under .cursor/skills
TARGET_CURSOR_SKILLS="$TARGET/.cursor/skills"
if [[ -e "$TARGET_CURSOR_SKILLS" && ! -L "$TARGET_CURSOR_SKILLS" ]]; then
  echo "NOTE: $TARGET_CURSOR_SKILLS already exists and is not a symlink — left unchanged."
else
  mkdir -p "$TARGET/.cursor"
  ln -sfn "../.agents/skills" "$TARGET_CURSOR_SKILLS"
fi

if [[ -f "$TARGET/.gitignore" ]] && ! grep -q '^\.kstack/$' "$TARGET/.gitignore" 2>/dev/null; then
  printf '\n# kstack clone directory (optional)\n.kstack/\n' >>"$TARGET/.gitignore"
fi

echo "Installed kstack into $TARGET/.agents/"
echo "  Skills:  .agents/skills/"
echo "  Agent:   .agents/agents/kstack.md (+ .cursor/agents/kstack.md for Cursor)"
echo "  Shims:   .claude/skills → .agents/skills, .cursor/skills → .agents/skills"
echo "Next: fill in context.md files (see examples/context-templates/)."
