#!/usr/bin/env bash
# Install kstack skills into a target project (.agents/-first, with host shims).
#
# Usage:
#   ./scripts/install.sh /path/to/project
#   ./scripts/install.sh /path/to/project --ref v2.0.0
#   ./scripts/install.sh /path/to/project --symlink
#   ./scripts/install.sh /path/to/project --keep
#   ./scripts/install.sh /path/to/project --overwrite
#   ./scripts/install.sh /path/to/project --uninstall [--yes]
#
# Reinstall never overwrites existing context.md / context.*.md. Other files are
# upgraded when unmodified (checksum match). Locally edited files are kept by
# default; upstream is written as a .kstack-new sidecar with a merge report.
# Retired skills are pruned; authored overlays are archived first.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
REF=""
USE_SYMLINK=false
CONFLICT_MODE="" # "" | keep | overwrite
DO_UNINSTALL=false
ASSUME_YES=false
APPLY_ALL="" # "" | keep | overwrite

CONFLICT_COUNT=0
LEGACY_MODE=""
KEEP_FLAG=false
OVERWRITE_FLAG=false

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
    --keep)
      KEEP_FLAG=true
      CONFLICT_MODE="keep"
      shift
      ;;
    --overwrite)
      OVERWRITE_FLAG=true
      CONFLICT_MODE="overwrite"
      shift
      ;;
    --uninstall)
      DO_UNINSTALL=true
      shift
      ;;
    --yes | -y)
      ASSUME_YES=true
      shift
      ;;
    -h | --help)
      cat <<'EOF'
Usage: install.sh <target-project> [options]

Options:
  --ref <tag>     Checkout that tag/ref in the kstack clone before installing
  --symlink       Symlink skill files into the project instead of copying
  --keep          On conflict, keep local edits and write .kstack-new sidecars
  --overwrite     On conflict, take upstream (discards local skill-body edits)
  --uninstall     Remove kstack-managed skills/agent/shims from the target
  --yes           Non-interactive confirmation for --uninstall
  -h, --help      Show this help

Installs skills under .agents/skills/ (all hosts) and the kstack router agent
for Cursor (.cursor/agents/kstack.md). Claude Code / Codex get skills only.

Reinstall:
  - Never overwrites existing context.md / context.*.md
  - Overwrites other files only when they match the last-installed checksum
  - Locally edited files: prompt (TTY) or --keep (non-TTY); writes sidecars +
    .agents/.kstack-merge.md for agent-assisted merge
  - Prunes retired skills; archives authored context overlays first
  - Migrates overlays across renames listed in scripts/renamed-skills.txt
EOF
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

if [[ "$KEEP_FLAG" == true && "$OVERWRITE_FLAG" == true ]]; then
  echo "ERROR: --keep and --overwrite are mutually exclusive" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"
SRC_SKILLS="$REPO_ROOT/.agents/skills"
SRC_AGENT="$REPO_ROOT/.agents/agents/kstack.md"
RETIRED_SKILLS_FILE="$REPO_ROOT/scripts/retired-skills.txt"
RENAMED_SKILLS_FILE="$REPO_ROOT/scripts/renamed-skills.txt"

TARGET_AGENTS="$TARGET/.agents"
TARGET_AGENTS_SKILLS="$TARGET_AGENTS/skills"
TARGET_AGENTS_AGENT_DIR="$TARGET_AGENTS/agents"
TARGET_CURSOR_AGENTS="$TARGET/.cursor/agents"
TARGET_CLAUDE_SKILLS="$TARGET/.claude/skills"
TARGET_CURSOR_SKILLS="$TARGET/.cursor/skills"
MANIFEST="$TARGET_AGENTS/.kstack-skills"
FILES_MANIFEST="$TARGET_AGENTS/.kstack-files"
MERGE_REPORT="$TARGET_AGENTS/.kstack-merge.md"
ARCHIVE_DIR="$TARGET_AGENTS/.kstack-archive"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

file_sha256() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
  else
    echo "ERROR: need sha256sum or shasum" >&2
    exit 1
  fi
}

is_context_file() {
  local name="$1"
  [[ "$name" == "context.md" || "$name" == context.*.md ]]
}

# Skill directory names only (no path separators / parent refs).
is_safe_skill_name() {
  local name="$1"
  [[ "$name" =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ ]]
}

