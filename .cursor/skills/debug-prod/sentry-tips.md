# Sentry Tips

## When to Use Sentry vs Cloud Logging

- **Sentry** is the right tool for **masked GraphQL errors** — `graphqlErrorHandler.ts` replaces unexpected error
  messages with `"Internal server error"` in Cloud Logging, but the original exception with full stack trace is captured
  in Sentry via `Sentry.captureException`.
- **Cloud Logging** is faster and more direct for infrastructure errors (API key issues, rate limits, network failures)
  since the full error chain is logged to stderr.

## Configuration

- **Organization**: Org slug is `kestral`, region URL is `https://us.sentry.io`
- Always pass `regionUrl` to Sentry MCP tools
- Use `search_issues` for grouped issue lists
- Use `search_events` for counts/aggregations or individual events with timestamps

## Auth Expiry

If Sentry calls return `401: Token expired`, tell the user their Sentry token needs refreshing. Don't retry — move on to
Cloud Logging.
