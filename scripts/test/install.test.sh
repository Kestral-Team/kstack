#!/usr/bin/env bash
# Tests for scripts/install.sh safe-reinstall behavior.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    echo "        expected: $expected"
    echo "        actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_file() {
  local desc="$1" path="$2"
  if [[ -f "$path" ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc (missing $path)"
    FAIL=$((FAIL + 1))
  fi
}

assert_missing() {
  local desc="$1" path="$2"
  if [[ ! -e "$path" ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc (still exists: $path)"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local desc="$1" path="$2" needle="$3"
  if [[ -f "$path" ]] && grep -qF "$needle" "$path"; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc (no '$needle' in $path)"
    FAIL=$((FAIL + 1))
  fi
}

file_hash() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# Minimal upstream fixture derived from real kstack (copy, then trim for rename tests).
setup_src() {
  local src="$1"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude .git "$ROOT/" "$src/"
  else
    # CI / minimal environments without rsync
    cp -R "$ROOT/." "$src/"
    rm -rf "$src/.git"
  fi
}

echo "=== install.test.sh ==="

# ---------------------------------------------------------------------------
# 1. Fresh install writes manifests and preserves nothing yet
# ---------------------------------------------------------------------------
echo "-- fresh install"
SRC="$(mktemp -d "${TMPDIR:-/tmp}/kstack-src.XXXXXX")"
T="$(mktemp -d "${TMPDIR:-/tmp}/kstack-proj.XXXXXX")"
setup_src "$SRC"
"$SRC/scripts/install.sh" "$T" >/dev/null
assert_file "skills manifest" "$T/.agents/.kstack-skills"
assert_file "files checksum manifest" "$T/.agents/.kstack-files"
assert_file "code-review SKILL" "$T/.agents/skills/code-review/SKILL.md"
assert_file "context stub" "$T/.agents/skills/code-review/context.md"
assert_contains "gitignore sidecar patterns" "$T/.gitignore" "*.kstack-new"
assert_contains "gitignore merge report" "$T/.gitignore" ".agents/.kstack-merge.md"
assert_missing "no merge report on clean install" "$T/.agents/.kstack-merge.md"

# ---------------------------------------------------------------------------
# 2. context.md never overwritten
# ---------------------------------------------------------------------------
echo "-- context.md preserved on reinstall"
echo "MY OVERLAY LINE" >>"$T/.agents/skills/code-review/context.md"
"$SRC/scripts/install.sh" "$T" --keep >/dev/null
assert_contains "context overlay survives" "$T/.agents/skills/code-review/context.md" "MY OVERLAY LINE"

# ---------------------------------------------------------------------------
# 3. unmodified SKILL.md upgrades silently
# ---------------------------------------------------------------------------
echo "-- unmodified skill body upgrades"
echo "UPSTREAM V2" >>"$SRC/.agents/skills/code-review/SKILL.md"
BEFORE_HASH="$(file_hash "$T/.agents/skills/code-review/SKILL.md")"
"$SRC/scripts/install.sh" "$T" --keep >/dev/null
AFTER_HASH="$(file_hash "$T/.agents/skills/code-review/SKILL.md")"
SRC_HASH="$(file_hash "$SRC/.agents/skills/code-review/SKILL.md")"
assert_eq "unmodified file took upstream" "$SRC_HASH" "$AFTER_HASH"
if [[ "$BEFORE_HASH" != "$AFTER_HASH" ]]; then
  echo "  PASS: hash changed after upstream bump"
  PASS=$((PASS + 1))
else
  echo "  FAIL: hash did not change after upstream bump"
  FAIL=$((FAIL + 1))
fi
assert_missing "no sidecar when unmodified" "$T/.agents/skills/code-review/SKILL.md.kstack-new"

# ---------------------------------------------------------------------------
# 4. local edit + --keep writes sidecar + merge report
# ---------------------------------------------------------------------------
echo "-- local edit keep + sidecar"
echo "LOCAL EDIT" >>"$T/.agents/skills/code-review/SKILL.md"
echo "UPSTREAM V3" >>"$SRC/.agents/skills/code-review/SKILL.md"
"$SRC/scripts/install.sh" "$T" --keep >/dev/null
assert_contains "kept local edit" "$T/.agents/skills/code-review/SKILL.md" "LOCAL EDIT"
assert_file "sidecar written" "$T/.agents/skills/code-review/SKILL.md.kstack-new"
assert_contains "sidecar has upstream" "$T/.agents/skills/code-review/SKILL.md.kstack-new" "UPSTREAM V3"
assert_file "merge report" "$T/.agents/.kstack-merge.md"
assert_contains "merge report mentions file" "$T/.agents/.kstack-merge.md" "code-review/SKILL.md"

# ---------------------------------------------------------------------------
# 4b. kept edit must not be silently overwritten on next reinstall
# ---------------------------------------------------------------------------
echo "-- kept edit survives second reinstall"
"$SRC/scripts/install.sh" "$T" --keep >/dev/null
assert_contains "second reinstall still keeps local" "$T/.agents/skills/code-review/SKILL.md" "LOCAL EDIT"
assert_file "sidecar still present or refreshed" "$T/.agents/skills/code-review/SKILL.md.kstack-new"

# ---------------------------------------------------------------------------
# 5. --overwrite takes upstream
# ---------------------------------------------------------------------------
echo "-- overwrite mode"
echo "ANOTHER LOCAL" >>"$T/.agents/skills/write-plan/SKILL.md"
echo "UPSTREAM WRITEPLAN" >>"$SRC/.agents/skills/write-plan/SKILL.md"
"$SRC/scripts/install.sh" "$T" --overwrite >/dev/null
assert_contains "overwrite took upstream" "$T/.agents/skills/write-plan/SKILL.md" "UPSTREAM WRITEPLAN"
if grep -q "ANOTHER LOCAL" "$T/.agents/skills/write-plan/SKILL.md"; then
  echo "  FAIL: local edit still present after --overwrite"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: local edit removed by --overwrite"
  PASS=$((PASS + 1))
fi

# ---------------------------------------------------------------------------
# 6. prune archives authored context
# ---------------------------------------------------------------------------
echo "-- prune archives authored overlay"
mkdir -p "$T/.agents/skills/debugging"
cat >"$T/.agents/skills/debugging/SKILL.md" <<'EOF'
---
name: debugging
description: retired fixture
---
# Debugging
EOF
cat >"$T/.agents/skills/debugging/context.md" <<'EOF'
# Project Context

Authored overlay for retired skill that must be archived.
Extra line to exceed stub length.
And another so wc -l is greater than 4.
EOF
# Ensure debugging is in skills manifest so prune considers it
if ! grep -qx 'debugging' "$T/.agents/.kstack-skills"; then
  echo "debugging" >>"$T/.agents/.kstack-skills"
fi
"$SRC/scripts/install.sh" "$T" --keep >/dev/null
assert_missing "debugging skill pruned" "$T/.agents/skills/debugging"
assert_file "overlay archived" "$T/.agents/.kstack-archive/debugging/context.md"
assert_contains "archive content" "$T/.agents/.kstack-archive/debugging/context.md" "Authored overlay"

# ---------------------------------------------------------------------------
# 7. rename migrates context
# ---------------------------------------------------------------------------
echo "-- rename migrates context"
# Reset a clean project for rename
T2="$(mktemp -d "${TMPDIR:-/tmp}/kstack-proj.XXXXXX")"
SRC2="$(mktemp -d "${TMPDIR:-/tmp}/kstack-src.XXXXXX")"
setup_src "$SRC2"
"$SRC2/scripts/install.sh" "$T2" >/dev/null
cat >>"$T2/.agents/skills/write-plan/context.md" <<'EOF'
Plans live in docs/plans/bernard/.
EOF
# Rename write-plan -> author-plan in upstream
mv "$SRC2/.agents/skills/write-plan" "$SRC2/.agents/skills/author-plan"
# Fix frontmatter name for lint niceness (not required by install)
sed -i.bak 's/^name: write-plan/name: author-plan/' "$SRC2/.agents/skills/author-plan/SKILL.md" 2>/dev/null || \
  sed -i '' 's/^name: write-plan/name: author-plan/' "$SRC2/.agents/skills/author-plan/SKILL.md"
echo "write-plan	author-plan" >>"$SRC2/scripts/renamed-skills.txt"
# Ensure write-plan is prune candidate via manifest (already listed)
"$SRC2/scripts/install.sh" "$T2" --keep >/dev/null
assert_file "new skill present" "$T2/.agents/skills/author-plan/SKILL.md"
assert_contains "migrated overlay" "$T2/.agents/skills/author-plan/context.md" "docs/plans/bernard"
assert_missing "old skill pruned" "$T2/.agents/skills/write-plan"

# ---------------------------------------------------------------------------
# 8. legacy (no checksum manifest) + --keep
# ---------------------------------------------------------------------------
echo "-- legacy keep"
T3="$(mktemp -d "${TMPDIR:-/tmp}/kstack-proj.XXXXXX")"
SRC3="$(mktemp -d "${TMPDIR:-/tmp}/kstack-src.XXXXXX")"
setup_src "$SRC3"
"$SRC3/scripts/install.sh" "$T3" >/dev/null
rm -f "$T3/.agents/.kstack-files"
echo "LEGACY LOCAL" >>"$T3/.agents/skills/code-review/SKILL.md"
echo "LEGACY UPSTREAM" >>"$SRC3/.agents/skills/code-review/SKILL.md"
"$SRC3/scripts/install.sh" "$T3" --keep >/dev/null
assert_contains "legacy kept local" "$T3/.agents/skills/code-review/SKILL.md" "LEGACY LOCAL"
assert_file "legacy sidecar" "$T3/.agents/skills/code-review/SKILL.md.kstack-new"
assert_file "files manifest recreated" "$T3/.agents/.kstack-files"

# ---------------------------------------------------------------------------
# 9. project-local skill left alone
# ---------------------------------------------------------------------------
echo "-- project-local skill preserved"
mkdir -p "$T3/.agents/skills/my-own-skill"
echo "# Mine" >"$T3/.agents/skills/my-own-skill/SKILL.md"
"$SRC3/scripts/install.sh" "$T3" --keep >/dev/null
assert_file "local skill survives" "$T3/.agents/skills/my-own-skill/SKILL.md"

# ---------------------------------------------------------------------------
# 10. cursor agent local edit is kept
# ---------------------------------------------------------------------------
echo "-- cursor agent conflict keep"
echo "CURSOR LOCAL EDIT" >>"$T3/.cursor/agents/kstack.md"
echo "AGENT UPSTREAM EDIT" >>"$SRC3/.agents/agents/kstack.md"
"$SRC3/scripts/install.sh" "$T3" --keep >/dev/null
assert_contains "cursor agent kept" "$T3/.cursor/agents/kstack.md" "CURSOR LOCAL EDIT"
assert_file "cursor agent sidecar" "$T3/.cursor/agents/kstack.md.kstack-new"

# ---------------------------------------------------------------------------
# 11. unsafe skill names are not pruned/removed
# ---------------------------------------------------------------------------
echo "-- path traversal name ignored on prune"
mkdir -p "$T3/.agents/skills"
# Plant a poison manifest entry; installer must not treat it as a skill dir to rm.
printf '%s\n' '# test' '../poison' >>"$T3/.agents/.kstack-skills"
"$SRC3/scripts/install.sh" "$T3" --keep >/dev/null
# If traversal were honored, files outside skills could be affected; we only assert
# the installer still completes and my-own-skill remains.
assert_file "local skill still present after poison manifest line" "$T3/.agents/skills/my-own-skill/SKILL.md"

# ---------------------------------------------------------------------------
# 12. uninstall
# ---------------------------------------------------------------------------
echo "-- uninstall"
T4="$(mktemp -d "${TMPDIR:-/tmp}/kstack-proj.XXXXXX")"
SRC4="$(mktemp -d "${TMPDIR:-/tmp}/kstack-src.XXXXXX")"
setup_src "$SRC4"
"$SRC4/scripts/install.sh" "$T4" >/dev/null
echo "KEEP ME ON UNINSTALL" >>"$T4/.agents/skills/code-review/context.md"
mkdir -p "$T4/.agents/skills/my-own-skill"
echo "# Mine" >"$T4/.agents/skills/my-own-skill/SKILL.md"
"$SRC4/scripts/install.sh" "$T4" --uninstall --yes >/dev/null
assert_missing "kstack skill removed" "$T4/.agents/skills/code-review"
assert_file "local skill kept" "$T4/.agents/skills/my-own-skill/SKILL.md"
assert_file "context archived on uninstall" "$T4/.agents/.kstack-archive/code-review/context.md"
assert_contains "archived overlay text" "$T4/.agents/.kstack-archive/code-review/context.md" "KEEP ME ON UNINSTALL"
assert_missing "skills manifest gone" "$T4/.agents/.kstack-skills"
assert_missing "files manifest gone" "$T4/.agents/.kstack-files"
assert_missing "agent gone" "$T4/.agents/agents/kstack.md"
assert_missing "cursor agent gone" "$T4/.cursor/agents/kstack.md"
# shims removed when ours
if [[ -L "$T4/.claude/skills" ]]; then
  echo "  FAIL: claude shim still present"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: claude shim removed"
  PASS=$((PASS + 1))
fi

# ---------------------------------------------------------------------------
# cleanup
# ---------------------------------------------------------------------------
rm -rf "$SRC" "$T" "$SRC2" "$T2" "$SRC3" "$T3" "$SRC4" "$T4"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