# Bash 3.2 compatible: look up hashes via line scan of FILES_MANIFEST (no assoc arrays).
HAS_FILES_MANIFEST=false

load_files_manifest() {
  HAS_FILES_MANIFEST=false
  [[ -f "$FILES_MANIFEST" ]] || return 0
  HAS_FILES_MANIFEST=true
}

NEW_FILES_MANIFEST=""
cleanup_install_temp() {
  if [[ -n "${NEW_FILES_MANIFEST:-}" && -f "${NEW_FILES_MANIFEST:-}" ]]; then
    rm -f "$NEW_FILES_MANIFEST"
  fi
}
trap cleanup_install_temp EXIT

init_new_files_manifest() {
  NEW_FILES_MANIFEST="$(mktemp)"
  echo "# sha256 paths relative to .agents/skills/ (or agent:kstack.md)." >"$NEW_FILES_MANIFEST"
  echo "# Managed by scripts/install.sh — do not edit by hand." >>"$NEW_FILES_MANIFEST"
}

copy_content() {
  local src="$1"
  local dest="$2"
  cp -L "$src" "$dest" 2>/dev/null || cp "$src" "$dest"
}

place_file() {
  local src="$1"
  local dest="$2"
  local mode="$3"
  if [[ "$mode" == "link" ]]; then
    ln -sf "$src" "$dest"
  else
    copy_content "$src" "$dest"
  fi
}

record_file_hash() {
  local relpath="$1"
  local abspath="$2"
  local hash
  if [[ -L "$abspath" ]]; then
    [[ -f "$abspath" ]] || return 0
    hash="$(file_sha256 "$abspath")"
  elif [[ -f "$abspath" ]]; then
    hash="$(file_sha256 "$abspath")"
  else
    return 0
  fi
  echo "$hash $relpath" >>"$NEW_FILES_MANIFEST"
}

write_files_manifest() {
  mkdir -p "$TARGET_AGENTS"
  mv "$NEW_FILES_MANIFEST" "$FILES_MANIFEST"
  NEW_FILES_MANIFEST=""
}

recorded_hash_for() {
  local relpath="$1" line hash path
  [[ -f "$FILES_MANIFEST" ]] || return 0
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    hash="${line%% *}"
    path="${line#* }"
    if [[ "$path" == "$relpath" ]]; then
      echo "$hash"
      return 0
    fi
  done <"$FILES_MANIFEST"
}

is_interactive() {
  [[ -t 0 && -t 1 ]]
}

prompt_conflict() {
  local relpath="$1"
  local choice
  if [[ -n "$APPLY_ALL" ]]; then
    echo "$APPLY_ALL"
    return 0
  fi
  if [[ -n "$CONFLICT_MODE" ]]; then
    echo "$CONFLICT_MODE"
    return 0
  fi
  if ! is_interactive; then
    echo "keep"
    return 0
  fi
  while true; do
    printf "Conflict: %s\n  [o]verwrite with upstream  [k]eep local + sidecar  [s]kip (keep, no sidecar)  [a]pply to all remaining\n> " "$relpath" >&2
    read -r choice || choice="k"
    case "$choice" in
      o | O)
        echo "overwrite"
        return 0
        ;;
      k | K)
        echo "keep"
        return 0
        ;;
      s | S)
        echo "skip"
        return 0
        ;;
      a | A)
        printf "Apply to all remaining? [o]verwrite / [k]eep: " >&2
        read -r choice || choice="k"
        case "$choice" in
          o | O)
            APPLY_ALL="overwrite"
            echo "overwrite"
            return 0
            ;;
          *)
            APPLY_ALL="keep"
            echo "keep"
            return 0
            ;;
        esac
        ;;
      *)
        echo "Enter o, k, s, or a." >&2
        ;;
    esac
  done
}

init_merge_report() {
  rm -f "$MERGE_REPORT"
}

local_display_path() {
  local relpath="$1"
  case "$relpath" in
    cursor-agent:*)
      echo ".cursor/agents/${relpath#cursor-agent:}"
      ;;
    agent:*)
      echo ".agents/agents/${relpath#agent:}"
      ;;
    *)
      echo ".agents/skills/$relpath"
      ;;
  esac
}

