# Changelog

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
