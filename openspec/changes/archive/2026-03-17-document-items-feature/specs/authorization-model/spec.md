## ADDED Requirements

### Requirement: Control de acceso a item individual
El sistema SHALL verificar ownership a nivel de route handler para operaciones sobre items individuales (GET, PUT, DELETE en `/api/v1/items/{id}`). Usuarios no-superuser SHALL recibir status 403 cuando intenten acceder a un item donde `owner_id != current_user.id`. Superusuarios SHALL poder acceder a cualquier item independientemente del `owner_id`.

#### Scenario: Usuario no-superuser intenta leer item ajeno
- **WHEN** un usuario no-superuser envía `GET /api/v1/items/{id}` donde `item.owner_id != current_user.id`
- **THEN** el sistema retorna status 403 con detalle "Not enough permissions"

#### Scenario: Usuario no-superuser intenta actualizar item ajeno
- **WHEN** un usuario no-superuser envía `PUT /api/v1/items/{id}` donde `item.owner_id != current_user.id`
- **THEN** el sistema retorna status 403 con detalle "Not enough permissions"

#### Scenario: Usuario no-superuser intenta eliminar item ajeno
- **WHEN** un usuario no-superuser envía `DELETE /api/v1/items/{id}` donde `item.owner_id != current_user.id`
- **THEN** el sistema retorna status 403 con detalle "Not enough permissions"

#### Scenario: Superusuario accede a operaciones sobre item ajeno
- **WHEN** un superusuario envía GET, PUT o DELETE a `/api/v1/items/{id}` de cualquier usuario
- **THEN** el sistema permite la operación