append_merge_entry() {
  local relpath="$1"
  local local_path sidecar_path
  local_path="$(local_display_path "$relpath")"
  sidecar_path="${local_path}.kstack-new"
  if [[ ! -f "$MERGE_REPORT" ]]; then
    cat >"$MERGE_REPORT" <<'EOF'
# kstack merge report

Local skill files differ from the newly installed upstream copies.
For each entry below, merge upstream changes into the local file, then delete
the `.kstack-new` sidecar.

Ask your agent: "Apply the merge report at `.agents/.kstack-merge.md`."

EOF
  fi
  {
    echo "## \`$local_path\`"
    echo ""
    echo "- Local: \`$local_path\`"
    echo "- Upstream: \`$sidecar_path\`"
    echo "- Action: merge upstream into local, delete the sidecar, remove this section"
    echo ""
  } >>"$MERGE_REPORT"
}

finalize_merge_report() {
  if [[ "$CONFLICT_COUNT" -eq 0 ]]; then
    rm -f "$MERGE_REPORT"
  fi
}

clear_stale_sidecar() {
  local dest="$1"
  local sidecar="${dest}.kstack-new"
  if [[ -f "$sidecar" ]]; then
    rm -f "$sidecar"
  fi
}

install_file() {
  local src="$1"
  local dest="$2"
  local relpath="$3"
  local mode="$4"
  local name
  name="$(basename "$src")"

  mkdir -p "$(dirname "$dest")"

  # Never overwrite existing context overlays; record shipped stub hash for prune detection.
  if is_context_file "$name"; then
    if [[ -e "$dest" ]]; then
      local prev stub_hash
      prev="$(recorded_hash_for "$relpath")"
      if [[ -n "$prev" ]]; then
        echo "$prev $relpath" >>"$NEW_FILES_MANIFEST"
      else
        stub_hash="$(file_sha256 "$src")"
        echo "$stub_hash $relpath" >>"$NEW_FILES_MANIFEST"
      fi
      return 0
    fi
    place_file "$src" "$dest" "$mode"
    record_file_hash "$relpath" "$dest"
    return 0
  fi

  # Symlink installs: refresh links; a real file at dest is a local edit → conflict path.
  if [[ "$mode" == "link" && -L "$dest" ]]; then
    place_file "$src" "$dest" "link"
    record_file_hash "$relpath" "$dest"
    clear_stale_sidecar "$dest"
    return 0
  fi

  if [[ ! -e "$dest" ]]; then
    place_file "$src" "$dest" "$mode"
    record_file_hash "$relpath" "$dest"
    return 0
  fi

  local dest_hash src_hash recorded
  src_hash="$(file_sha256 "$src")"
  dest_hash=""
  [[ -f "$dest" ]] && dest_hash="$(file_sha256 "$dest")"

  if [[ -n "$dest_hash" && "$dest_hash" == "$src_hash" ]]; then
    [[ "$mode" == "link" && -L "$dest" ]] && place_file "$src" "$dest" "link"
    record_file_hash "$relpath" "$dest"
    clear_stale_sidecar "$dest"
    return 0
  fi

  recorded="$(recorded_hash_for "$relpath")"

  if [[ -n "$recorded" && -n "$dest_hash" && "$dest_hash" == "$recorded" ]]; then
    [[ "$mode" == "link" ]] && rm -f "$dest"
    place_file "$src" "$dest" "$mode"
    record_file_hash "$relpath" "$dest"
    clear_stale_sidecar "$dest"
    return 0
  fi

  if [[ "$HAS_FILES_MANIFEST" != true ]]; then
    apply_conflict_action "$src" "$dest" "$relpath" "$mode" "${LEGACY_MODE:-keep}"
    return 0
  fi

  local action
  action="$(prompt_conflict "$relpath")"
  apply_conflict_action "$src" "$dest" "$relpath" "$mode" "$action"
}

