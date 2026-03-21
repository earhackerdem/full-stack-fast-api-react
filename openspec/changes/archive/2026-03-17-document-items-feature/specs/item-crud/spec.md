## ADDED Requirements

### Requirement: Creación de item
El sistema SHALL permitir a usuarios autenticados crear items mediante `POST /api/v1/items/`. El item creado SHALL tener `owner_id` asignado automáticamente al usuario autenticado. Los campos `id` y `created_at` SHALL ser generados automáticamente por el sistema.

#### Scenario: Creación exitosa de item
- **WHEN** un usuario autenticado envía un request `POST /api/v1/items/` con `title` (1-255 caracteres) y opcionalmente `description` (máximo 255 caracteres)
- **THEN** el sistema crea el item, asigna `owner_id` al usuario actual, genera `id` (UUID) y `created_at` (timestamp UTC), y retorna el item con status 200

#### Scenario: Creación de item sin título
- **WHEN** un usuario autenticado envía un request `POST /api/v1/items/` sin campo `title` o con `title` vacío
- **THEN** el sistema retorna status 422 con error de validación

#### Scenario: Creación de item con título demasiado largo
- **WHEN** un usuario autenticado envía un request `POST /api/v1/items/` con `title` de más de 255 caracteres
- **THEN** el sistema retorna status 422 con error de validación

### Requirement: Lectura de item individual
El sistema SHALL permitir obtener un item específico mediante `GET /api/v1/items/{id}`. El acceso SHALL estar restringido por ownership (ver spec `authorization-model`).

#### Scenario: Lectura exitosa de item propio
- **WHEN** un usuario autenticado envía `GET /api/v1/items/{id}` donde el item existe y `owner_id == current_user.id`
- **THEN** el sistema retorna el item con campos `id`, `title`, `description`, `owner_id`, `created_at`

#### Scenario: Item no encontrado
- **WHEN** un usuario autenticado envía `GET /api/v1/items/{id}` con un `id` que no existe
- **THEN** el sistema retorna status 404 con detalle "Item not found"

### Requirement: Listado paginado de items
El sistema SHALL proveer un endpoint `GET /api/v1/items/` que retorna items paginados. Los resultados SHALL estar ordenados por fecha de creación descendente (más recientes primero). El filtrado por ownership se define en la spec `authorization-model`.

#### Scenario: Listado con parámetros por defecto
- **WHEN** un usuario autenticado envía `GET /api/v1/items/` sin parámetros de paginación
- **THEN** el sistema retorna hasta 100 items (limit por defecto) desde el inicio (skip=0) con el campo `count` indicando el total de items disponibles

#### Scenario: Listado con paginación personalizada
- **WHEN** un usuario autenticado envía `GET /api/v1/items/?skip=10&limit=5`
- **THEN** el sistema retorna hasta 5 items comenzando desde la posición 10, con `count` indicando el total

#### Scenario: Listado vacío
- **WHEN** un usuario autenticado no tiene items (o no existen items en el sistema para superusuarios)
- **THEN** el sistema retorna `data: []` y `count: 0`

### Requirement: Actualización parcial de item
El sistema SHALL permitir actualizar items mediante `PUT /api/v1/items/{id}`. La actualización SHALL ser parcial — solo los campos incluidos en el request body son modificados. Los campos `id`, `owner_id` y `created_at` SHALL ser inmutables.

#### Scenario: Actualización exitosa de título
- **WHEN** un usuario autenticado envía `PUT /api/v1/items/{id}` con `{"title": "nuevo título"}` para un item que le pertenece
- **THEN** el sistema actualiza solo el `title`, mantiene `description` sin cambios, y retorna el item actualizado

#### Scenario: Actualización exitosa de descripción
- **WHEN** un usuario autenticado envía `PUT /api/v1/items/{id}` con `{"description": "nueva descripción"}` para un item que le pertenece
- **THEN** el sistema actualiza solo la `description`, mantiene `title` sin cambios, y retorna el item actualizado

#### Scenario: Actualización de item no encontrado
- **WHEN** un usuario autenticado envía `PUT /api/v1/items/{id}` con un `id` que no existe
- **THEN** el sistema retorna status 404 con detalle "Item not found"

### Requirement: Eliminación de item
El sistema SHALL permitir eliminar items mediante `DELETE /api/v1/items/{id}`. El acceso SHALL estar restringido por ownership (ver spec `authorization-model`).

#### Scenario: Eliminación exitosa
- **WHEN** un usuario autenticado envía `DELETE /api/v1/items/{id}` para un item que le pertenece
- **THEN** el sistema elimina el item y retorna `{"message": "Item deleted successfully"}`

#### Scenario: Eliminación de item no encontrado
- **WHEN** un usuario autenticado envía `DELETE /api/v1/items/{id}` con un `id` que no existe
- **THEN** el sistema retorna status 404 con detalle "Item not found"

### Requirement: Eliminación en cascada por usuario
El sistema SHALL eliminar automáticamente todos los items de un usuario cuando dicho usuario es eliminado del sistema (CASCADE delete en la relación `owner_id` → `User.id`).

#### Scenario: Eliminación de usuario con items
- **WHEN** un usuario que posee items es eliminado del sistema
- **THEN** el sistema elimina automáticamente todos los items donde `owner_id == usuario.id`
