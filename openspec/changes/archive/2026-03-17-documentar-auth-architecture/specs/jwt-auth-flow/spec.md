## ADDED Requirements

### Requirement: Token generation on login

El sistema SHALL generar un JWT access token cuando un usuario se autentica exitosamente via `POST /api/v1/login/access-token` usando OAuth2 Password Bearer flow. El token SHALL contener los claims `exp` (expiración) y `sub` (UUID del usuario), firmado con el algoritmo HS256 usando `SECRET_KEY`.

#### Scenario: Login exitoso con credenciales válidas

- **WHEN** un usuario envía email y password válidos a `POST /api/v1/login/access-token`
- **THEN** el sistema retorna `{"access_token": "<jwt>", "token_type": "bearer"}` con status 200

#### Scenario: Login fallido con credenciales inválidas

- **WHEN** un usuario envía email o password incorrectos a `POST /api/v1/login/access-token`
- **THEN** el sistema retorna status 400 con detalle "Incorrect email or password"

#### Scenario: Login fallido con usuario inactivo

- **WHEN** un usuario con `is_active=False` envía credenciales válidas
- **THEN** el sistema retorna status 400 con detalle "Inactive user"

### Requirement: Token validation on protected routes

El sistema SHALL validar el JWT bearer token en cada request a rutas protegidas. La validación SHALL decodificar el token con `SECRET_KEY` y algoritmo HS256, extraer el `sub` claim como UUID del usuario, buscar el usuario en base de datos y verificar que esté activo.

#### Scenario: Request con token válido

- **WHEN** un request incluye header `Authorization: Bearer <jwt_válido>`
- **THEN** el sistema inyecta el objeto `User` correspondiente como `CurrentUser` en el route handler

#### Scenario: Request con token expirado

- **WHEN** un request incluye un token cuyo claim `exp` ya pasó
- **THEN** el sistema retorna status 403 con detalle "Could not validate credentials"

#### Scenario: Request con token inválido o malformado

- **WHEN** un request incluye un token con firma inválida o formato incorrecto
- **THEN** el sistema retorna status 403 con detalle "Could not validate credentials"

#### Scenario: Request sin token

- **WHEN** un request a una ruta protegida no incluye header Authorization
- **THEN** el sistema retorna status 401 (Not Authenticated)

### Requirement: Token expiration configuration

El sistema SHALL configurar la expiración del access token via `ACCESS_TOKEN_EXPIRE_MINUTES` (default: 11520 minutos / 8 días). El valor SHALL ser configurable via variable de entorno.

#### Scenario: Token generado con expiración por defecto

- **WHEN** se genera un token sin especificar `expires_delta`
- **THEN** el token tiene un claim `exp` igual a `now + ACCESS_TOKEN_EXPIRE_MINUTES`

### Requirement: Test token endpoint

El sistema SHALL proveer `POST /api/v1/login/test-token` para verificar la validez de un token existente.

#### Scenario: Verificación de token válido

- **WHEN** un usuario autenticado llama a `POST /api/v1/login/test-token`
- **THEN** el sistema retorna los datos del usuario actual (schema `UserPublic`)

### Requirement: Password reset token flow

El sistema SHALL generar tokens JWT de reset de contraseña con expiración de 48 horas. El token SHALL usar el email del usuario como `sub` claim e incluir un claim `nbf` (not before).

#### Scenario: Solicitud de recuperación de contraseña

- **WHEN** un usuario llama a `POST /api/v1/password-recovery/{email}` con un email registrado
- **THEN** el sistema envía un email con un link que contiene el token de reset

#### Scenario: Solicitud con email no registrado

- **WHEN** se llama a `POST /api/v1/password-recovery/{email}` con un email que no existe
- **THEN** el sistema retorna el mismo response que con email válido (prevención de enumeración)

#### Scenario: Reset de contraseña con token válido

- **WHEN** un usuario envía un token válido y nueva contraseña a `POST /api/v1/reset-password/`
- **THEN** el sistema actualiza el `hashed_password` del usuario y retorna confirmación

#### Scenario: Reset de contraseña con token expirado

- **WHEN** un usuario envía un token expirado (>48 horas) a `POST /api/v1/reset-password/`
- **THEN** el sistema retorna status 400 con detalle "Invalid token"

