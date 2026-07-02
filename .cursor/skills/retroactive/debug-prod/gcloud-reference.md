# GCloud Reference

## Cloud Logging Query Templates

**Service logs (web server / API):**

```bash
gcloud logging read \
  'resource.type="cloud_run_revision" AND resource.labels.service_name="app" AND resource.labels.location="us-west1" AND timestamp>="<START_UTC>" AND timestamp<="<END_UTC>"' \
  --limit=100 --format=json --project=briber2
```

**Job logs (background batch processing):**

```bash
gcloud logging read \
  'resource.type="cloud_run_job" AND resource.labels.job_name="<JOB_NAME>" AND resource.labels.location="us-west1" AND timestamp>="<START_UTC>" AND timestamp<="<END_UTC>"' \
  --limit=100 --format=json --project=briber2
```

To filter a specific execution, add: `AND labels."run.googleapis.com/execution_name"="<EXECUTION_NAME>"`

**Cross-resource search (when source is unknown):**

```bash
gcloud logging read \
  'resource.labels.location="us-west1" AND timestamp>="<START_UTC>" AND timestamp<="<END_UTC>" AND textPayload=~"<KEYWORD>"' \
  --limit=30 --format=json --project=briber2
```

Key details:
- **Project**: `briber2`
- **Service name**: `app` (NOT "kestral-server")
- **Location**: `us-west1`

## Other Useful Commands

- `gcloud run services describe app --region=us-west1 --project=briber2` — inspect service state
- `gcloud run revisions list --service=app --region=us-west1 --project=briber2 --limit=5` — check recent deploys
- `gcloud run services logs read app --region=us-west1 --project=briber2` — recent service logs (simpler but less filterable)
- `gcloud run jobs list --region=us-west1 --project=briber2 --format="value(metadata.name)"` — list all batch jobs
- `gcloud run jobs executions list --job=<JOB_NAME> --region=us-west1 --project=briber2 --limit=5` — recent executions of a job

## Cloud Run Services vs Jobs

| Resource | `resource.type` | Runs | Examples |
|---|---|---|---|
| **Cloud Run Service** | `cloud_run_revision` | Web server, cron, WebSocket | `app`, `app-beta` |
| **Cloud Run Job** | `cloud_run_job` | Background batch processing | `notion-bulk-import-batch-job`, `feedback-pipeline-job`, etc. |

Background jobs handle bulk imports, pipelines, and batch processing. If the issue involves an agent, ingestion, or batch operation, check jobs first.

## Log Format Quirks

- **Line-level splitting**: Cloud Run splits each line of a multi-line log call into a **separate log entry**. Search for a distinctive substring rather than trying to match the full object.
- **Severity mapping**: `logger.warn()` maps to **DEFAULT** severity in Cloud Logging, not WARNING. Don't filter by `severity>=WARNING` — use `severity>=DEFAULT` or omit severity entirely.
- **stdout vs stderr**: Application `logger.*()` calls emit to **stderr** (`logName=~"stderr"`), not stdout. Health checks and stats print to stdout.
- **Error masking**: `graphqlErrorHandler.ts` replaces all unexpected error messages with `"Internal server error"` in production. The original error is captured in **Sentry** (via `Sentry.captureException`), not in Cloud Logging.