apply_conflict_action() {
  local src="$1"
  local dest="$2"
  local relpath="$3"
  local mode="$4"
  local action="$5"
  local upstream_hash

  case "$action" in
    overwrite)
      [[ "$mode" == "link" ]] && rm -f "$dest"
      place_file "$src" "$dest" "$mode"
      record_file_hash "$relpath" "$dest"
      clear_stale_sidecar "$dest"
      echo "overwrote $relpath (took upstream)"
      ;;
    skip)
      # Keep local; record upstream hash so the next reinstall still sees a conflict.
      upstream_hash="$(file_sha256 "$src")"
      echo "$upstream_hash $relpath" >>"$NEW_FILES_MANIFEST"
      echo "kept $relpath (no sidecar)"
      ;;
    keep | *)
      copy_content "$src" "${dest}.kstack-new"
      upstream_hash="$(file_sha256 "$src")"
      echo "$upstream_hash $relpath" >>"$NEW_FILES_MANIFEST"
      append_merge_entry "$relpath"
      CONFLICT_COUNT=$((CONFLICT_COUNT + 1))
      echo "kept $relpath; wrote $(local_display_path "$relpath").kstack-new"
      ;;
  esac
}

collect_legacy_diffs() {
  local src_root="$1"
  local dest_root="$2"
  local rel_prefix="${3:-}"
  local item name dest relpath
  shopt -s nullglob
  for item in "$src_root"/*; do
    name="$(basename "$item")"
    [[ -L "$item" ]] && continue
    if [[ -d "$item" ]]; then
      if [[ -n "$rel_prefix" ]]; then
        collect_legacy_diffs "$item" "$dest_root/$name" "$rel_prefix/$name"
      else
        collect_legacy_diffs "$item" "$dest_root/$name" "$name"
      fi
    elif [[ -f "$item" ]]; then
      is_context_file "$name" && continue
      dest="$dest_root/$name"
      [[ -f "$dest" ]] || continue
      [[ -L "$dest" ]] && continue
      if [[ "$(file_sha256 "$item")" != "$(file_sha256 "$dest")" ]]; then
        if [[ -n "$rel_prefix" ]]; then
          relpath="$rel_prefix/$name"
        else
          relpath="$name"
        fi
        echo "$relpath"
      fi
    fi
  done
  shopt -u nullglob
}

resolve_legacy_mode() {
  LEGACY_MODE=""
  if [[ "$HAS_FILES_MANIFEST" == true ]]; then
    return 0
  fi
  [[ -d "$TARGET_AGENTS_SKILLS" ]] || return 0

  local diffs
  diffs="$(collect_legacy_diffs "$SRC_SKILLS" "$TARGET_AGENTS_SKILLS" || true)"
  local count
  count="$(printf '%s\n' "$diffs" | grep -c . || true)"
  [[ "$count" -gt 0 ]] || return 0

  if [[ -n "$CONFLICT_MODE" ]]; then
    LEGACY_MODE="$CONFLICT_MODE"
    echo "Legacy install (no checksum manifest): $count differing file(s) → $LEGACY_MODE"
    return 0
  fi

  if ! is_interactive; then
    LEGACY_MODE="keep"
    echo "Legacy install (no checksum manifest): $count differing file(s); keeping local + writing merge report (non-interactive)."
    return 0
  fi

  local choice
  while true; do
    printf "%s\n" \
      "Legacy install: no .agents/.kstack-files checksum record." \
      "$count file(s) differ from upstream and provenance is unknown." \
      "  [o]verwrite all with upstream" \
      "  [k]eep all local + write sidecars / merge report" \
      "> " >&2
    read -r choice || choice="k"
    case "$choice" in
      o | O)
        LEGACY_MODE="overwrite"
        return 0
        ;;
      k | K)
        LEGACY_MODE="keep"
        return 0
        ;;
      *)
        echo "Enter o or k." >&2
        ;;
    esac
  done
}

install_tree() {
  local src="$1"
  local dest="$2"
  local mode="$3"
  local rel_prefix="${4:-}"
  local item name relpath
  mkdir -p "$dest"
  shopt -s nullglob
  for item in "$src"/*; do
    name="$(basename "$item")"
    [[ -L "$item" ]] && continue
    if [[ -n "$rel_prefix" ]]; then
      relpath="$rel_prefix/$name"
    else
      relpath="$name"
    fi
    if [[ -d "$item" ]]; then
      install_tree "$item" "$dest/$name" "$mode" "$relpath"
    elif [[ -f "$item" ]]; then
      install_file "$item" "$dest/$name" "$relpath" "$mode"
    fi
  done
  shopt -u nullglob
}

list_source_skills() {
  local skill_file
  shopt -s nullglob
  for skill_file in "$SRC_SKILLS"/*/SKILL.md; do
    basename "$(dirname "$skill_file")"
  done
  shopt -u nullglob
}

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

