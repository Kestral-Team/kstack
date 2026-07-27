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
LEGACY_DIFF_COUNT=0
LEGACY_MODE="" # set after aggregated legacy prompt if needed
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

# Relative path from TARGET_AGENTS_SKILLS (or absolute key for agent file).
rel_skills_path() {
  local abs="$1"
  echo "${abs#"$TARGET_AGENTS_SKILLS/"}"
}

# Bash 3.2 compatible: look up hashes via grep on FILES_MANIFEST (no assoc arrays).
HAS_FILES_MANIFEST=false

load_files_manifest() {
  HAS_FILES_MANIFEST=false
  [[ -f "$FILES_MANIFEST" ]] || return 0
  HAS_FILES_MANIFEST=true
}

# Staging for new manifest written at end of install
NEW_FILES_MANIFEST=""
init_new_files_manifest() {
  NEW_FILES_MANIFEST="$(mktemp)"
  echo "# sha256 paths relative to .agents/skills/ (or agent:kstack.md)." >"$NEW_FILES_MANIFEST"
  echo "# Managed by scripts/install.sh — do not edit by hand." >>"$NEW_FILES_MANIFEST"
}

record_file_hash() {
  local relpath="$1"
  local abspath="$2"
  local hash
  if [[ -L "$abspath" ]]; then
    # Record hash of the target content when it's a real file we can read
    if [[ -f "$abspath" ]]; then
      hash="$(file_sha256 "$abspath")"
    else
      return 0
    fi
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
  if [[ "$relpath" == agent:* ]]; then
    echo ".agents/agents/${relpath#agent:}"
  else
    echo ".agents/skills/$relpath"
  fi
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

# Decide and apply one file. Args: src_file dest_file relpath mode(copy|link)
install_file() {
  local src="$1"
  local dest="$2"
  local relpath="$3"
  local mode="$4"
  local name
  name="$(basename "$src")"

  mkdir -p "$(dirname "$dest")"

  # context.md / context.*.md: never overwrite if present
  if is_context_file "$name"; then
    if [[ -e "$dest" ]]; then
      # Record the *shipped* stub hash (previous record or current upstream), not
      # the live dest — so prune/archive can detect authored overlays.
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
    if [[ "$mode" == "link" ]]; then
      ln -sf "$src" "$dest"
    else
      cp "$src" "$dest"
    fi
    record_file_hash "$relpath" "$dest"
    return 0
  fi

  # Symlink mode: if dest is already a symlink into src, refresh and record
  if [[ "$mode" == "link" ]]; then
    if [[ -L "$dest" ]]; then
      ln -sf "$src" "$dest"
      record_file_hash "$relpath" "$dest"
      clear_stale_sidecar "$dest"
      return 0
    fi
    # Real file replaced a symlink — treat as conflict candidate below
  fi

  if [[ ! -e "$dest" ]]; then
    if [[ "$mode" == "link" ]]; then
      ln -sf "$src" "$dest"
    else
      cp "$src" "$dest"
    fi
    record_file_hash "$relpath" "$dest"
    return 0
  fi

  # Dest exists (regular file, or broken expectations)
  local dest_hash src_hash recorded
  src_hash="$(file_sha256 "$src")"
  if [[ -f "$dest" ]]; then
    dest_hash="$(file_sha256 "$dest")"
  else
    dest_hash=""
  fi

  # Already matches upstream
  if [[ -n "$dest_hash" && "$dest_hash" == "$src_hash" ]]; then
    if [[ "$mode" == "link" && ! -L "$dest" ]]; then
      : # keep identical real file; or convert? keep as-is
    elif [[ "$mode" == "link" ]]; then
      ln -sf "$src" "$dest"
    fi
    record_file_hash "$relpath" "$dest"
    clear_stale_sidecar "$dest"
    return 0
  fi

  recorded="$(recorded_hash_for "$relpath")"

  # Unmodified since last install — safe to upgrade
  if [[ -n "$recorded" && -n "$dest_hash" && "$dest_hash" == "$recorded" ]]; then
    if [[ "$mode" == "link" ]]; then
      rm -f "$dest"
      ln -sf "$src" "$dest"
    else
      cp "$src" "$dest"
    fi
    record_file_hash "$relpath" "$dest"
    clear_stale_sidecar "$dest"
    return 0
  fi

  # No recorded hash (legacy reinstall) — use aggregated LEGACY_MODE
  if [[ "$HAS_FILES_MANIFEST" != true ]]; then
    apply_conflict_action "$src" "$dest" "$relpath" "$mode" "${LEGACY_MODE:-keep}"
    return 0
  fi

  # Known install + local modification
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
      if [[ "$mode" == "link" ]]; then
        rm -f "$dest"
        ln -sf "$src" "$dest"
      else
        cp "$src" "$dest"
      fi
      record_file_hash "$relpath" "$dest"
      clear_stale_sidecar "$dest"
      echo "overwrote $relpath (took upstream)"
      ;;
    skip)
      # Record upstream hash so the local edit still looks modified next reinstall.
      upstream_hash="$(file_sha256 "$src")"
      echo "$upstream_hash $relpath" >>"$NEW_FILES_MANIFEST"
      echo "kept $relpath (no sidecar)"
      ;;
    keep | *)
      cp "$src" "${dest}.kstack-new"
      upstream_hash="$(file_sha256 "$src")"
      echo "$upstream_hash $relpath" >>"$NEW_FILES_MANIFEST"
      append_merge_entry "$relpath" "${relpath}.kstack-new"
      CONFLICT_COUNT=$((CONFLICT_COUNT + 1))
      echo "kept $relpath; wrote ${relpath}.kstack-new"
      ;;
  esac
}

