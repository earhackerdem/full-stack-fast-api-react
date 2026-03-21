## ADDED Requirements

### Requirement: Create user by admin
El sistema SHALL permitir a superusuarios crear nuevos usuarios via `POST /api/v1/users/` proporcionando email, password, full_name, is_active e is_superuser.

#### Scenario: Creación exitosa
- **WHEN** un superusuario envía email, password y datos válidos a `POST /api/v1/users/`
- **THEN** el sistema crea el usuario con password hasheado y retorna `UserPublic` con status 200

#### Scenario: Email duplicado
- **WHEN** un superusuario intenta crear un usuario con un email ya registrado
- **THEN** el sistema retorna status 400 con detalle "The user with this email already exists in the system."

#### Scenario: Envío de email de bienvenida
- **WHEN** se crea un usuario exitosamente y `emails_enabled` es True
- **THEN** el sistema envía un email de nueva cuenta al usuario creado

### Requirement: List users by admin
El sistema SHALL permitir a superusuarios listar todos los usuarios via `GET /api/v1/users/` con paginación via `skip` y `limit`.

#### Scenario: Listado con paginación por defecto
- **WHEN** un superusuario llama a `GET /api/v1/users/` sin parámetros
- **THEN** el sistema retorna los primeros 100 usuarios ordenados por `created_at` descendente y el count total

#### Scenario: Listado con paginación personalizada
- **WHEN** un superusuario llama a `GET /api/v1/users/?skip=10&limit=5`
- **THEN** el sistema retorna 5 usuarios comenzando desde el offset 10

### Requirement: Update user by admin
El sistema SHALL permitir a superusuarios actualizar cualquier usuario via `PATCH /api/v1/users/{user_id}`, incluyendo email, password, full_name, is_active e is_superuser.

#### Scenario: Actualización exitosa
- **WHEN** un superusuario envía datos válidos a `PATCH /api/v1/users/{user_id}`
- **THEN** el sistema actualiza los campos proporcionados y retorna `UserPublic`

#### Scenario: Usuario no existe
- **WHEN** un superusuario intenta actualizar un user_id inexistente
- **THEN** el sistema retorna status 404 con detalle "The user with this id does not exist in the system"

#### Scenario: Email duplicado en actualización
- **WHEN** un superusuario actualiza el email a uno que ya pertenece a otro usuario
- **THEN** el sistema retorna status 409 con detalle "User with this email already exists"

### Requirement: Delete user by admin
El sistema SHALL permitir a superusuarios eliminar cualquier usuario via `DELETE /api/v1/users/{user_id}`, eliminando también sus items asociados.

#### Scenario: Eliminación exitosa
- **WHEN** un superusuario elimina un usuario existente que no es él mismo
- **THEN** el sistema elimina los items del usuario, luego el usuario, y retorna "User deleted successfully"

#### Scenario: Superusuario intenta eliminarse a sí mismo
- **WHEN** un superusuario intenta eliminar su propio user_id
- **THEN** el sistema retorna status 403 con detalle "Super users are not allowed to delete themselves"

#### Scenario: Usuario no existe
- **WHEN** un superusuario intenta eliminar un user_id inexistente
- **THEN** el sistema retorna status 404 con detalle "User not found"

### Requirement: Read user by id
El sistema SHALL permitir a usuarios autenticados consultar un usuario por ID via `GET /api/v1/users/{user_id}`. Usuarios regulares solo pueden consultar su propio perfil.

#### Scenario: Usuario consulta su propio perfil por ID
- **WHEN** un usuario autenticado consulta su propio user_id
- **THEN** el sistema retorna `UserPublic` del usuario

#### Scenario: Superusuario consulta cualquier usuario
- **WHEN** un superusuario consulta el user_id de otro usuario
- **THEN** el sistema retorna `UserPublic` del usuario consultado

#### Scenario: Usuario regular consulta otro usuario
- **WHEN** un usuario no-superuser consulta el user_id de otro usuario
- **THEN** el sistema retorna status 403 con detalle "The user doesn't have enough privileges"

#### Scenario: Usuario no encontrado
- **WHEN** un superusuario consulta un user_id inexistente
- **THEN** el sistema retorna status 404 con detalle "User not found"

