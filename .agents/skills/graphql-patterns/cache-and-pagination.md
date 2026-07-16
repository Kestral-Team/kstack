# Cache Management & Pagination

## Cache Management

- Prefer `cache.evict()` over `refetch()` for mutation cache updates
- Only evict what's affected, then call `cache.gc()`
- Combine cache updates with pubsub subscriptions for optimal UX

```typescript
const [createTask] = useMutation(CreateTaskDocument, {
  update: (cache, { data }) => {
    if (!data?.createTask) return;
    cache.evict({ fieldName: "incompleteTasksPaginated" });
    cache.gc();
  },
});
```

## Pagination Standard

All paginated queries return a Connection type with:

- A domain-specific plural field: `{pluralTypeName}: [Type!]!` (e.g., `tasks: [Task!]!`, `feedbacks: [Feedback!]!`,
  `projects: [Project!]!`). Use generic `items: [Type!]!` only for wrapper types that don't correspond to a single
  domain entity (e.g., `CompanyWithCountConnection`).
- `hasMore: Boolean!`
- `total: Int!`

```graphql
type TaskConnection {
  tasks: [Task!]!
  hasMore: Boolean!
  total: Int!
}
```

- Query names: `{domain}Paginated` to avoid `x.x` patterns
- Run count queries in parallel with data queries using `Promise.all`
- Use `total` (not `totalCount`), `hasMore` (not `hasNextPage`)
- Client: always use server-provided `hasMore`, never calculate client-side
- When modifying cache, recalculate `hasMore` when `total` changes

### External API Pagination

- **N+1 pattern**: Fetch `limit+1`, return `limit`, set `hasMore = results.length > limit`
- **Cursor-based**: Use `nextCursor` for `hasMore`; use page-size heuristic (`items.length === limit`)

### Cursor-Based Exception

Some internal queries use cursor-based pagination (e.g., `before` timestamp). For these, use
`hasMore: items.length === actualLimit` instead of the offset formula. Document the exception in the GraphQL schema.