# Two-pass for legacy: scan for differing non-context files, prompt once, then install.
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
  # Only if target already has skills (reinstall)
  [[ -d "$TARGET_AGENTS_SKILLS" ]] || return 0

  local diffs
  diffs="$(collect_legacy_diffs "$SRC_SKILLS" "$TARGET_AGENTS_SKILLS" || true)"
  local count
  count="$(printf '%s\n' "$diffs" | grep -c . || true)"
  [[ "$count" -gt 0 ]] || return 0

  LEGACY_DIFF_COUNT="$count"

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

copy_tree() {
  local src="$1"
  local dest="$2"
  local rel_prefix="${3:-}"
  local item name relpath
  mkdir -p "$dest"
  shopt -s nullglob
  for item in "$src"/*; do
    name="$(basename "$item")"
    if [[ -L "$item" ]]; then
      continue
    fi
    if [[ -n "$rel_prefix" ]]; then
      relpath="$rel_prefix/$name"
    else
      relpath="$name"
    fi
    if [[ -d "$item" ]]; then
      copy_tree "$item" "$dest/$name" "$relpath"
    elif [[ -f "$item" ]]; then
      install_file "$item" "$dest/$name" "$relpath" "copy"
    fi
  done
  shopt -u nullglob
}

link_tree() {
  local src="$1"
  local dest="$2"
  local rel_prefix="${3:-}"
  local item name relpath
  mkdir -p "$dest"
  shopt -s nullglob
  for item in "$src"/*; do
    name="$(basename "$item")"
    if [[ -L "$item" ]]; then
      continue
    fi
    if [[ -n "$rel_prefix" ]]; then
      relpath="$rel_prefix/$name"
    else
      relpath="$name"
    fi
    if [[ -d "$item" ]]; then
      link_tree "$item" "$dest/$name" "$relpath"
    elif [[ -f "$item" ]]; then
      install_file "$item" "$dest/$name" "$relpath" "link"
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

# Returns 0 if context file looks authored (differs from recorded hash, or no hash and >4 lines)
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
  # No record: treat as authored if longer than the empty stub (~4 lines)
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
    # Support tab or whitespace separator
    old="$(printf '%s\n' "$line" | awk '{print $1}')"
    new="$(printf '%s\n' "$line" | awk '{print $2}')"
    [[ -n "$old" && -n "$new" ]] || continue
    old_dir="$TARGET_AGENTS_SKILLS/$old"
    new_dir="$TARGET_AGENTS_SKILLS/$new"
    [[ -d "$old_dir" && ! -L "$old_dir" ]] || continue
    [[ -d "$new_dir" ]] || continue

    shopt -s nullglob
    for f in "$old_dir"/context.md "$old_dir"/context.*.md; do
      [[ -f "$f" && ! -L "$f" ]] || continue
      name="$(basename "$f")"
      if [[ -f "$new_dir/$name" ]]; then
        # Only migrate onto pristine stub / missing authored content
        if context_is_authored "$new_dir/$name" "$new/$name"; then
          echo "rename migrate skip $old/$name → $new/$name (destination already authored)"
          continue
        fi
      fi
      if context_is_authored "$f" "$old/$name" || [[ ! -f "$new_dir/$name" ]]; then
        # Migrate if old looks authored, or always if new missing; for stubs copy if new is stub
        if context_is_authored "$f" "$old/$name"; then
          cp "$f" "$new_dir/$name"
          echo "migrated context $old/$name → $new/$name"
        elif [[ ! -f "$new_dir/$name" ]]; then
          cp "$f" "$new_dir/$name"
          echo "migrated context $old/$name → $new/$name"
        else
          # Old is stub and new exists as stub — nothing to do
          :
        fi
      fi
    done
    shopt -u nullglob
  done <"$RENAMED_SKILLS_FILE"
}

prune_retired_skills() {
  local name dest pruned=0

  while IFS= read -r name; do
    [[ -n "$name" ]] || continue

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
      # Real file — use install_file conflict path via copy of logic
      install_file "$SRC_AGENT" "$dest" "$relpath" "copy"
    else
      ln -sf "$SRC_AGENT" "$dest"
      record_file_hash "$relpath" "$dest"
    fi
  else
    install_file "$SRC_AGENT" "$dest" "$relpath" "copy"
  fi
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
  # Collapse trailing blank lines excess
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

  local name dest removed=0 archived_note=0
  if [[ -f "$MANIFEST" ]]; then
    while IFS= read -r name; do
      [[ -z "$name" || "$name" == \#* ]] && continue
      dest="$TARGET_AGENTS_SKILLS/$name"
      if [[ -d "$dest" && ! -L "$dest" ]]; then
        archive_context_overlays "$dest" "$name" && archived_note=1
        rm -rf "$dest"
        echo "removed skill $name"
        removed=$((removed + 1))
      fi
    done <"$MANIFEST"
  else
    echo "NOTE: no .agents/.kstack-skills manifest; not removing skill directories."
  fi

  # Agent files
  rm -f "$TARGET_AGENTS_AGENT_DIR/kstack.md"
  rm -f "$TARGET_CURSOR_AGENTS/kstack.md"
  echo "removed kstack agent files"

  remove_shim_if_ours "$TARGET_CLAUDE_SKILLS"
  remove_shim_if_ours "$TARGET_CURSOR_SKILLS"

  # Sidecars and merge report under skills
  if [[ -d "$TARGET_AGENTS_SKILLS" ]]; then
    find "$TARGET_AGENTS_SKILLS" -name '*.kstack-new' -type f -delete 2>/dev/null || true
  fi
  rm -f "$MERGE_REPORT" "$FILES_MANIFEST" "$MANIFEST"

  strip_gitignore_kstack_blocks

  # Remove empty agent/skills dirs and .agents if empty
  rmdir "$TARGET_AGENTS_AGENT_DIR" 2>/dev/null || true
  rmdir "$TARGET_AGENTS_SKILLS" 2>/dev/null || true
  rmdir "$TARGET_CURSOR_AGENTS" 2>/dev/null || true
  rmdir "$TARGET/.claude" 2>/dev/null || true
  # Keep .agents if archive or other content remains
  if [[ -d "$TARGET_AGENTS" ]]; then
    if [[ -z "$(ls -A "$TARGET_AGENTS" 2>/dev/null)" ]]; then
      rmdir "$TARGET_AGENTS"
    fi
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
  link_tree "$SRC_SKILLS" "$TARGET_AGENTS_SKILLS"
else
  copy_tree "$SRC_SKILLS" "$TARGET_AGENTS_SKILLS"
fi

install_agent_file

# Cursor copy of agent — always a real copy for discovery (even in symlink mode
# the agents dir copy for Cursor is a content copy of whatever is at agents/)
mkdir -p "$TARGET_CURSOR_AGENTS"
if [[ -f "$TARGET_AGENTS_AGENT_DIR/kstack.md" ]]; then
  # If symlink, copy resolved content; if file, cp
  cp -L "$TARGET_AGENTS_AGENT_DIR/kstack.md" "$TARGET_CURSOR_AGENTS/kstack.md" 2>/dev/null \
    || cp "$TARGET_AGENTS_AGENT_DIR/kstack.md" "$TARGET_CURSOR_AGENTS/kstack.md"
fi

migrate_renamed_skills
prune_retired_skills
write_install_manifest
write_files_manifest
finalize_merge_report

# Claude Code shim
mkdir -p "$TARGET/.claude"
if [[ -e "$TARGET_CLAUDE_SKILLS" && ! -L "$TARGET_CLAUDE_SKILLS" ]]; then
  echo "NOTE: $TARGET_CLAUDE_SKILLS already exists and is not a symlink — left unchanged."
else
  ln -sfn "../.agents/skills" "$TARGET_CLAUDE_SKILLS"
fi

# Cursor skills shim
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
