## ADDED Requirements

### Requirement: Dual password hashing system

El sistema SHALL usar un sistema de hashing dual con Argon2 como hasher primario y Bcrypt como hasher de fallback, implementado via `pwdlib.PasswordHash`. Todas las contraseñas nuevas SHALL ser hasheadas con Argon2.

#### Scenario: Hashing de nueva contraseña

- **WHEN** se crea un usuario o se actualiza una contraseña
- **THEN** el sistema almacena el hash Argon2 del password en el campo `hashed_password`

#### Scenario: Verificación de contraseña hasheada con Argon2

- **WHEN** un usuario se autentica y su `hashed_password` usa formato Argon2
- **THEN** el sistema verifica correctamente el password contra el hash Argon2

#### Scenario: Verificación de contraseña legacy hasheada con Bcrypt

- **WHEN** un usuario se autentica y su `hashed_password` usa formato Bcrypt (legacy)
- **THEN** el sistema verifica correctamente el password contra el hash Bcrypt

### Requirement: Automatic hash migration

El sistema SHALL migrar automáticamente hashes Bcrypt a Argon2 cuando un usuario se autentica exitosamente. La migración SHALL ser transparente para el usuario.

#### Scenario: Migración automática de Bcrypt a Argon2

- **WHEN** un usuario con hash Bcrypt se autentica exitosamente
- **THEN** el sistema re-hashea el password con Argon2 y actualiza `hashed_password` en la base de datos

#### Scenario: No migración si ya es Argon2

- **WHEN** un usuario con hash Argon2 se autentica exitosamente
- **THEN** el sistema no modifica el `hashed_password` existente

### Requirement: Timing attack prevention

El sistema SHALL prevenir timing attacks durante la autenticación usando un `DUMMY_HASH` cuando el usuario no existe en la base de datos. Esto SHALL asegurar que el tiempo de respuesta sea similar independientemente de si el email existe o no.

#### Scenario: Autenticación con usuario inexistente

- **WHEN** se intenta autenticar con un email que no existe en la base de datos
- **THEN** el sistema ejecuta `verify_password` contra `DUMMY_HASH` antes de retornar `None`, consumiendo tiempo similar a una verificación real

#### Scenario: Autenticación con usuario existente pero password incorrecto

- **WHEN** se intenta autenticar con un email válido pero password incorrecto
- **THEN** el sistema ejecuta `verify_password` contra el hash real del usuario y retorna `None`

### Requirement: Password validation rules

El sistema SHALL enforcar reglas de validación en las contraseñas: mínimo 8 caracteres, máximo 128 caracteres.

#### Scenario: Password válido

- **WHEN** un usuario proporciona un password de 8-128 caracteres
- **THEN** el sistema acepta el password para creación o actualización

#### Scenario: Password demasiado corto

- **WHEN** un usuario proporciona un password de menos de 8 caracteres
- **THEN** el sistema rechaza la operación con error de validación

#### Scenario: Password demasiado largo

- **WHEN** un usuario proporciona un password de más de 128 caracteres
- **THEN** el sistema rechaza la operación con error de validación

### Requirement: Secret key security enforcement

El sistema SHALL validar que `SECRET_KEY` no sea el valor por defecto "changethis" en entornos de staging y producción. En entorno local, SHALL emitir un warning.

#### Scenario: Secret key por defecto en producción

- **WHEN** `SECRET_KEY` es "changethis" y `ENVIRONMENT` es "staging" o "production"
- **THEN** el sistema lanza `ValueError` y no arranca

#### Scenario: Secret key por defecto en local

- **WHEN** `SECRET_KEY` es "changethis" y `ENVIRONMENT` es "local"
- **THEN** el sistema emite un warning pero continúa la ejecución

