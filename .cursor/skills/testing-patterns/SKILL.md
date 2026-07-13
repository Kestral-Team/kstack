---
name: testing-patterns
description: >-
  Vitest mocking reference for constructor mocks, global mocks, and env var mocks. Use when writing
  or fixing test mocks, when a test throws TypeError about constructors, when global mocks leak
  between tests, or when env var mocking causes undefined values.
---

# Testing Patterns

Mocking reference for Vitest. Jump to the section matching your problem.

## Constructor Mocking (Vitest 4)

Vitest 4 enforces that mocks used with `new` must have a `function` or `class` implementation. Arrow functions lack
`[[Construct]]` and will throw `TypeError: ... is not a constructor`.

### Anti-patterns

```typescript
// BAD - arrow function can't be used with `new`
vi.mock('@google-cloud/storage', () => ({
  Storage: vi.fn(() => ({ bucket: vi.fn() })),
}));

// BAD - mockReturnValue rejected when called with `new`
vi.mocked(SomeClass).mockReturnValue(instance);
```

### Correct patterns

```typescript
// GOOD - use function keyword in mockImplementation
vi.mock('@google-cloud/storage', () => ({
  Storage: vi.fn().mockImplementation(function () {
    return { bucket: vi.fn() };
  }),
}));

// GOOD - hoisted constructor mock
const MockClass = vi.hoisted(() =>
  vi.fn().mockImplementation(function () {
    return { method: vi.fn() };
  })
);

// GOOD - override in beforeEach with function
mockConstructor.mockImplementation(function () {
  return { bucket: vi.fn() };
});
```

### Checklist for constructor mocks

- [ ] Uses `function` keyword (not `=>`) in `mockImplementation`
- [ ] Uses `mockImplementation`, never `mockReturnValue`, for mocks called with `new`
- [ ] `vi.hoisted` constructor mocks also use `function` keyword
- [ ] Per-test overrides via `mockImplementation(function () { ... })`, not arrow

---

## Global Mocking

**NEVER override global objects at file scope without proper restoration.** Global mocks leak between test files.

### Anti-patterns

```typescript
// BAD - file-scope overrides (leak into other tests)
global.fetch = vi.fn();
window.location = { pathname: '/test' } as any;

// BAD - destructive cleanup
afterEach(() => { delete (window as any).location; });

// BAD - unsafe casting
(global.fetch as any).mockResolvedValue(response);
```

### Correct: scoped mocks with restoration

```typescript
describe('MyComponent', () => {
  let fetchSpy: MockInstance;
  let originalLocation: Location;

  beforeEach(() => {
    originalLocation = window.location;
    fetchSpy = vi.spyOn(global, 'fetch').mockImplementation(vi.fn());
    Object.defineProperty(window, 'location', {
      value: { pathname: '/test/path' },
      writable: true,
      configurable: true,
    });
  });

  afterEach(() => {
    fetchSpy.mockRestore();
    Object.defineProperty(window, 'location', {
      value: originalLocation,
      writable: true,
      configurable: true,
    });
  });
});
```

### Checklist for global mocks

- [ ] Save original values in `beforeEach` BEFORE mocking
- [ ] Use `vi.spyOn()` instead of direct assignment for functions
- [ ] Use `Object.defineProperty()` for object property mocking
- [ ] Restore ALL mocks in `afterEach` using saved originals
- [ ] Never use `delete` to clean up -- always restore original values
- [ ] Type mocks properly -- avoid `as any` casting

---

## Mocking Environment Config Modules

**NEVER** use `vi.mock('env-module', () => ({ ONLY_VARS_I_NEED }))` — this replaces the entire module and any transitive
dependency importing an unlisted var gets `undefined`.

### Static mocks (`vi.mock`) — use `importOriginal`

```typescript
vi.mock('your-project/config/env', async (importOriginal) => {
  const actual = await importOriginal<typeof import('your-project/config/env')>();
  return { ...actual, BUCKET_NAME: 'test-bucket' };
});
```

### Dynamic mocks (`vi.doMock`) — spread shared defaults

`vi.doMock` doesn't support `importOriginal`. Use a shared test defaults module (see context.md for project-specific
path):

```typescript
vi.doMock('your-project/config/env', async () => {
  const { TEST_ENV_DEFAULTS } = await import('../test/testEnvDefaults');
  return { ...TEST_ENV_DEFAULTS, SOME_KEY: 'override' };
});
```

### Dynamic getters for mid-test changes

When a test needs to change an env var between assertions, use a getter with `vi.hoisted`:

```typescript
const envMock = vi.hoisted(() => ({ ENVIRONMENT: 'test' as string }));

vi.mock('your-project/config/env', async (importOriginal) => {
  const actual = await importOriginal<Record<string, unknown>>();
  return {
    ...actual,
    get ENVIRONMENT() { return envMock.ENVIRONMENT; },
  };
});

// In tests: envMock.ENVIRONMENT = 'production';
```

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