# Authored = differs from recorded stub hash; without a record, longer than the 4-line stub.
context_is_authored() {
  local abspath="$1"
  local relpath="$2"
  [[ -f "$abspath" ]] || return 1
  local recorded dest_hash lines
  recorded="$(recorded_hash_for "$relpath")"
  dest_hash="$(file_sha256 "$abspath")"
  if [[ -n "$recorded" ]]; then
    [[ "$dest_hash" != "$recorded" ]]
    return $?
  fi
  lines="$(wc -l <"$abspath" | tr -d ' ')"
  [[ "$lines" -gt 4 ]]
}

archive_context_overlays() {
  local skill_dir="$1"
  local skill_name="$2"
  local archived=0
  local f name relpath
  shopt -s nullglob
  for f in "$skill_dir"/context.md "$skill_dir"/context.*.md; do
    [[ -f "$f" && ! -L "$f" ]] || continue
    name="$(basename "$f")"
    relpath="$skill_name/$name"
    if context_is_authored "$f" "$relpath"; then
      mkdir -p "$ARCHIVE_DIR/$skill_name"
      cp "$f" "$ARCHIVE_DIR/$skill_name/$name"
      echo "archived $relpath → .agents/.kstack-archive/$skill_name/$name"
      archived=$((archived + 1))
    fi
  done
  shopt -u nullglob
  return 0
}

migrate_renamed_skills() {
  [[ -f "$RENAMED_SKILLS_FILE" ]] || return 0
  local line old new old_dir new_dir f name
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    old="$(printf '%s\n' "$line" | awk '{print $1}')"
    new="$(printf '%s\n' "$line" | awk '{print $2}')"
    is_safe_skill_name "$old" && is_safe_skill_name "$new" || continue
    old_dir="$TARGET_AGENTS_SKILLS/$old"
    new_dir="$TARGET_AGENTS_SKILLS/$new"
    [[ -d "$old_dir" && ! -L "$old_dir" && -d "$new_dir" ]] || continue

    shopt -s nullglob
    for f in "$old_dir"/context.md "$old_dir"/context.*.md; do
      [[ -f "$f" && ! -L "$f" ]] || continue
      name="$(basename "$f")"
      if [[ -f "$new_dir/$name" ]] && context_is_authored "$new_dir/$name" "$new/$name"; then
        echo "rename migrate skip $old/$name → $new/$name (destination already authored)"
        continue
      fi
      if context_is_authored "$f" "$old/$name" || [[ ! -f "$new_dir/$name" ]]; then
        cp "$f" "$new_dir/$name"
        echo "migrated context $old/$name → $new/$name"
      fi
    done
    shopt -u nullglob
  done <"$RENAMED_SKILLS_FILE"
}

