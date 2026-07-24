#!/usr/bin/env bash
# Install kstack skills into a target project (.agents/-first, with host shims).
#
# Usage:
#   ./scripts/install.sh /path/to/project
#   ./scripts/install.sh /path/to/project --ref v2.0.0
#   ./scripts/install.sh /path/to/project --symlink
#
# Reinstall prunes skills that kstack used to ship but no longer does. Project-local
# and plugin skills (not recorded in .agents/.kstack-skills / retired-skills.txt) are
# left alone.

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
      echo ""
      echo "Installs skills under .agents/skills/ (all hosts) and the kstack"
      echo "router agent for Cursor (.cursor/agents/kstack.md)."
      echo "Claude Code / Codex get skills only — no /kstack subagent; invoke"
      echo "pipeline or step skills manually (/planning-pipeline, \$review-pipeline, etc.)."
      echo ""
      echo "Reinstall removes skill directories that this installer previously wrote"
      echo "(tracked in .agents/.kstack-skills) or that appear in scripts/retired-skills.txt"
      echo "and are no longer in the current kstack skill set. Other skills are kept."
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
RETIRED_SKILLS_FILE="$REPO_ROOT/scripts/retired-skills.txt"

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
MANIFEST="$TARGET/.agents/.kstack-skills"

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

list_source_skills() {
  local skill_file
  shopt -s nullglob
  for skill_file in "$SRC_SKILLS"/*/SKILL.md; do
    basename "$(dirname "$skill_file")"
  done
  shopt -u nullglob
}

# Candidates for removal: previously installed (manifest) ∪ known retired names.
# Never touch skill dirs that are not in that set (project-local / plugin skills).
collect_prune_candidates() {
  if [[ -f "$MANIFEST" ]]; then
    grep -vE '^\s*(#|$)' "$MANIFEST" || true
  fi
  if [[ -f "$RETIRED_SKILLS_FILE" ]]; then
    grep -vE '^\s*(#|$)' "$RETIRED_SKILLS_FILE" || true
  fi
}

is_current_skill() {
  local name="$1"
  local current
  for current in $CURRENT_SKILLS; do
    if [[ "$current" == "$name" ]]; then
      return 0
    fi
  done
  return 1
}

prune_retired_skills() {
  local name dest pruned=0

  while IFS= read -r name; do
    [[ -n "$name" ]] || continue

    if is_current_skill "$name"; then
      continue
    fi

    dest="$TARGET_AGENTS_SKILLS/$name"
    # Skip missing paths and top-level symlinks (e.g. plugin skill links).
    if [[ ! -e "$dest" ]] || [[ -L "$dest" ]]; then
      continue
    fi
    if [[ ! -d "$dest" ]]; then
      continue
    fi

    rm -rf "$dest"
    echo "pruned $name (no longer shipped by kstack)"
    pruned=$((pruned + 1))
  done < <(collect_prune_candidates | sort -u)

  if [[ "$pruned" -gt 0 ]]; then
    echo "Pruned $pruned retired skill(s)."
  fi
}

write_install_manifest() {
  local name
  {
    echo "# Skills installed by kstack. Managed by scripts/install.sh — do not edit by hand."
    for name in $CURRENT_SKILLS; do
      echo "$name"
    done
  } >"$MANIFEST"
}

if [[ -n "$REF" ]]; then
  git -C "$REPO_ROOT" fetch --tags origin 2>/dev/null || true
  git -C "$REPO_ROOT" checkout "$REF"
fi

CURRENT_SKILLS="$(list_source_skills | sort)"

if [[ "$USE_SYMLINK" == true ]]; then
  link_tree "$SRC_SKILLS" "$TARGET_AGENTS_SKILLS"
  ln -sf "$SRC_AGENT" "$TARGET_AGENTS_AGENT_DIR/kstack.md"
else
  copy_tree "$SRC_SKILLS" "$TARGET_AGENTS_SKILLS"
  cp "$SRC_AGENT" "$TARGET_AGENTS_AGENT_DIR/kstack.md"
fi

prune_retired_skills
write_install_manifest

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
echo "  Skills:  .agents/skills/  (all hosts — invoke pipeline/step skills directly)"
echo "  Manifest:.agents/.kstack-skills (tracks installed skills for prune-on-reinstall)"
echo "  Agent:   .agents/agents/kstack.md → .cursor/agents/kstack.md"
echo "           (Cursor only: enables /kstack router; other hosts have no /kstack)"
echo "  Shims:   .claude/skills → .agents/skills, .cursor/skills → .agents/skills"
echo "Next: fill in context.md files (see examples/context-templates/)."
echo "      Cursor: /kstack …  |  Claude/Codex: /planning-pipeline, \$review-pipeline, etc."
