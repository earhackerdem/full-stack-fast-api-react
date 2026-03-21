## ADDED Requirements

### Requirement: Active user authorization
El sistema SHALL requerir que el usuario tenga `is_active=True` para acceder a cualquier ruta protegida. La verificación SHALL ocurrir en la dependencia `get_current_user` después de decodificar el token.

#### Scenario: Usuario activo accede a ruta protegida
- **WHEN** un usuario con `is_active=True` envía un request con token válido a una ruta protegida
- **THEN** el sistema permite el acceso y ejecuta el route handler

#### Scenario: Usuario inactivo accede a ruta protegida
- **WHEN** un usuario con `is_active=False` envía un request con token válido a una ruta protegida
- **THEN** el sistema retorna status 400 con detalle "Inactive user"

### Requirement: Superuser privilege escalation
El sistema SHALL proveer una dependencia `get_current_active_superuser` que restringe el acceso a usuarios con `is_superuser=True`. Las rutas que usen esta dependencia SHALL retornar 403 para usuarios no-superuser.

#### Scenario: Superusuario accede a ruta de admin
- **WHEN** un usuario con `is_superuser=True` accede a una ruta protegida con `get_current_active_superuser`
- **THEN** el sistema permite el acceso

#### Scenario: Usuario regular accede a ruta de admin
- **WHEN** un usuario con `is_superuser=False` accede a una ruta protegida con `get_current_active_superuser`
- **THEN** el sistema retorna status 403 con detalle "The user doesn't have enough privileges"

### Requirement: Resource ownership verification
El sistema SHALL verificar ownership de recursos (items) a nivel de route handler. Usuarios no-superuser SHALL solo acceder a recursos donde `owner_id` coincida con su `id`. Superusuarios SHALL poder acceder a cualquier recurso.

#### Scenario: Usuario accede a su propio recurso
- **WHEN** un usuario no-superuser accede a un item donde `item.owner_id == current_user.id`
- **THEN** el sistema permite el acceso al recurso

#### Scenario: Usuario accede a recurso ajeno
- **WHEN** un usuario no-superuser accede a un item donde `item.owner_id != current_user.id`
- **THEN** el sistema retorna status 403 con detalle "Not enough permissions"

#### Scenario: Superusuario accede a recurso de otro usuario
- **WHEN** un superusuario accede a un item de cualquier usuario
- **THEN** el sistema permite el acceso al recurso

### Requirement: Filtered resource listing
El sistema SHALL filtrar listados de recursos según el rol del usuario. Usuarios no-superuser SHALL ver solo sus propios recursos. Superusuarios SHALL ver todos los recursos.

#### Scenario: Usuario regular lista items
- **WHEN** un usuario no-superuser llama a `GET /api/v1/items/`
- **THEN** el sistema retorna solo items donde `owner_id == current_user.id`

#### Scenario: Superusuario lista items
- **WHEN** un superusuario llama a `GET /api/v1/items/`
- **THEN** el sistema retorna todos los items de todos los usuarios

### Requirement: Self-management endpoints
El sistema SHALL permitir que usuarios autenticados gestionen su propio perfil via endpoints `/me`. La actualización de contraseña SHALL requerir verificación del password actual.

#### Scenario: Usuario actualiza su propio password
- **WHEN** un usuario autenticado envía `current_password` correcto y `new_password` a `PATCH /api/v1/users/me/password`
- **THEN** el sistema actualiza el password y retorna confirmación

#### Scenario: Usuario actualiza password con current_password incorrecto
- **WHEN** un usuario envía `current_password` incorrecto a `PATCH /api/v1/users/me/password`
- **THEN** el sistema retorna status 400 con detalle "Incorrect password"

#### Scenario: Usuario elimina su propia cuenta
- **WHEN** un usuario no-superuser llama a `DELETE /api/v1/users/me`
- **THEN** el sistema elimina el usuario y sus recursos asociados

#### Scenario: Superusuario intenta eliminarse a sí mismo
- **WHEN** un superusuario llama a `DELETE /api/v1/users/me`
- **THEN** el sistema retorna status 403 con detalle "Super users are not allowed to delete themselves"

### Requirement: Public user registration
El sistema SHALL permitir el registro público de nuevos usuarios via `POST /api/v1/users/signup` cuando `USERS_OPEN_REGISTRATION` está habilitado en la configuración.

#### Scenario: Registro público habilitado
- **WHEN** `USERS_OPEN_REGISTRATION=True` y un usuario se registra con email no existente
- **THEN** el sistema crea el usuario y retorna sus datos públicos

#### Scenario: Registro público deshabilitado
- **WHEN** `USERS_OPEN_REGISTRATION=False` y un usuario intenta registrarse
- **THEN** el sistema retorna status 403 con detalle "Open user registration is forbidden on this server"

#### Scenario: Registro con email ya existente
- **WHEN** un usuario intenta registrarse con un email que ya existe en la base de datos
- **THEN** el sistema retorna status 400 con detalle indicando que el usuario ya existe
