## Why

The Items feature is a core domain capability that currently lacks formal specification. As the template's primary example of an owned resource with CRUD operations and permission-based access control, documenting it as a spec ensures consistent behavior, enables future extensions, and provides a reference for building similar resource modules.

## What Changes

- Document the Items CRUD lifecycle (create, read, list, update, delete) as a formal capability spec
- Capture the ownership-based access control model (owner-only vs superuser access)
- Specify pagination, validation rules, and error handling behavior
- No code changes — this is a documentation/specification-only change

## Capabilities

### New Capabilities

- `item-crud`: Full lifecycle management of items — creation, retrieval (single + paginated list), update (partial), and deletion with ownership-based access control

### Modified Capabilities

- `authorization-model`: Item access control rules extend the existing authorization model (superuser override, owner-only access for regular users)

## Impact

- No code changes required
- Specs directory gains a new `item-crud` spec documenting the items feature
- Existing `authorization-model` spec gains a delta describing item-specific authorization rules
- Serves as reference documentation for the items module at `backend/app/modules/items/`

