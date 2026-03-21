## Context

The Items module (`backend/app/modules/items/`) is the template's primary example of an owned resource with full CRUD operations. It follows a modular structure with separate models, service, and route files. The feature is already fully implemented — this change documents its behavior as formal specs.

Current architecture:

- **Model**: `Item` SQLModel with `id`, `title`, `description`, `created_at`, `owner_id` fields
- **Service**: `create_item()` in `modules/items/service.py`
- **Routes**: Standard REST endpoints at `/api/v1/items/` with ownership-based access control
- **Tests**: Comprehensive test coverage in `tests/api/routes/test_items.py`

## Goals / Non-Goals

**Goals:**

- Document the Items CRUD lifecycle as a formal capability spec (`item-crud`)
- Capture item-specific authorization rules as a delta to the existing `authorization-model` spec
- Ensure specs are testable — each scenario maps to an existing or potential test case

**Non-Goals:**

- No code changes or refactoring
- No new features or API modifications
- No changes to existing test coverage
- No documentation of frontend item components

## Decisions

**Decision 1: Separate `item-crud` spec from `authorization-model`**
The item CRUD lifecycle (validation, creation, pagination, partial updates) is documented as its own spec, while authorization rules that apply to items are captured as additions to the existing `authorization-model` spec. This keeps authorization concerns centralized and avoids duplication.

*Alternative considered*: A single monolithic `items` spec covering both CRUD and auth — rejected because authorization patterns are shared across resource types and belong in the authorization spec.

**Decision 2: Specs written in Spanish to match existing conventions**
Existing specs (`authorization-model`, `jwt-auth-flow`, `password-security`) are written in Spanish. New specs follow the same language for consistency.

*Alternative considered*: Writing in English — rejected for consistency with existing spec base.

## Risks / Trade-offs

- [Spec drift] Specs document current behavior but code may evolve independently → Mitigation: Specs serve as reference, not enforcement; update specs when behavior changes via future openspec changes.
- [Authorization overlap] Some item authorization scenarios already exist in `authorization-model` spec → Mitigation: Use ADDED (not MODIFIED) in delta spec to extend without duplicating existing requirements.

