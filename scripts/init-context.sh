#!/usr/bin/env bash
# Scaffold empty context.md stubs for every skill in this repo.
# Safe to re-run — skips files that already have content beyond the header.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_ROOT="$REPO_ROOT/.agents/skills"

write_stub() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local lines
    lines="$(wc -l <"$file" | tr -d ' ')"
    if [[ "$lines" -gt 4 ]]; then
      echo "skip   $file (has content)"
      return 0
    fi
  fi
  cat >"$file" <<'EOF'
# Project Context

<!-- Add project-specific constraints for this skill. -->
<!-- See examples/context-templates/ for starter examples. -->
EOF
  echo "stub   $file"
}

echo "Initializing context stubs under $SKILLS_ROOT"
echo ""

for skill_dir in "$SKILLS_ROOT"/*; do
  [[ -d "$skill_dir" ]] || continue
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  write_stub "$skill_dir/context.md"
  if [[ "$(basename "$skill_dir")" == "code-review" ]]; then
    write_stub "$skill_dir/context.checks.md"
  fi
done

echo ""
echo "Customize these first:"
echo "  - implement-plan/context.md"
echo "  - code-review/context.md + context.checks.md"
echo "  - write-plan/context.md"
echo "  - kestral-sync/context.md (if using Kestral MCP)"