prune_retired_skills() {
  local name dest pruned=0

  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    is_safe_skill_name "$name" || continue

    if is_current_skill "$name"; then
      continue
    fi

    dest="$TARGET_AGENTS_SKILLS/$name"
    if [[ ! -e "$dest" ]] || [[ -L "$dest" ]]; then
      continue
    fi
    if [[ ! -d "$dest" ]]; then
      continue
    fi

    archive_context_overlays "$dest" "$name"
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

install_agent_file() {
  local dest="$TARGET_AGENTS_AGENT_DIR/kstack.md"
  mkdir -p "$TARGET_AGENTS_AGENT_DIR"
  local relpath="agent:kstack.md"
  if [[ "$USE_SYMLINK" == true ]]; then
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      install_file "$SRC_AGENT" "$dest" "$relpath" "copy"
    else
      ln -sf "$SRC_AGENT" "$dest"
      record_file_hash "$relpath" "$dest"
    fi
  else
    install_file "$SRC_AGENT" "$dest" "$relpath" "copy"
  fi
}

# Cursor discovers the router under .cursor/agents/. Keep local edits when they
# diverge from the installed .agents/agents copy (same conflict policy as skills).
sync_cursor_agent() {
  local src="$TARGET_AGENTS_AGENT_DIR/kstack.md"
  local dest="$TARGET_CURSOR_AGENTS/kstack.md"
  local relpath="cursor-agent:kstack.md"
  local src_hash dest_hash action

  mkdir -p "$TARGET_CURSOR_AGENTS"
  [[ -f "$src" ]] || return 0

  if [[ ! -e "$dest" ]]; then
    copy_content "$src" "$dest"
    return 0
  fi

  src_hash="$(file_sha256 "$src")"
  if [[ -f "$dest" ]]; then
    dest_hash="$(file_sha256 "$dest")"
    if [[ "$src_hash" == "$dest_hash" ]]; then
      clear_stale_sidecar "$dest"
      return 0
    fi
  fi

  action="$(prompt_conflict "$relpath")"
  apply_conflict_action "$src" "$dest" "$relpath" "copy" "$action"
}

update_gitignore() {
  local gi="$TARGET/.gitignore"
  if [[ ! -f "$gi" ]]; then
    printf '# kstack clone directory (optional)\n.kstack/\n\n# kstack reinstall sidecars / merge report\n*.kstack-new\n.agents/.kstack-merge.md\n' >"$gi"
    return 0
  fi

  if ! grep -q '^\.kstack/$' "$gi" 2>/dev/null; then
    printf '\n# kstack clone directory (optional)\n.kstack/\n' >>"$gi"
  fi
  if ! grep -q '\*\.kstack-new' "$gi" 2>/dev/null; then
    printf '\n# kstack reinstall sidecars / merge report\n*.kstack-new\n.agents/.kstack-merge.md\n' >>"$gi"
  fi
}

strip_gitignore_kstack_blocks() {
  local gi="$TARGET/.gitignore"
  [[ -f "$gi" ]] || return 0
  local tmp
  tmp="$(mktemp)"
  # Remove our known appended blocks (best-effort line patterns)
  awk '
    /^# kstack clone directory \(optional\)$/ { skip=1; next }
    skip && /^\.kstack\/$/ { skip=0; next }
    /^# kstack reinstall sidecars \/ merge report$/ { skip=2; next }
    skip==2 && /^\*\.kstack-new$/ { next }
    skip==2 && /^\.agents\/\.kstack-merge\.md$/ { skip=0; next }
    { print }
  ' "$gi" >"$tmp"
  mv "$tmp" "$gi"
}

remove_shim_if_ours() {
  local link="$1"
  if [[ -L "$link" ]]; then
    local target
    target="$(readlink "$link")"
    if [[ "$target" == "../.agents/skills" || "$target" == "../.agents/skills/" ]]; then
      rm -f "$link"
      echo "removed shim $link"
    else
      echo "NOTE: left $link (points to $target, not ../.agents/skills)"
    fi
  elif [[ -e "$link" ]]; then
    echo "NOTE: left $link (not a symlink)"
  fi
}

confirm_uninstall() {
  if [[ "$ASSUME_YES" == true ]]; then
    return 0
  fi
  if ! is_interactive; then
    echo "ERROR: --uninstall requires --yes when non-interactive" >&2
    exit 1
  fi
  local answer
  printf "Uninstall kstack from %s? [y/N] " "$TARGET" >&2
  read -r answer || answer="n"
  case "$answer" in
    y | Y | yes | YES) return 0 ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
}