### Requirement: Get current user profile
El sistema SHALL permitir a usuarios autenticados obtener su propio perfil via `GET /api/v1/users/me`.

#### Scenario: Obtener perfil propio
- **WHEN** un usuario autenticado llama a `GET /api/v1/users/me`
- **THEN** el sistema retorna `UserPublic` con los datos del usuario actual

### Requirement: Update current user profile
El sistema SHALL permitir a usuarios autenticados actualizar su `full_name` y/o `email` via `PATCH /api/v1/users/me`.

#### Scenario: Actualización exitosa
- **WHEN** un usuario envía full_name y/o email válidos a `PATCH /api/v1/users/me`
- **THEN** el sistema actualiza los campos y retorna `UserPublic` actualizado

#### Scenario: Email duplicado
- **WHEN** un usuario intenta cambiar su email a uno que ya pertenece a otro usuario
- **THEN** el sistema retorna status 409 con detalle "User with this email already exists"

### Requirement: Update current user password
El sistema SHALL permitir a usuarios autenticados cambiar su contraseña via `PATCH /api/v1/users/me/password`, requiriendo verificación del password actual.

#### Scenario: Cambio de contraseña exitoso
- **WHEN** un usuario envía `current_password` correcto y `new_password` válido
- **THEN** el sistema actualiza el hash y retorna "Password updated successfully"

#### Scenario: Password actual incorrecto
- **WHEN** un usuario envía `current_password` incorrecto
- **THEN** el sistema retorna status 400 con detalle "Incorrect password"

#### Scenario: Nuevo password igual al actual
- **WHEN** un usuario envía `new_password` idéntico a `current_password`
- **THEN** el sistema retorna status 400 con detalle "New password cannot be the same as the current one"

### Requirement: Delete current user account
El sistema SHALL permitir a usuarios no-superuser eliminar su propia cuenta via `DELETE /api/v1/users/me`. Los superusuarios NO pueden auto-eliminarse.

#### Scenario: Usuario regular elimina su cuenta
- **WHEN** un usuario no-superuser llama a `DELETE /api/v1/users/me`
- **THEN** el sistema elimina el usuario y retorna "User deleted successfully"

#### Scenario: Superusuario intenta auto-eliminarse
- **WHEN** un superusuario llama a `DELETE /api/v1/users/me`
- **THEN** el sistema retorna status 403 con detalle "Super users are not allowed to delete themselves"

### Requirement: Public user registration
El sistema SHALL permitir registro público via `POST /api/v1/users/signup` usando email, password y full_name. Los nuevos usuarios se crean con `is_active=True` e `is_superuser=False`.

#### Scenario: Registro exitoso
- **WHEN** un visitante se registra con email no existente y password válido (8-128 chars)
- **THEN** el sistema crea el usuario y retorna `UserPublic`

#### Scenario: Email ya registrado
- **WHEN** un visitante intenta registrarse con un email ya existente
- **THEN** el sistema retorna status 400 con detalle "The user with this email already exists in the system"

### Requirement: User data model
El sistema SHALL almacenar usuarios con los campos: `id` (UUID, auto-generado), `email` (único, indexado), `hashed_password`, `full_name` (opcional), `is_active` (default True), `is_superuser` (default False), `created_at` (UTC). Los usuarios tienen relación one-to-many con items via `owner_id` con cascade delete.

#### Scenario: Campos por defecto en creación
- **WHEN** se crea un usuario sin especificar is_active ni is_superuser
- **THEN** el usuario se crea con `is_active=True`, `is_superuser=False` y `created_at` en UTC

#### Scenario: Cascade delete de items
- **WHEN** se elimina un usuario que tiene items asociados
- **THEN** el sistema elimina todos los items del usuario antes de eliminar el usuario

### Requirement: Password validation
El sistema SHALL validar que las contraseñas tengan entre 8 y 128 caracteres en todos los schemas que aceptan passwords (UserCreate, UserRegister, UserUpdate, UpdatePassword, NewPassword).

#### Scenario: Password válido
- **WHEN** se proporciona un password de 8-128 caracteres
- **THEN** el sistema acepta el password

#### Scenario: Password demasiado corto
- **WHEN** se proporciona un password de menos de 8 caracteres
- **THEN** el sistema retorna error de validación 422
