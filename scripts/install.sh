#!/usr/bin/env bash
# Install kstack skills into a target project.
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
TARGET_CURSOR="$TARGET/.cursor"
mkdir -p "$TARGET_CURSOR/skills" "$TARGET_CURSOR/agents"

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
  link_tree "$REPO_ROOT/.cursor/skills" "$TARGET_CURSOR/skills"
  ln -sf "$REPO_ROOT/.cursor/agents/kstack.md" "$TARGET_CURSOR/agents/kstack.md"
else
  copy_tree "$REPO_ROOT/.cursor/skills" "$TARGET_CURSOR/skills"
  cp "$REPO_ROOT/.cursor/agents/kstack.md" "$TARGET_CURSOR/agents/kstack.md"
fi

echo "Installed kstack into $TARGET/.cursor/"
echo "Next: fill in context.md files (see examples/context-templates/)."