do_uninstall() {
  confirm_uninstall
  load_files_manifest

  local name dest removed=0
  if [[ -f "$MANIFEST" ]]; then
    while IFS= read -r name; do
      [[ -z "$name" || "$name" == \#* ]] && continue
      is_safe_skill_name "$name" || continue
      dest="$TARGET_AGENTS_SKILLS/$name"
      if [[ -d "$dest" && ! -L "$dest" ]]; then
        archive_context_overlays "$dest" "$name"
        rm -rf "$dest"
        echo "removed skill $name"
        removed=$((removed + 1))
      fi
    done <"$MANIFEST"
  else
    echo "NOTE: no .agents/.kstack-skills manifest; not removing skill directories."
  fi

  rm -f "$TARGET_AGENTS_AGENT_DIR/kstack.md"
  rm -f "$TARGET_CURSOR_AGENTS/kstack.md"
  echo "removed kstack agent files"

  remove_shim_if_ours "$TARGET_CLAUDE_SKILLS"
  remove_shim_if_ours "$TARGET_CURSOR_SKILLS"

  if [[ -d "$TARGET_AGENTS_SKILLS" ]]; then
    find "$TARGET_AGENTS_SKILLS" -name '*.kstack-new' -type f -delete 2>/dev/null || true
  fi
  if [[ -d "$TARGET_CURSOR_AGENTS" ]]; then
    find "$TARGET_CURSOR_AGENTS" -name '*.kstack-new' -type f -delete 2>/dev/null || true
  fi
  rm -f "$MERGE_REPORT" "$FILES_MANIFEST" "$MANIFEST"

  strip_gitignore_kstack_blocks

  rmdir "$TARGET_AGENTS_AGENT_DIR" 2>/dev/null || true
  rmdir "$TARGET_AGENTS_SKILLS" 2>/dev/null || true
  rmdir "$TARGET_CURSOR_AGENTS" 2>/dev/null || true
  rmdir "$TARGET/.claude" 2>/dev/null || true
  # Leave .agents/ when archive or other project content remains.
  if [[ -d "$TARGET_AGENTS" && -z "$(ls -A "$TARGET_AGENTS" 2>/dev/null)" ]]; then
    rmdir "$TARGET_AGENTS"
  fi

  echo "Uninstalled kstack from $TARGET ($removed skill dir(s) removed)."
  if [[ -d "$ARCHIVE_DIR" ]]; then
    echo "Authored context overlays archived under .agents/.kstack-archive/ (not deleted)."
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if [[ "$DO_UNINSTALL" == true ]]; then
  do_uninstall
  exit 0
fi

if [[ ! -d "$SRC_SKILLS" ]]; then
  echo "ERROR: skills not found at $SRC_SKILLS" >&2
  exit 1
fi
if [[ ! -f "$SRC_AGENT" ]]; then
  echo "ERROR: kstack agent not found at $SRC_AGENT" >&2
  exit 1
fi

if [[ -n "$REF" ]]; then
  git -C "$REPO_ROOT" fetch --tags origin 2>/dev/null || true
  git -C "$REPO_ROOT" checkout "$REF"
fi

mkdir -p "$TARGET_AGENTS_SKILLS" "$TARGET_AGENTS_AGENT_DIR" "$TARGET_CURSOR_AGENTS"

CURRENT_SKILLS="$(list_source_skills | sort)"
load_files_manifest
init_new_files_manifest
init_merge_report
resolve_legacy_mode

if [[ "$USE_SYMLINK" == true ]]; then
  install_tree "$SRC_SKILLS" "$TARGET_AGENTS_SKILLS" "link"
else
  install_tree "$SRC_SKILLS" "$TARGET_AGENTS_SKILLS" "copy"
fi

install_agent_file
sync_cursor_agent

migrate_renamed_skills
prune_retired_skills
write_install_manifest
write_files_manifest
finalize_merge_report

mkdir -p "$TARGET/.claude"
if [[ -e "$TARGET_CLAUDE_SKILLS" && ! -L "$TARGET_CLAUDE_SKILLS" ]]; then
  echo "NOTE: $TARGET_CLAUDE_SKILLS already exists and is not a symlink — left unchanged."
else
  ln -sfn "../.agents/skills" "$TARGET_CLAUDE_SKILLS"
fi

if [[ -e "$TARGET_CURSOR_SKILLS" && ! -L "$TARGET_CURSOR_SKILLS" ]]; then
  echo "NOTE: $TARGET_CURSOR_SKILLS already exists and is not a symlink — left unchanged."
else
  mkdir -p "$TARGET/.cursor"
  ln -sfn "../.agents/skills" "$TARGET_CURSOR_SKILLS"
fi

update_gitignore

echo "Installed kstack into $TARGET/.agents/"
echo "  Skills:   .agents/skills/  (all hosts — invoke pipeline/step skills directly)"
echo "  Manifest: .agents/.kstack-skills + .agents/.kstack-files (prune + checksums)"
echo "  Agent:    .agents/agents/kstack.md → .cursor/agents/kstack.md"
echo "            (Cursor only: enables /kstack router; other hosts have no /kstack)"
echo "  Shims:    .claude/skills → .agents/skills, .cursor/skills → .agents/skills"
if [[ "$CONFLICT_COUNT" -gt 0 ]]; then
  echo ""
  echo "Conflicts: $CONFLICT_COUNT file(s) kept locally with .kstack-new sidecars."
  echo "Next: open .agents/.kstack-merge.md and ask your agent to apply the merge report."
else
  echo "Next: fill in context.md files (see examples/context-templates/)."
fi
echo "      Cursor: /kstack …  |  Claude/Codex: /planning-pipeline, \$review-pipeline, etc."
