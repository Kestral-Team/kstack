# Changelog

## Unreleased

**Install:** Re-running `scripts/install.sh` now prunes skills that kstack no longer ships. It tracks installed
skills in `.agents/.kstack-skills` and also removes names listed in `scripts/retired-skills.txt` (so the first
reinstall after the narrowed skill set cleans up old copies). Project-local and plugin skill directories are not
touched.

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
