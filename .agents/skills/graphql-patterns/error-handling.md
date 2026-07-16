# Error Handling

Resolvers use central wrapping for root `Query`/`Mutation` failures plus local patterns for expected errors and special
catch blocks. See your error handling documentation for the full
guide.

## 1. Direct `throw new GraphQLError` — validation & preconditions

Use inside the try block (or before it) for **expected** failures: auth, not-found, bad input, conflicts. No logging
needed — the global handler filters these from Sentry.

```typescript
if (!actorId || !workspaceId) {
  throw new GraphQLError('Authentication required', {
    extensions: { code: ErrorCode.AuthenticationRequired },
  });
}
if (!task) {
  throw new GraphQLError('Task not found', {
    extensions: { code: ErrorCode.NotFound },
  });
}
```

Add `silent: true` to suppress client-side toast when the UI handles the error inline:

```typescript
throw new GraphQLError('Thread not found', {
  extensions: { code: ErrorCode.NotFound, silent: true },
});
```

## 2. `withResolverErrorHandling` — root Query/Mutation unexpected failures

Root `Query` and `Mutation` fields are wrapped automatically in `your resolver registry (e.g. resolvers/index.ts)`. Implement ordinary root
resolvers as plain `async` functions and configure non-default `clientMessage`, `code`, logging `extra`, non-root
fields, or `false` opt-outs in `your root error config module`.

`Subscription` fields are not auto-wrapped because they use `subscribe`/`resolve` objects and async iterators.

## 3. `throwResolverError` in intentional local catch blocks

**Do not** write catch blocks that always do `throw new GraphQLError(..., InternalServerError)` — that swallows
intentional codes like `NotFound` or `Forbidden`. Use `throwResolverError` instead: it re-throws `GraphQLError`s
unchanged and wraps everything else.

Use this only when a local catch block is intentional, such as subscriptions, non-root fields not configured centrally,
cleanup branches, or integration-specific translation.

```typescript
import { throwResolverError } from 'your-project/utils/graphqlErrorHandler';

} catch (error) {
  throwResolverError(error, 'Error fetching company', 'fetch_company', context, {
    companyId: id,
  });
}

// Fixed client-facing message + optional originalError in extensions:
} catch (error) {
  throwResolverError(error, 'Error in syncTaskToLinear resolver', 'syncTaskToLinear', context, {
    clientMessage: 'Failed to sync task to Linear',
    includeOriginalError: true,
  });
}

// No GraphQL Context, or intentional silence / background log:
} catch (error) {
  throwResolverError(error, '...', 'workspace.members', context, {
    log: 'none',
    clientMessage: 'Error fetching workspace members',
  });
}
```

## Error Code Flow

- Use generated `ErrorCode` enum for `extensions.code` in `GraphQLError` -- no ad-hoc strings
- **Expected business errors** (`AuthenticationRequired`, `Forbidden`, `BadUserInput`, `NotFound`, etc.): logged at
  `info`, skipped for Sentry
- **System errors** (`InternalServerError`, `ExternalApiError`): logged at `error`, sent to Sentry
- In production, unexpected codes are masked as `InternalServerError` with `correlationId`/`requestId`

## Apollo Client Error Handling

```typescript
import { CombinedGraphQLErrors, ServerError, ServerParseError } from "@apollo/client/errors";

function handleError(error: unknown) {
  if (CombinedGraphQLErrors.is(error)) {
    const code = error.errors[0]?.extensions?.code as string | undefined;
    return;
  }
  if (ServerError.is(error) || ServerParseError.is(error)) { return; }
}
```
