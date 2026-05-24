# Spec: <ticket-id> — <subtask title>

**Parent ticket:** <ticket-id> — <ticket title>
**Plan:** `<spec_directory>/<ticket-id>/plan.md`
**PR scope:** <1-sentence summary of what this PR delivers>
**Created:** <date>

## Context

<Brief summary of what this subtask accomplishes. Reference the plan for full ticket context.>

## Dependencies & Shared Contracts

### Consumes (from prior subtasks)

<List what this subtask assumes already exists from earlier subtasks in the implementation order. If this is the first subtask, write "None — this is the first subtask in the implementation order.">

- <e.g., "Assumes `CreateOrderRequestDto` from spec-backend-api.md exists">

### Produces (for later subtasks)

<List what this subtask creates that later subtasks depend on.>

- <e.g., "Exposes `IOrderBusiness.Create()` — consumed by frontend subtask">

### Shared interfaces or models

<If this subtask introduces or modifies interfaces/models used across subtasks, define the contract here — signature only, no implementation.>

## Existing Architecture

<Describe the relevant parts of the current codebase for this subtask.>

**Limit: max 12 rows across all tables in this section.** Include only files directly modified
in this subtask. Move supplementary context to a note in the relevant Changes Required item.

- Key files and their roles (table, <=12 rows total)
- Relevant interfaces and their current method signatures
- Data flow: API -> Business -> Database (as it exists today)
- Existing patterns that this implementation should follow

## Changes Required

For each change, specify the file path, action, and what to add or modify. Define **contracts only** — method signatures, property shapes, endpoint routes, model structures. Do NOT include method bodies or implementation logic.

**What to add/change — rules:**

- Method signatures in prose only: `Move(long id, long? newParentId): Task<Model?>` — not full implementations.
- **No code blocks.** No TypeScript/C# snippets of method bodies, hooks, or JSX.
- If implementation detail must be captured, add it to the relevant Implementation Order step — not here.

### 1. <Component/Layer name>

**File:** `<exact file path>`
**Action:** Create | Modify | Delete

**What to add/change:**

- <e.g., "Add method `Task<OrderModel> Create(CreateOrderRequestDto dto)` to `IOrderBusiness`">
- <e.g., "Add `[HttpPost]` endpoint returning `ActionResult<OrderResponseDto>`">
- <e.g., "Add property `string Name` to new `CreateOrderRequestDto`">

**Rationale:** <Why this change, why this approach over alternatives>

### 2. <Next component>

...

## Data Flow

<Describe the complete data flow for the new/changed feature, from API endpoint to database and back. Use prose or a numbered sequence — not code. Include:>

- Request/response model shapes (property names and types, not full class definitions)
- Validation rules (what is checked, what errors are returned)
- Business logic decisions (branching, calculations, side effects)
- Database operations (queries, updates, transactions)
- Event publishing (if applicable)

## Edge Cases & Error Handling

| Scenario          | Expected Behavior         |
| ----------------- | ------------------------- |
| <edge case>       | <how to handle>           |
| <error condition> | <error response/behavior> |

## Test Plan

> **Note:** Tests are implemented separately via the `/t2p-TEST` prompt. This section defines WHAT to test — the `/t2p-TEST` prompt handles HOW.

### Unit Tests

| Test Name                            | Scenario | Expected Result |
| ------------------------------------ | -------- | --------------- |
| `<MethodName>_<Scenario>_<Expected>` | <setup>  | <assertion>     |

### Integration Tests (if applicable)

<Describe integration test scenarios>

## Migration / Deployment Notes

<Any database migrations, config changes, or deployment steps required>

## Implementation Order

<Ordered list of steps to implement, with dependencies noted. Each step should be a logical unit that can be built and verified independently.>

1. **Step 1: <title>** — <what to do, which Changes Required items this covers>
2. **Step 2: <title>** — <what to do>
3. ...

## Checklist

- [ ] Implementation matches this spec
- [ ] Edge cases from table above are handled
- [ ] No breaking changes to existing API contracts
- [ ] Unit tests written and passing
- [ ] Reviewed via `/t2p-REVIEW`
