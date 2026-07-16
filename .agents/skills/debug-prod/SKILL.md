---
name: debug-prod
description: >-
  Debug production issues using cloud logs, CLI tools, error tracking, and database access.
  Use when debugging production errors, investigating service or job failures, or diagnosing
  masked errors in production.
---

# Debug Production

Help debug a production issue using cloud logs, error tracking, and database access.

## Tools

### Cloud CLI

Use your cloud provider's CLI for log queries and service inspection. See context.md for project-specific CLI
configuration, project IDs, and auth instructions.

### Error Tracking

An error tracking service (Sentry, etc.) may be available as an MCP server. See context.md for usage guidance.

### Database Access

**First, check which Postgres MCP servers are available.** If a **production** Postgres MCP is present and accessible,
query it directly (read-only). If only a **dev** server is present, do NOT query it for production debugging — ask the
user to run a specific SQL query on production.

## Workflow

1. **Gather context** — Ask for symptom, error message, affected users/endpoints, time window. Check recent deploys.
2. **Identify the source** — Determine service vs background job. If unclear, use cross-resource log search.
3. **Pull logs** — Use appropriate query template. Start with ±2 min window. Search for application logs.
4. **Correlate** — Cross-reference with recent code changes (`git log`), deployment history, service health.
5. **Hypothesize and verify** — Form root cause hypothesis, find supporting evidence before proposing a fix. Since
   production errors are often masked, trace the code path.
6. **Propose a fix** — Present minimal, targeted fix with clear reasoning. Flag risks or rollback considerations.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
