# Resolver Patterns

## Export Plain Objects (NOT `Resolvers<Context>`)

```typescript
import type { Context } from "your-project/common/types";
import { getUserById } from "your-project/db/queries/userQueries";
import { userDBToUser } from "your-project/db/dbTypes";

export const userResolvers = {
  Query: {
    user: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      const dbUser = await getUserById(id, context.workspaceId);
      return dbUser ? userDBToUser(dbUser) : null;
    },
  },
  User: {
    assignee: async (parent: { assigneeId: string | null }) => {
      if (!parent.assigneeId) return null;
      return fetchActorFromId(parent.assigneeId);
    },
  },
};
```

**Key principles:**

- Plain objects without generic type annotations
- Explicit parameter types inline
- Parent resolvers return partial data; field resolvers populate related data
- Field resolver parent types only need the fields they access

## Standard Resolver Context

For standard non-exempt GraphQL operations, Apollo middleware already runs `verifyAccess(context)` before resolvers
execute.

- Do not add redundant resolver-local guards or helper functions that only check `context.workspaceId` /
  `context.actorId` presence for normal authenticated resolver paths.
- Prefer resolver-local auth/context guards only for auth-exempt operations, admin operations, websocket/tool entry
  points, or code paths that bypass normal GraphQL middleware.
- This does **not** replace DB-level workspace scoping. Queries must still enforce workspace isolation with
  `.where('workspace_id', '=', workspaceId)` or equivalent.
