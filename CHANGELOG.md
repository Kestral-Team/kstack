# Changelog

## Unreleased

**Install (safe reinstall):** `scripts/install.sh` now records per-file checksums in
`.agents/.kstack-files`. Reinstall never overwrites existing `context.md` / `context.*.md`. Other
files upgrade when unmodified; locally edited files are kept by default with `*.kstack-new`
sidecars and an agent-readable `.agents/.kstack-merge.md` report (`--keep` / `--overwrite` /
TTY prompt). Retired skills still prune via `.agents/.kstack-skills` and
`scripts/retired-skills.txt`, but authored overlays are archived under
`.agents/.kstack-archive/` first. Renames can migrate overlays via `scripts/renamed-skills.txt`.
New: `--uninstall [--yes]` removes managed skills/agent/shims while archiving overlays.
Project-local and plugin skill directories remain untouched.

**Docs:** `/kstack` is documented as **Cursor-only**. Claude Code, Codex, and other hosts invoke pipeline or
step skills directly (`/planning-pipeline`, `$review-pipeline`, etc.). Skills remain multi-host under
`.agents/skills/`; only Cursor installs the router agent at `.cursor/agents/kstack.md`.

**Breaking:** Canonical skill root is `.agents/skills/` (host-agnostic). The `kstack` router lives at
`.agents/agents/kstack.md`. `install.sh` still places Cursor/Claude shims (`.cursor/agents/kstack.md`,
`.claude/skills` → `.agents/skills`, `.cursor/skills` → `.agents/skills`).

### Migration from `.cursor/skills` layout

1. Move any customized `context.md` or `context.*.md` files from `.cursor/skills/<skill>/` to
   `.agents/skills/<skill>/`.
2. Re-run `./scripts/install.sh /path/to/project`.
3. Update custom references from `.cursor/skills/` to `.agents/skills/`.
4. You can remove a leftover project `.cursor/skills/` directory if it is only an old copy (the installer may replace
   it with a symlink to `.agents/skills`).

## v2.0.0 — 2026-07-02

**Breaking:** Category folder structure replaces flat v1 layout.

### Added

- 32 skills across 6 categories (planning, implementation, review, retroactive, prototyping, shared)
- 5 pipeline orchestrators (planning, implementation, review, review-plan, debug)
- Context overlay system (`context.md` stubs + `examples/context-templates/`)
- `kestral-sync` skill for Kestral MCP task integration
- `context-evolve`, `debug-prod`, `pattern-check`, `evals`, and 15+ other skills
- `scripts/install.sh` and `scripts/init-context.sh`
- CI lint workflow

### Changed

- Skills paths: `.cursor/skills/code-review/` → `.cursor/skills/review/code-review/`
- `checks.md` is production-tested (no placeholder markers)
- kstack agent updated for v2 pipeline routing

### Migration from v1

1. Remove old flat `.cursor/skills/*` directories
2. Run `./scripts/install.sh /path/to/project` from kstack v2
3. Migrate customizations from edited v1 files into `context.md` (not SKILL.md)
4. Update any custom references to old skill paths

## v1.0.0

Initial release: 11 flat skills, 3 pipelines, placeholder customization files.
